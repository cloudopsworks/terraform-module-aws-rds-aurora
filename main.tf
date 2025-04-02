##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  rds_port    = try(var.settings.port, 5432)
  db_name     = try(var.settings.database_name, "cluster_db")
  master_user = try(var.settings.master_username, "cluster_root")
}

# Provision RDS global cluster only if settings.global_cluster.create=true
resource "aws_rds_global_cluster" "this" {
  count                     = try(var.settings.global_cluster.create, false) ? 1 : 0
  global_cluster_identifier = "rds-${var.settings.name_prefix}-${local.system_name}-global"
  engine                    = var.settings.engine_type
  engine_version            = var.settings.engine_version
}

resource "random_string" "final_snapshot" {
  length = 10
  special = false
    upper = false
    lower = true
  numeric = true
}

# Provisions RDS instance only if rds_provision=true
resource "aws_rds_cluster" "this" {
  cluster_identifier          = "rds-${var.settings.name_prefix}-${local.system_name}"
  engine                      = var.settings.engine_type
  engine_version              = var.settings.engine_version
  global_cluster_identifier   = try(var.settings.global_cluster.create, false) ? aws_rds_global_cluster.this[0].id : try(var.settings.global_cluster.id, null)
  availability_zones          = var.settings.availability_zones
  database_name               = local.db_name
  master_username             = local.master_user
  master_password             = try(var.settings.managed_password_rotation, false) ? null : random_password.randompass[0].result
  manage_master_user_password = try(var.settings.managed_password_rotation, false) ? true : null
  backup_retention_period     = try(var.settings.backup.retention_period, 5)
  preferred_backup_window     = try(var.settings.backup.window, "01:00-03:00")
  copy_tags_to_snapshot       = try(var.settings.backup.copy_tags, true)
  apply_immediately           = try(var.settings.apply_immediately, true)
  vpc_security_group_ids      = local.security_group_ids
  storage_encrypted           = try(var.settings.storage.encryption.enabled, false)
  db_subnet_group_name        = var.vpc.subnet_group
  kms_key_id                  = try(var.settings.storage.encryption.kms_key_id, null)
  port                        = local.rds_port
  final_snapshot_identifier   = "rds-${var.settings.name_prefix}-${local.system_name}-cluster-final-snap-${random_string.final_snapshot.result}"
  deletion_protection         = try(var.settings.deletion_protection, true)
  allow_major_version_upgrade = try(var.settings.allow_upgrade, true)
  tags                        = local.all_tags
}

resource "aws_rds_cluster_instance" "this" {
  count                      = try(var.settings.replicas, 1)
  identifier                 = "rds-${count.index}-${var.settings.name_prefix}-${local.system_name}"
  cluster_identifier         = aws_rds_cluster.this.id
  instance_class             = var.settings.instance_size
  engine                     = var.settings.engine_type
  engine_version             = var.settings.engine_version
  auto_minor_version_upgrade = try(var.settings.auto_minor_upgrade, false)
  apply_immediately          = try(var.settings.apply_immediately, true)
  tags                       = merge(local.all_tags, local.backup_tags)
}
