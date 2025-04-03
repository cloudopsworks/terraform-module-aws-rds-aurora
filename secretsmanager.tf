##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username            = local.master_user
    password            = try(var.settings.managed_password_rotation, false) ? null : random_password.randompass[0].result
    engine              = aws_rds_cluster.this.engine
    host                = aws_rds_cluster.this.endpoint
    port                = aws_rds_cluster.this.port
    dbClusterIdentifier = aws_rds_cluster.this.cluster_identifier
  }
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  count = try(var.settings.managed_password_rotation, false) ? 0 : 1
  name  = "${local.secret_store_path}/${var.settings.engine_type}/${aws_rds_cluster.this.cluster_identifier}/${local.db_name}/master-rds-credentials"
  tags  = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  count         = try(var.settings.managed_password_rotation, false) ? 0 : 1
  secret_id     = aws_secretsmanager_secret.rds[count.index].id
  secret_string = jsonencode(local.rds_credentials)
}
