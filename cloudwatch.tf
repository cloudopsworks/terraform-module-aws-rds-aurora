##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "aws_cloudwatch_log_group" "this" {
  for_each          = toset(local.cw_logs)
  name              = each.value
  retention_in_days = try(var.settings.cloudwatch.retention_days, 90)
  skip_destroy      = try(var.settings.cloudwatch.retain, true)
  kms_key_id        = try(var.settings.storage.encryption.enabled, false) ? try(aws_kms_key.this[0].arn, var.settings.storage.encryption.kms_key_arn, null) : null
  tags              = local.all_tags
}