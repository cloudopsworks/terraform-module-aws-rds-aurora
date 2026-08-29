##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  rds_port              = try(var.settings.port, 5432)
  db_name               = try(var.settings.database_name, "cluster_db")
  master_user           = try(var.settings.master_username, "cluster_root")
  cluster_identifier    = try(var.settings.name, "") != "" ? var.settings.name : "rds-${var.settings.name_prefix}-${local.system_name}"
  default_exported_logs = strcontains(var.settings.engine_type, "postgres") ? ["postgresql"] : ["audit", "error"]
  cw_logs = [
    for log in try(var.settings.cloudwatch.log_exports, local.default_exported_logs) : "/aws/rds/cluster/${local.cluster_identifier}/${log}"
  ]

  migration_enabled = try(var.settings.migration.enabled, false)
  recovery_enabled  = try(var.settings.recovery.enabled, false)
  managed_password  = try(var.settings.managed_password, false)
  # A migration cluster replicates its source and inherits that instance's credentials, so it must
  # not be handed a master password of its own
  manage_master_password = local.managed_password && !local.migration_enabled
  # The module generates and stores the master password only for fresh clusters that do not delegate
  # the secret to AWS. A snapshot restore carries the master password of the snapshot, and a
  # migration cluster carries that of its replication source, so generating one in either case would
  # store a secret that does not match the database.
  generate_password = !local.managed_password && !local.migration_enabled && !local.recovery_enabled
  # settings.database_name may be passed explicitly as null to skip the initial database, which is
  # also what migration requires. try() only substitutes on error, not on null, so local.db_name is
  # null in that case and the secret name cannot be built from it.
  create_secret = local.generate_password && local.db_name != null
}

# Provision RDS global cluster only if settings.global_cluster.create=true
resource "aws_rds_global_cluster" "this" {
  count                     = try(var.settings.global_cluster.create, false) ? 1 : 0
  global_cluster_identifier = "${local.cluster_identifier}-global"
  engine                    = var.settings.engine_type
  engine_version            = var.settings.engine_version
}

resource "random_string" "final_snapshot" {
  length  = 10
  special = false
  upper   = false
  lower   = true
  numeric = true
}

data "aws_db_cluster_snapshot" "recovery" {
  count                          = local.recovery_enabled ? 1 : 0
  db_cluster_identifier          = try(var.settings.recovery.cluster_identifier, local.cluster_identifier)
  db_cluster_snapshot_identifier = try(var.settings.recovery.snapshot_identifier, null)
  most_recent                    = true
}

data "aws_db_instance" "migration_source" {
  count                  = local.migration_enabled ? 1 : 0
  db_instance_identifier = var.settings.migration.source_rds_instance
}

# Provisions RDS instance only if rds_provision=true
resource "aws_rds_cluster" "this" {
  depends_on                            = [aws_cloudwatch_log_group.this]
  cluster_identifier                    = local.cluster_identifier
  engine                                = var.settings.engine_type
  engine_version                        = var.settings.engine_version
  global_cluster_identifier             = try(var.settings.global_cluster.create, false) ? aws_rds_global_cluster.this[0].id : try(var.settings.global_cluster.id, null)
  availability_zones                    = var.settings.availability_zones
  database_name                         = !local.migration_enabled ? local.db_name : null
  master_username                       = !local.migration_enabled ? local.master_user : null
  master_password_wo                    = local.generate_password ? random_password.randompass[0].result : null
  master_password_wo_version            = local.generate_password ? time_rotating.randompass[0].unix : null
  manage_master_user_password           = local.manage_master_password
  master_user_secret_kms_key_id         = local.manage_master_password ? try(var.settings.password_secret_kms_key_id, null) : null
  backup_retention_period               = !local.migration_enabled ? try(var.settings.backup.retention_period, 5) : null
  preferred_backup_window               = try(var.settings.backup.window, "00:45-02:45")
  preferred_maintenance_window          = try(var.settings.maintenance.window, "sun:03:00-sun:04:00")
  copy_tags_to_snapshot                 = try(var.settings.backup.copy_tags, true)
  apply_immediately                     = try(var.settings.apply_immediately, true)
  vpc_security_group_ids                = local.security_group_ids
  storage_encrypted                     = local.encryption_enabled
  db_subnet_group_name                  = var.vpc.subnet_group
  db_cluster_parameter_group_name       = try(var.settings.cluster_parameter_group.create, false) ? aws_rds_cluster_parameter_group.this[0].name : null
  kms_key_id                            = local.cluster_kms_key_arn
  port                                  = local.rds_port
  final_snapshot_identifier             = "${local.cluster_identifier}-cluster-final-snap-${random_string.final_snapshot.result}"
  snapshot_identifier                   = local.recovery_enabled ? try(data.aws_db_cluster_snapshot.recovery[0].id, null) : null
  deletion_protection                   = try(var.settings.deletion_protection, true)
  allow_major_version_upgrade           = try(var.settings.allow_upgrade, true)
  iam_database_authentication_enabled   = try(var.settings.iam.database_authentication_enabled, true)
  iam_roles                             = try(var.settings.iam.authentication_roles, null)
  iops                                  = try(var.settings.storage.iops, null)
  storage_type                          = try(var.settings.storage.type, null)
  monitoring_interval                   = try(var.settings.monitoring.interval, null)
  monitoring_role_arn                   = try(var.settings.monitoring.interval, 0) > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports       = try(var.settings.cloudwatch.log_exports, local.default_exported_logs)
  replication_source_identifier         = local.migration_enabled ? data.aws_db_instance.migration_source[0].db_instance_arn : null
  performance_insights_enabled          = local.perf_enabled
  performance_insights_kms_key_id       = local.perf_kms_key_arn
  performance_insights_retention_period = local.perf_enabled ? try(var.settings.performance_insights.retention_period, var.settings.performance.retention_period, 7) : null
  database_insights_mode                = try(var.settings.insights_mode, "standard")
  engine_mode = try(var.settings.serverless.enabled, false) ? (
    try(var.settings.serverless.v2, false) ? "provisioned" : "serverless"
  ) : try(var.settings.engine_mode, null)
  dynamic "scaling_configuration" {
    for_each = try(var.settings.serverless.scaling_configuration, null) != null && try(var.settings.serverless.enabled, false) && !try(var.settings.serverless.v2, false) ? [1] : []
    content {
      auto_pause               = try(var.settings.serverless.scaling_configuration.auto_pause, null)
      max_capacity             = try(var.settings.serverless.scaling_configuration.max_capacity, null)
      min_capacity             = try(var.settings.serverless.scaling_configuration.min_capacity, null)
      seconds_until_auto_pause = try(var.settings.serverless.scaling_configuration.seconds_until_auto_pause, null)
      timeout_action           = try(var.settings.serverless.scaling_configuration.timeout_action, null)
    }
  }
  dynamic "serverlessv2_scaling_configuration" {
    for_each = try(var.settings.serverless.scaling_configuration, null) != null && try(var.settings.serverless.enabled, false) && try(var.settings.serverless.v2, false) ? [1] : []
    content {
      max_capacity             = try(var.settings.serverless.scaling_configuration.max_capacity, null)
      min_capacity             = try(var.settings.serverless.scaling_configuration.min_capacity, null)
      seconds_until_auto_pause = try(var.settings.serverless.scaling_configuration.seconds_until_auto_pause, null)
    }
  }
  lifecycle {
    ignore_changes = [
      snapshot_identifier,
    ]
  }
  tags = merge(local.all_tags, {
    cluster-identifier = local.cluster_identifier
  }, local.backup_tags)
}

resource "aws_rds_cluster_instance" "this" {
  count                                 = try(var.settings.replicas.count, 1)
  identifier                            = "${local.cluster_identifier}-${count.index}"
  cluster_identifier                    = aws_rds_cluster.this.cluster_identifier
  instance_class                        = try(var.settings.replicas[format("replica_%s", count.index)].instance_size, var.settings.instance_size)
  engine                                = var.settings.engine_type
  engine_version                        = var.settings.engine_version
  auto_minor_version_upgrade            = try(var.settings.auto_minor_upgrade, false)
  apply_immediately                     = try(var.settings.apply_immediately, true)
  publicly_accessible                   = try(var.settings.publicly_accessible, false)
  copy_tags_to_snapshot                 = try(var.settings.backup.copy_tags, true)
  availability_zone                     = try(var.settings.replicas[format("replica_%s", count.index)].availability_zone, null)
  promotion_tier                        = try(var.settings.replicas[format("replica_%s", count.index)].promotion_tier, null)
  preferred_maintenance_window          = try(var.settings.replicas[format("replica_%s", count.index)].maintenance_window, var.settings.maintenance.window, "sun:03:00-sun:04:00")
  monitoring_interval                   = try(var.settings.monitoring.interval, null)
  monitoring_role_arn                   = try(var.settings.monitoring.interval, 0) > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  db_parameter_group_name               = try(var.settings.parameter_group.create, false) ? aws_db_parameter_group.this[0].name : null
  performance_insights_enabled          = local.perf_enabled
  performance_insights_kms_key_id       = local.perf_kms_key_arn
  performance_insights_retention_period = local.perf_enabled ? try(var.settings.performance_insights.retention_period, var.settings.performance.retention_period, 7) : null
  tags = merge(local.all_tags, {
    cluster-identifier = local.cluster_identifier
    instance-name      = "${local.cluster_identifier}-${count.index}"
  }, local.backup_tags)
}

resource "aws_rds_cluster_endpoint" "this" {
  for_each                    = { for endpoint in try(var.settings.custom_endpoints, []) : endpoint.name => endpoint }
  cluster_identifier          = aws_rds_cluster.this.cluster_identifier
  cluster_endpoint_identifier = each.value.name
  custom_endpoint_type        = upper(each.value.type)
  static_members              = try(each.value.static_members, null)
  excluded_members            = try(each.value.excluded_members, null)
  tags                        = local.all_tags
}

resource "aws_rds_cluster_parameter_group" "this" {
  count       = try(var.settings.cluster_parameter_group.create, false) ? 1 : 0
  name_prefix = "${local.cluster_identifier}-cluster-param-group"
  description = "RDS Cluster Parameter Group for ${local.cluster_identifier}"
  family      = try(var.settings.cluster_parameter_group.family, format("%s%s", var.settings.engine_type, var.settings.engine_version))

  dynamic "parameter" {
    for_each = try(var.settings.cluster_parameter_group.parameters, [])
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
  tags = merge(local.all_tags, {
    cluster-identifier = local.cluster_identifier
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "this" {
  count       = try(var.settings.parameter_group.create, false) ? 1 : 0
  name_prefix = "${local.cluster_identifier}-param-group"
  description = "RDS Cluster Parameter Group for ${local.cluster_identifier}"
  family      = try(var.settings.parameter_group.family, format("%s%s", var.settings.engine_type, var.settings.engine_version))

  dynamic "parameter" {
    for_each = try(var.settings.parameter_group.parameters, [])
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
  skip_destroy = try(var.settings.parameter_group.skip_destroy, false)
  tags = merge(local.all_tags, {
    cluster-identifier = local.cluster_identifier
  })

  lifecycle {
    create_before_destroy = true
  }
}
