##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "rds_monitoring" {
  count = try(var.settings.monitoring.interval, 0) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count              = try(var.settings.monitoring.interval, 0) > 0 ? 1 : 0
  name               = format("%s-mon-role", local.cluster_identifier)
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring[0].json
  tags               = local.all_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = try(var.settings.monitoring.interval, 0) > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}