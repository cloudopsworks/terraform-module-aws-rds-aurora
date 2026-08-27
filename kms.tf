##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  # Cluster storage encryption. settings.encryption takes precedence over settings.storage.encryption.
  # The raw alias is kept alongside the normalised one so an unset alias stays distinguishable from
  # a normalised empty one, which would otherwise read as "alias/".
  encryption_enabled       = try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false)
  encryption_key_arn       = try(var.settings.encryption.kms_key_arn, var.settings.storage.encryption.kms_key_arn, "")
  encryption_key_id        = try(var.settings.encryption.kms_key_id, var.settings.storage.encryption.kms_key_id, "")
  encryption_key_alias_raw = try(var.settings.encryption.kms_key_alias, var.settings.storage.encryption.kms_key_alias, "")
  encryption_key_alias     = startswith(local.encryption_key_alias_raw, "alias/") ? local.encryption_key_alias_raw : format("alias/%s", local.encryption_key_alias_raw)
  create_kms_key           = local.encryption_enabled && local.encryption_key_arn == "" && local.encryption_key_id == "" && local.encryption_key_alias_raw == ""

  # Module managed storage key parameters. The settings.encryption names are the ones shared with
  # terraform-module-aws-rds-database, the *_in_days names are the ones this module has always used.
  kms_deletion_window  = try(var.settings.encryption.deletion_window, var.settings.storage.encryption.deletion_window_in_days, var.settings.storage.encryption.deletion_window, 30)
  kms_rotation_period  = try(var.settings.encryption.rotation_period, var.settings.storage.encryption.rotation_period_in_days, var.settings.storage.encryption.rotation_period, 90)
  kms_rotation_enabled = try(var.settings.encryption.rotation_enabled, var.settings.storage.encryption.rotation_enabled, true)
  kms_multi_region     = try(var.settings.encryption.multi_region, var.settings.storage.encryption.multi_region, false)

  # CloudWatch log group encryption. The log groups are always created by this module, so there is
  # no enable flag here: a key is used when one is configured, or when the module owns one.
  cw_encryption_key_id        = try(var.settings.cloudwatch.kms_key_id, "")
  cw_encryption_key_alias_raw = try(var.settings.cloudwatch.kms_key_alias, "")
  cw_encryption_key_alias     = startswith(local.cw_encryption_key_alias_raw, "alias/") ? local.cw_encryption_key_alias_raw : format("alias/%s", local.cw_encryption_key_alias_raw)

  # Performance Insights encryption. settings.performance_insights takes precedence over
  # settings.performance, and the key may be given either flat or under an encryption block.
  perf_enabled                  = try(var.settings.performance_insights.enabled, var.settings.performance.enabled, false)
  perf_encryption_enabled       = try(var.settings.performance_insights.encryption.enabled, var.settings.performance.encryption.enabled, false)
  perf_encryption_key_arn       = try(var.settings.performance_insights.kms_key_arn, var.settings.performance_insights.encryption.kms_key_arn, var.settings.performance.encryption.kms_key_arn, "")
  perf_encryption_key_id        = try(var.settings.performance_insights.kms_key_id, var.settings.performance_insights.encryption.kms_key_id, var.settings.performance.encryption.kms_key_id, "")
  perf_encryption_key_alias_raw = try(var.settings.performance_insights.kms_key_alias, var.settings.performance_insights.encryption.kms_key_alias, var.settings.performance.encryption.kms_key_alias, "")
  perf_encryption_key_alias     = startswith(local.perf_encryption_key_alias_raw, "alias/") ? local.perf_encryption_key_alias_raw : format("alias/%s", local.perf_encryption_key_alias_raw)
  create_perf_key               = local.perf_enabled && local.perf_encryption_enabled && local.perf_encryption_key_arn == "" && local.perf_encryption_key_id == "" && local.perf_encryption_key_alias_raw == ""

  # Resolved keys handed to the cluster, its instances and the log groups. coalesce is required here:
  # one() yields null on an empty list rather than raising, so a try() chain would always return its
  # first argument and the fallbacks would never be reached.
  cluster_kms_key_arn = local.encryption_enabled ? try(coalesce(
    one(aws_kms_key.this[*].arn),
    one(data.aws_kms_alias.rds[*].target_key_arn),
    one(data.aws_kms_key.rds[*].arn),
    local.encryption_key_arn,
  ), null) : null

  # Falls back to the module managed key only. A key the module does not own cannot be guaranteed to
  # carry the CloudWatch Logs grant, and an AWS managed key such as aws/rds carries none and cannot be
  # edited, so reusing one here would fail at apply.
  cw_kms_key_arn = try(coalesce(
    one(data.aws_kms_key.cw[*].arn),
    one(data.aws_kms_alias.cw[*].target_key_arn),
    one(aws_kms_key.this[*].arn),
  ), null)

  perf_kms_key_arn = local.perf_enabled && local.perf_encryption_enabled ? try(coalesce(
    one(aws_kms_key.perf[*].arn),
    one(data.aws_kms_alias.perf[*].target_key_arn),
    one(data.aws_kms_key.perf[*].arn),
    local.perf_encryption_key_arn,
  ), null) : null
}

data "aws_partition" "current" {}

# Key policy for the module managed storage key. The AWS default key policy only grants the account
# root, which is not enough: CloudWatch Logs reaches the key as a service principal and never through
# IAM, so without an explicit grant the encrypted log group cannot be written.
data "aws_iam_policy_document" "kms" {
  count = local.create_kms_key ? 1 : 0

  # Keeps the key manageable through IAM. Dropping this statement orphans the key
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Cluster storage encryption reaches the key through the RDS service, so a single ViaService
  # statement covers it. RDS creates its own grants, which is why kms:CreateGrant is included
  statement {
    sid    = "AllowAccessThroughRDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${data.aws_region.current.region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Scoped to the log groups this module creates for the cluster,
  # /aws/rds/cluster/<identifier>/<log type>
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/cluster/${local.cluster_identifier}/*"]
    }
  }
}

# The Performance Insights key gets its own policy. It used to borrow the storage key policy
# document, whose count keys off the storage encryption settings, so enabling Performance Insights
# encryption without a module managed storage key raised an index error.
data "aws_iam_policy_document" "kms_perf" {
  count = local.create_perf_key ? 1 : 0

  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Performance Insights reaches the key through RDS and creates its own grants
  statement {
    sid    = "AllowAccessThroughRDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${data.aws_region.current.region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "this" {
  count                   = local.create_kms_key ? 1 : 0
  description             = "KMS key for RDS - ${local.cluster_identifier}"
  policy                  = data.aws_iam_policy_document.kms[0].json
  deletion_window_in_days = local.kms_deletion_window
  enable_key_rotation     = local.kms_rotation_enabled
  rotation_period_in_days = local.kms_rotation_period
  multi_region            = local.kms_multi_region
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = local.create_kms_key ? 1 : 0
  target_key_id = aws_kms_key.this[0].id
  name          = "alias/aurora/${local.cluster_identifier}"
}

data "aws_kms_key" "rds" {
  count  = local.encryption_enabled && local.encryption_key_id != "" ? 1 : 0
  key_id = local.encryption_key_id
}

data "aws_kms_alias" "rds" {
  count = (local.encryption_enabled &&
    local.encryption_key_id == "" &&
    local.encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.encryption_key_alias
}

data "aws_kms_key" "cw" {
  count  = local.cw_encryption_key_id != "" ? 1 : 0
  key_id = local.cw_encryption_key_id
}

data "aws_kms_alias" "cw" {
  count = (local.cw_encryption_key_id == "" &&
    local.cw_encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.cw_encryption_key_alias
}

resource "aws_kms_key" "perf" {
  count                   = local.create_perf_key ? 1 : 0
  description             = "KMS Key for RDS Performance Insights Encryption - ${local.cluster_identifier}"
  policy                  = data.aws_iam_policy_document.kms_perf[0].json
  deletion_window_in_days = local.kms_deletion_window
  enable_key_rotation     = local.kms_rotation_enabled
  rotation_period_in_days = local.kms_rotation_period
  multi_region            = local.kms_multi_region
  tags                    = local.all_tags
}

resource "aws_kms_alias" "perf" {
  count         = local.create_perf_key ? 1 : 0
  target_key_id = aws_kms_key.perf[0].id
  name          = "alias/aurora/perf/${local.cluster_identifier}"
}

data "aws_kms_key" "perf" {
  count  = local.perf_enabled && local.perf_encryption_enabled && local.perf_encryption_key_id != "" ? 1 : 0
  key_id = local.perf_encryption_key_id
}

data "aws_kms_alias" "perf" {
  count = (local.perf_enabled && local.perf_encryption_enabled &&
    local.perf_encryption_key_id == "" &&
    local.perf_encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.perf_encryption_key_alias
}
