##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

import {
  for_each = toset(try(var.settings.cloudwatch.import, false) ? local.cw_logs : [])
  id       = each.value
  to       = aws_cloudwatch_log_group.this[each.key]
}

resource "aws_cloudwatch_log_group" "this" {
  for_each          = toset(local.cw_logs)
  name              = each.value
  retention_in_days = try(var.settings.cloudwatch.retention_days, 90)
  skip_destroy      = try(var.settings.cloudwatch.retain, true)
  kms_key_id        = local.cw_kms_key_arn
  tags              = local.all_tags
}
