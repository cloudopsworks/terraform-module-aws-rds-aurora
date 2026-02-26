##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "hoop_connection" "postgres_managed" {
  count    = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && !try(var.settings.migration.in_progress, false) && try(var.settings.hoop.agent_id, "") != "" ? 1 : 0
  name     = local.cluster_owner_name
  agent_id = var.settings.hoop.agent_id
  type     = "database"
  subtype  = "postgres"
  secrets = {
    "envvar:HOST"    = aws_rds_cluster.this.endpoint
    "envvar:PORT"    = aws_rds_cluster.this.port
    "envvar:USER"    = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username"
    "envvar:PASS"    = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password"
    "envvar:DB"      = aws_rds_cluster.this.database_name
    "envvar:SSLMODE" = "prefer"
  }
  access_mode_connect  = "enabled"
  access_mode_exec     = "enabled"
  access_mode_runbooks = "enabled"
  access_schema        = "enabled"
  tags                 = try(var.settings.hoop.tags, {})
  lifecycle {
    ignore_changes = [
      command,
    ]
  }

}

resource "hoop_connection" "postgres" {
  count    = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-postgresql" && !try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && try(var.settings.hoop.agent_id, "") != "" ? 1 : 0
  name     = local.cluster_owner_name
  agent_id = var.settings.hoop.agent_id
  type     = "database"
  subtype  = "postgres"
  secrets = {
    "envvar:HOST"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:host"
    "envvar:PORT"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:port"
    "envvar:USER"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:username"
    "envvar:PASS"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:password"
    "envvar:DB"      = "_aws:${aws_secretsmanager_secret.rds[0].name}:dbname"
    "envvar:SSLMODE" = "prefer"
  }
  access_mode_connect  = "enabled"
  access_mode_exec     = "enabled"
  access_mode_runbooks = "enabled"
  access_schema        = "enabled"
  tags                 = try(var.settings.hoop.tags, {})
  lifecycle {
    ignore_changes = [
      command,
    ]
  }

}

resource "hoop_connection" "mysql_managed" {
  count    = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && !try(var.settings.migration.in_progress, false) && try(var.settings.hoop.agent_id, "") != "" ? 1 : 0
  name     = local.cluster_owner_name
  agent_id = var.settings.hoop.agent_id
  type     = "database"
  subtype  = "mysql"
  secrets = {
    "envvar:HOST" = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:host"
    "envvar:PORT" = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:port"
    "envvar:USER" = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:username"
    "envvar:PASS" = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:password"
    "envvar:DB"   = "_aws:${data.aws_secretsmanager_secret.rds_managed[0].name}:dbname"
  }
  access_mode_connect  = "enabled"
  access_mode_exec     = "enabled"
  access_mode_runbooks = "enabled"
  access_schema        = "enabled"
  tags                 = try(var.settings.hoop.tags, {})
  lifecycle {
    ignore_changes = [
      command,
    ]
  }

}

resource "hoop_connection" "mysql" {
  count    = try(var.settings.hoop.enabled, false) && var.settings.engine_type == "aurora-mysql" && !try(var.settings.managed_password, false) && !try(var.settings.migration.enabled, false) && try(var.settings.hoop.agent_id, "") != "" ? 1 : 0
  name     = local.cluster_owner_name
  agent_id = var.settings.hoop.agent_id
  type     = "database"
  subtype  = "mysql"
  secrets = {
    "envvar:HOST"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:host"
    "envvar:PORT"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:port"
    "envvar:USER"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:username"
    "envvar:PASS"    = "_aws:${aws_secretsmanager_secret.rds[0].name}:password"
    "envvar:DB"      = "_aws:${aws_secretsmanager_secret.rds[0].name}:dbname"
    "envvar:SSLMODE" = "prefer"
  }
  access_mode_connect  = "enabled"
  access_mode_exec     = "enabled"
  access_mode_runbooks = "enabled"
  access_schema        = "enabled"
  tags                 = try(var.settings.hoop.tags, {})
  lifecycle {
    ignore_changes = [
      command,
    ]
  }

}

resource "hoop_plugin_connection" "access_control" {
  count         = length(try(var.settings.hoop.access_control, [])) > 0 && try(var.settings.hoop.agent_id, "") != "" ? 1 : 0
  connection_id = try(hoop_connection.postgres_managed[0].id, hoop_connection.postgres[0].id, hoop_connection.mysql_managed[0].id, hoop_connection.mysql[0].id)
  plugin_name   = "access_control"
  config        = var.settings.hoop.access_control
}