##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_secretsmanager_secret" "rds_managed" {
  count = try(var.settings.managed_password_rotation, false) ? 1 : 0
  arn   = aws_rds_cluster.this.master_user_secret[count.index].secret_arn
}

locals {
  hoop_tags = length(try(var.settings.hoop.tags, [])) > 0 ? join(" ", [for v in var.settings.hoop.tags : "--tags \"${v}\""]) : ""
}


output "hoop_connection_postgres_managed" {
  value = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && try(var.settings.managed_password_rotation, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/postgres \
  -e "HOST=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:host" \
  -e "PORT=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:port" \
  -e "USER=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username" \
  -e "PASS=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password" \
  -e "DB=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:dbname" \
  -e "SSLMODE=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:sslmode" \
  --overwrite \
  ${local.hoop_tags} \
EOT
  ) : null
}

output "hoop_connection_postgres" {
  value = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && !try(var.settings.managed_password_rotation, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/postgres \
  -e "HOST=_aws:${aws_secretsmanager_secret.rds[0].name}:host" \
  -e "PORT=_aws:${aws_secretsmanager_secret.rds[0].name}:port" \
  -e "USER=_aws:${aws_secretsmanager_secret.rds[0].name}:username" \
  -e "PASS=_aws:${aws_secretsmanager_secret.rds[0].name}:password" \
  -e "DB=_aws:${aws_secretsmanager_secret.rds[0].name}:dbname" \
  -e "SSLMODE=_aws:${aws_secretsmanager_secret.rds[0].name}:sslmode" \
  --overwrite \
  ${local.hoop_tags} \
EOT
  ) : null
}

output "hoop_connection_mysql_managed" {
  value = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && try(var.settings.managed_password_rotation, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/mysql \
  -e "HOST=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:host" \
  -e "PORT=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:port" \
  -e "USER=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username" \
  -e "PASS=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password" \
  -e "DB=_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:dbname" \
  --overwrite \
  ${local.hoop_tags} \
EOT
  ) : null
}

output "hoop_connection_mysql" {
  value = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && !try(var.settings.managed_password_rotation, false) ? (<<EOT
hoop admin create connection ${aws_rds_cluster.this.cluster_identifier}-ow \
  --agent ${var.settings.hoop.agent} \
  --type database/postgres \
  -e "HOST=_aws:${aws_secretsmanager_secret.rds[0].name}:host" \
  -e "PORT=_aws:${aws_secretsmanager_secret.rds[0].name}:port" \
  -e "USER=_aws:${aws_secretsmanager_secret.rds[0].name}:username" \
  -e "PASS=_aws:${aws_secretsmanager_secret.rds[0].name}:password" \
  -e "DB=_aws:${aws_secretsmanager_secret.rds[0].name}:dbname" \
  --overwrite \
  ${local.hoop_tags} \
EOT
  ) : null
}
