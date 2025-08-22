##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_iam_policy_document" "rds_kms_policy" {
  count = try(var.settings.encryption.enabled, false) && try(var.settings.encryption.kms_key_id, "") == "" ? 1 : 0
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
  count                   = try(var.settings.encryption.enabled, false) && try(var.settings.encryption.kms_key_id, "") == "" ? 1 : 0
  description             = "KMS key for RDS - ${local.cluster_identifier}"
  deletion_window_in_days = try(var.settings.encryption.deletion_window_in_days, 30)
  enable_key_rotation     = true
  rotation_period_in_days = try(var.settings.encryption.rotation_period_in_days, 90)
  policy                  = data.aws_iam_policy_document.rds_kms_policy[0].json
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = try(var.settings.encryption.enabled, false) && try(var.settings.encryption.kms_key_id, "") == "" ? 1 : 0
  target_key_id = aws_kms_key.this[0].id
  name          = "alias/aurora/${local.cluster_identifier}"
}