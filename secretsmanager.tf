##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username            = local.master_user
    password            = random_password.randompass.result
    engine              = aws_rds_cluster.this.engine
    host                = aws_rds_cluster.this.endpoint
    port                = aws_rds_cluster.this.port
    dbClusterIdentifier = aws_rds_cluster.this.cluster_identifier
  }
}

# Secrets saving
resource "aws_secretsmanager_secret" "dbuser" {
  depends_on = [aws_rds_cluster.this]
  name       = "${local.secret_store_path}/${var.settings.engine_type}/${aws_rds_cluster.this.cluster_identifier}/${local.db_name}/master-username"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "dbuser" {
  secret_id     = aws_secretsmanager_secret.dbuser.id
  secret_string = local.master_user
}

resource "aws_secretsmanager_secret" "randompass" {
  depends_on = [aws_rds_cluster.this]
  name       = "${local.secret_store_path}/${var.settings.engine_type}/${aws_rds_cluster.this.cluster_identifier}/${local.db_name}/master-password"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "randompass" {
  secret_id     = aws_secretsmanager_secret.randompass.id
  secret_string = random_password.randompass.result
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  name = "${local.secret_store_path}/${var.settings.engine_type}/${aws_rds_cluster.this.cluster_identifier}/${local.db_name}/master-rds-credentials"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id     = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode(local.rds_credentials)
}
