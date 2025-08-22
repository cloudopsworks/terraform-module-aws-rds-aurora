##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  rds_port           = try(var.settings.port, 5432)
  db_name            = try(var.settings.database_name, "cluster_db")
  master_user        = try(var.settings.master_username, "cluster_root")
  cluster_identifier = "rds-${var.settings.name_prefix}-${local.system_name}"
}

# Provision RDS global cluster only if settings.global_cluster.create=true
resource "aws_rds_global_cluster" "this" {
  count                     = try(var.settings.global_cluster.create, false) ? 1 : 0
  global_cluster_identifier = "rds-${var.settings.name_prefix}-${local.system_name}-global"
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
  count                          = try(var.settings.recovery.enabled, false) ? 1 : 0
  db_cluster_identifier          = try(var.settings.recovery.cluster_identifier, local.cluster_identifier)
  db_cluster_snapshot_identifier = try(var.settings.recovery.snapshot_identifier, null)
  most_recent                    = true
}

# Provisions RDS instance only if rds_provision=true
resource "aws_rds_cluster" "this" {
  cluster_identifier            = local.cluster_identifier
  engine                        = var.settings.engine_type
  engine_version                = var.settings.engine_version
  global_cluster_identifier     = try(var.settings.global_cluster.create, false) ? aws_rds_global_cluster.this[0].id : try(var.settings.global_cluster.id, null)
  availability_zones            = var.settings.availability_zones
  database_name                 = local.db_name
  master_username               = local.master_user
  master_password               = try(var.settings.managed_password, false) ? null : random_password.randompass[0].result
  manage_master_user_password   = try(var.settings.managed_password, false) ? true : null
  master_user_secret_kms_key_id = try(var.settings.managed_password_rotation, false) ? try(var.settings.password_secret_kms_key_id, null) : null
  backup_retention_period       = try(var.settings.backup.retention_period, 5)
  preferred_backup_window       = try(var.settings.backup.window, "00:45-02:45")
  preferred_maintenance_window  = try(var.settings.maintenance.window, "sun:03:00-sun:04:00")
  copy_tags_to_snapshot         = try(var.settings.backup.copy_tags, true)
  apply_immediately             = try(var.settings.apply_immediately, true)
  vpc_security_group_ids        = local.security_group_ids
  storage_encrypted             = try(var.settings.storage.encryption.enabled, false)
  db_subnet_group_name          = var.vpc.subnet_group
  kms_key_id                    = try(var.settings.storage.encryption.kms_key_id, aws_kms_key.this[0].id, null)
  port                          = local.rds_port
  final_snapshot_identifier     = "rds-${var.settings.name_prefix}-${local.system_name}-cluster-final-snap-${random_string.final_snapshot.result}"
  snapshot_identifier           = try(var.settings.recovery.enabled, false) ? data.aws_db_cluster_snapshot.recovery[0].id : null
  deletion_protection           = try(var.settings.deletion_protection, true)
  allow_major_version_upgrade   = try(var.settings.allow_upgrade, true)
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
  tags = local.all_tags
}

resource "aws_rds_cluster_instance" "this" {
  count                        = try(var.settings.replicas.count, 1)
  identifier                   = "rds-${count.index}-${var.settings.name_prefix}-${local.system_name}"
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = var.settings.instance_size
  engine                       = var.settings.engine_type
  engine_version               = var.settings.engine_version
  auto_minor_version_upgrade   = try(var.settings.auto_minor_upgrade, false)
  apply_immediately            = try(var.settings.apply_immediately, true)
  publicly_accessible          = try(var.settings.publicly_accessible, false)
  copy_tags_to_snapshot        = try(var.settings.backup.copy_tags, true)
  availability_zone            = try(var.settings.replicas[format("replica_%s", count.index)].availability_zone, null)
  promotion_tier               = try(var.settings.replicas[format("replica_%s", count.index)].promotion_tier, null)
  preferred_maintenance_window = try(var.settings.replicas[format("replica_%s", count.index)].maintenance_window, var.settings.maintenance.window, "sun:03:00-sun:04:00")
  tags = merge(local.all_tags, {
    instance-name : "rds-${count.index}-${var.settings.name_prefix}-${local.system_name}"
  }, local.backup_tags)
}
