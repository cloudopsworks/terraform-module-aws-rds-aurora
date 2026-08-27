##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username            = local.master_user
    password            = local.generate_password ? random_password.randompass[0].result : null
    engine              = aws_rds_cluster.this.engine
    host                = aws_rds_cluster.this.endpoint
    port                = aws_rds_cluster.this.port
    dbname              = aws_rds_cluster.this.database_name
    dbClusterIdentifier = aws_rds_cluster.this.cluster_identifier
    sslmode             = "require"
  }
  # Guarded on the database name, which may be null. format() would otherwise be reached with a null
  # argument and collapse the path segment, yielding a name with an empty component
  secret_name        = local.db_name != null ? format("%s/%s/%s/%s/master-rds-credentials", local.secret_store_path, var.settings.engine_type, aws_rds_cluster.this.cluster_identifier, local.db_name) : null
  secret_description = local.db_name != null ? format("RDS Master credentials - %s - %s - %s - %s", local.master_user, var.settings.engine_type, aws_rds_cluster.this.cluster_identifier, local.db_name) : null
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  count       = local.create_secret ? 1 : 0
  name        = local.secret_name
  description = local.secret_description
  kms_key_id  = try(var.settings.password_secret_kms_key_id, null)
  tags        = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  count         = local.create_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds[count.index].id
  secret_string = jsonencode(local.rds_credentials)
}

data "aws_lambda_function" "rotation_function" {
  count         = local.create_secret && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  function_name = var.settings.rotation_lambda_name
}

resource "aws_secretsmanager_secret_rotation" "user" {
  count               = local.create_secret && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.rds[0].id
  rotation_lambda_arn = data.aws_lambda_function.rotation_function[count.index].arn

  rotation_rules {
    automatically_after_days = try(var.settings.password_rotation_period, 90)
    duration                 = try(var.settings.rotation_duration, "1h")
  }
}

# aws_rds_cluster has no native master user password rotation arguments, unlike the upstream RDS
# instance module, so the rotation of the AWS managed secret is declared here
resource "aws_secretsmanager_secret_rotation" "managed" {
  count     = local.manage_master_password && try(var.settings.managed_password_rotation, false) ? 1 : 0
  secret_id = aws_rds_cluster.this.master_user_secret[0].secret_arn
  rotation_rules {
    automatically_after_days = try(var.settings.password_rotation_period, 90)
    duration                 = try(var.settings.rotation_duration, "1h")
  }
}
