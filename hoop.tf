##
# (c) 2021-2026
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
  cluster_owner_name          = "${aws_rds_cluster.this.cluster_identifier}-ow"
  master_user_secret_name_arn = try(split(":", aws_rds_cluster.this.master_user_secret[0].secret_arn), [])
  master_user_secret_name     = length(local.master_user_secret_name_arn) - 1 >= 0 ? local.master_user_secret_name_arn[length(local.master_user_secret_name_arn) - 1] : ""
  hoop_enabled                = try(var.settings.hoop.enabled, false) && !try(var.settings.migration.enabled, false)
  hoop_secret_prefix          = try(var.settings.hoop.community, true) ? "_aws" : "_envs/aws"
  hoop_secret_sep             = try(var.settings.hoop.community, true) ? ":" : "#"
  hoop_is_postgres            = try(var.settings.engine_type, "") == "aurora-postgresql"
  hoop_is_managed             = try(var.settings.managed_password, false) && !try(var.settings.migration.in_progress, false)
  hoop_managed_secret_name    = try(data.aws_secretsmanager_secret.rds_managed[0].name, "")
  hoop_unmanaged_secret_name  = try(aws_secretsmanager_secret.rds[0].name, "")
}

output "hoop_connections" {
  value = local.hoop_enabled ? {
    "owner" = {
      name           = local.cluster_owner_name
      agent_id       = var.settings.hoop.agent_id
      type           = "database"
      subtype        = local.hoop_is_postgres ? "postgres" : "mysql"
      tags           = try(var.settings.hoop.tags, {})
      access_control = toset(try(var.settings.hoop.access_control, []))
      access_modes   = { connect = "enabled", exec = "enabled", runbooks = "enabled", schema = "enabled" }
      import         = try(var.settings.hoop.import, false)
      secrets = local.hoop_is_postgres && local.hoop_is_managed ? {
        "envvar:HOST"    = aws_rds_cluster.this.endpoint
        "envvar:PORT"    = tostring(aws_rds_cluster.this.port)
        "envvar:USER"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"      = aws_rds_cluster.this.database_name
        "envvar:SSLMODE" = "prefer"
        } : local.hoop_is_postgres && !local.hoop_is_managed ? {
        "envvar:HOST"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"      = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}dbname"
        "envvar:SSLMODE" = "prefer"
        } : local.hoop_is_managed ? {
        "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}dbname"
        } : {
        "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}dbname"
      }
    }
  } : null
  precondition {
    condition     = !local.hoop_enabled || try(var.settings.hoop.agent_id, "") != ""
    error_message = "settings.hoop.agent_id must be set (as a Hoop agent UUID) when settings.hoop.enabled is true."
  }
}
