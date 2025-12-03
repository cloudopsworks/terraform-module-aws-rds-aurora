##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_secretsmanager_secret" "rds_managed" {
  count = try(var.settings.managed_password, false) && try(var.settings.hoop.enabled, false) && !try(var.settings.migration.in_progress, false) ? 1 : 0
  arn   = aws_rds_cluster.this.master_user_secret[count.index].secret_arn
}

locals {
  master_user_secret_name_arn = try(split(":", aws_rds_cluster.this.master_user_secret[0].secret_arn), [])
  master_user_secret_name     = length(local.master_user_secret_name_arn) - 1 >= 0 ? local.master_user_secret_name_arn[length(local.master_user_secret_name_arn) - 1] : ""
  hoop_tags                   = length(try(var.settings.hoop.tags, [])) > 0 ? join(" ", [for v in var.settings.hoop.tags : "--tags \"${v}\""]) : ""
  hoop_connection_postgres_managed = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && !try(var.settings.migration.in_progress, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/postgres \
  -e "HOST=${aws_rds_cluster.this.endpoint}" \
  -e "PORT=${aws_rds_cluster.this.port}" \
  -e "USER=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username" \
  -e "PASS=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password" \
  -e "DB=${aws_rds_cluster.this.database_name}" \
  -e "SSLMODE=prefer" \
  --overwrite \
  ${local.hoop_tags}
EOT
  ) : null
  hoop_connection_postgres = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && !try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/postgres \
  -e "HOST=_aws:${aws_secretsmanager_secret.rds[0].name}:host" \
  -e "PORT=_aws:${aws_secretsmanager_secret.rds[0].name}:port" \
  -e "USER=_aws:${aws_secretsmanager_secret.rds[0].name}:username" \
  -e "PASS=_aws:${aws_secretsmanager_secret.rds[0].name}:password" \
  -e "DB=_aws:${aws_secretsmanager_secret.rds[0].name}:dbname" \
  -e "SSLMODE=prefer" \
  --overwrite \
  ${local.hoop_tags}
EOT
  ) : null
  hoop_connection_mysql_managed = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && !try(var.settings.migration.in_progress, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/mysql \
  -e "HOST=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:host" \
  -e "PORT=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:port" \
  -e "USER=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username" \
  -e "PASS=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password" \
  -e "DB=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:dbname" \
  --overwrite \
  ${local.hoop_tags}
EOT
  ) : null
  hoop_connection_mysql = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && !try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/mysql \
  -e "HOST=_aws:${aws_secretsmanager_secret.rds[0].name}:host" \
  -e "PORT=_aws:${aws_secretsmanager_secret.rds[0].name}:port" \
  -e "USER=_aws:${aws_secretsmanager_secret.rds[0].name}:username" \
  -e "PASS=_aws:${aws_secretsmanager_secret.rds[0].name}:password" \
  -e "DB=_aws:${aws_secretsmanager_secret.rds[0].name}:dbname" \
  --overwrite \
  ${local.hoop_tags}
EOT
  ) : null

}

resource "null_resource" "hoop_connection_postgres_managed" {
  count = local.hoop_connection_postgres_managed != null && var.run_hoop ? 1 : 0
  provisioner "local-exec" {
    command     = local.hoop_connection_postgres_managed
    interpreter = ["bash", "-c"]
  }
}

output "hoop_connection_postgres_managed" {
  value = local.hoop_connection_postgres_managed
}

resource "null_resource" "hoop_connection_postgres" {
  count = local.hoop_connection_postgres != null && var.run_hoop ? 1 : 0
  provisioner "local-exec" {
    command     = local.hoop_connection_postgres
    interpreter = ["bash", "-c"]
  }
}

output "hoop_connection_postgres" {
  value = local.hoop_connection_postgres
}

resource "null_resource" "hoop_connection_mysql_managed" {
  count = local.hoop_connection_mysql_managed != null && var.run_hoop ? 1 : 0
  provisioner "local-exec" {
    command     = local.hoop_connection_mysql_managed
    interpreter = ["bash", "-c"]
  }
}

output "hoop_connection_mysql_managed" {
  value = local.hoop_connection_mysql_managed
}

resource "null_resource" "hoop_connection_mysql" {
  count = local.hoop_connection_mysql != null && var.run_hoop ? 1 : 0
  provisioner "local-exec" {
    command     = local.hoop_connection_mysql
    interpreter = ["bash", "-c"]
  }
}

output "hoop_connection_mysql" {
  value = local.hoop_connection_mysql
}
