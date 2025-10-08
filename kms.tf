##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_iam_policy_document" "rds_kms_policy" {
  count = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_arn, "") == "" && try(var.settings.storage.encryption.kms_key_id, "") == "" && try(var.settings.storage.encryption.kms_key_alias, "") == "" ? 1 : 0
  statement {
    sid    = "AllowRDSToUseTheKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.${data.aws_region.current.id}.amazonaws.com"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${data.aws_region.current.id}.amazonaws.com"]
    }
  }
  statement {
    sid    = "AllowRoot"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "this" {
  count                   = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_arn, "") == "" && try(var.settings.storage.encryption.kms_key_id, "") == "" && try(var.settings.storage.encryption.kms_key_alias, "") == "" ? 1 : 0
  description             = "KMS key for RDS - ${local.cluster_identifier}"
  deletion_window_in_days = try(var.settings.storage.encryption.deletion_window_in_days, 30)
  enable_key_rotation     = true
  rotation_period_in_days = try(var.settings.storage.encryption.rotation_period_in_days, 90)
  policy                  = data.aws_iam_policy_document.rds_kms_policy[0].json
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_arn, "") == "" && try(var.settings.storage.encryption.kms_key_id, "") == "" && try(var.settings.storage.encryption.kms_key_alias, "") == "" ? 1 : 0
  target_key_id = aws_kms_key.this[0].id
  name          = "alias/aurora/${local.cluster_identifier}"
}

data "aws_kms_alias" "rds" {
  count = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_alias, "") != "" ? 1 : 0
  name  = var.settings.storage.encryption.kms_key_alias
}

data "aws_kms_key" "rds" {
  count  = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_id, "") != "" ? 1 : 0
  key_id = var.settings.storage.encryption.kms_key_id
}