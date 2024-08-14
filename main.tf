##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  rds_port = try(var.settings.port, 5432)
}

# Provisions RDS instance only if rds_provision=true
resource "aws_rds_cluster" "this" {
  cluster_identifier          = "rds-cl-${var.settings.name_prefix}-${local.system_name}"
  engine                      = var.settings.engine_type
  engine_version              = var.settings.engine_version
  availability_zones          = var.settings.availability_zones
  database_name               = try(var.settings.database_name, "cluster_db")
  master_username             = try(var.settings.master_username, "cluster_root")
  master_password             = random_password.randompass.result
  backup_retention_period     = try(var.settings.backup.retention_period, 5)
  preferred_backup_window     = try(var.settings.backup.window, "01:00-03:00")
  copy_tags_to_snapshot       = try(var.settings.backup.copy_tags, true)
  apply_immediately           = try(var.settings.apply_immediately, true)
  vpc_security_group_ids      = local.security_group_ids
  storage_encrypted           = try(var.settings.storage.encryption.enabled, false)
  db_subnet_group_name        = var.vpc.subnet_group
  kms_key_id                  = try(var.settings.storage.encryption.kms_key_id, null)
  port                        = local.rds_port
  final_snapshot_identifier   = "rds-${var.settings.name_prefix}-${local.system_name}-cluster-final-snap"
  deletion_protection         = try(var.settings.deletion_protection, true)
  allow_major_version_upgrade = try(var.settings.allow_upgrade, true)
  tags                        = local.all_tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = try(var.settings.replicas, 1)
  identifier         = "rds-${count.index}-${var.settings.name_prefix}-${local.system_name}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.settings.instance_size
  engine             = var.settings.engine_type
  engine_version     = var.settings.engine_version
  apply_immediately  = try(var.settings.apply_immediately, true)
  tags               = local.all_tags
}
