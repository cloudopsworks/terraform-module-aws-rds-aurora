##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# output "rds_password" {
#   description = "The password for the RDS cluster"
#   value       = random_password.randompass[0].result
#   sensitive   = true
# }
# RDS Password will not be exposed by any means

output "rds_security_group_ids" {
  description = "The list of security group IDs attached to the cluster, created by the module or looked up from the existing security group"
  value       = local.security_group_ids
}

output "rds_cluster_identifier" {
  description = "The identifier of the Aurora cluster"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "rds_cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = aws_rds_cluster.this.arn
}

output "rds_cluster_endpoint" {
  description = "The writer endpoint of the Aurora cluster, without the port"
  value       = aws_rds_cluster.this.endpoint
}

output "rds_cluster_hosted_zone_id" {
  description = "The Route53 hosted zone ID of the Aurora cluster, to build alias records"
  value       = aws_rds_cluster.this.hosted_zone_id
}

output "rds_cluster_reader_endpoint" {
  description = "The read-only endpoint of the Aurora cluster, load balanced across the reader instances"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "rds_cluster_port" {
  description = "The port the Aurora cluster is listening on"
  value       = aws_rds_cluster.this.port
}

output "rds_cluster_master_username" {
  description = "The master username of the Aurora cluster, null when migrating from an existing RDS instance"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

output "rds_cluster_instance_ids" {
  description = "The identifiers of the cluster instances, in replica index order"
  value       = aws_rds_cluster_instance.this[*].id
}

output "rds_cluster_instance_endpoints" {
  description = "The endpoints of the cluster instances, in replica index order"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "rds_global_cluster_id" {
  description = "The ID of the Aurora global cluster, empty when settings.global_cluster.create is false"
  value       = aws_rds_global_cluster.this[*].id
}

output "cluster_secrets_credentials" {
  description = "The name of the Secrets Manager secret holding the master credentials, AWS managed when settings.managed_password is true, module managed otherwise, null when migrating or restoring from a snapshot"
  value       = local.manage_master_password ? local.master_user_secret_name : one(aws_secretsmanager_secret.rds[*].name)
}

output "cluster_secrets_credentials_arn" {
  description = "The ARN of the Secrets Manager secret holding the master credentials, AWS managed when settings.managed_password is true, module managed otherwise, null when migrating or restoring from a snapshot"
  value       = local.manage_master_password ? try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null) : one(aws_secretsmanager_secret.rds[*].arn)
}

output "cluster_kms_key_id" {
  description = "The ID of the KMS key encrypting the cluster storage, module managed or resolved from the configured key ID or alias, null when encryption is disabled"
  value = local.encryption_enabled ? try(coalesce(
    one(aws_kms_key.this[*].id),
    one(data.aws_kms_alias.rds[*].target_key_id),
    one(data.aws_kms_key.rds[*].key_id),
    local.encryption_key_id,
  ), null) : null
}

output "cluster_kms_key_arn" {
  description = "The ARN of the KMS key encrypting the cluster storage, null when encryption is disabled"
  value       = local.cluster_kms_key_arn
}

output "cluster_kms_key_alias" {
  description = "The alias of the KMS key encrypting the cluster storage, the module managed alias when the module owns the key, the configured alias otherwise, null when none applies"
  value       = local.encryption_enabled ? try(coalesce(one(aws_kms_alias.this[*].name), local.encryption_key_alias_raw != "" ? local.encryption_key_alias : null), null) : null
}

output "cluster_cloudwatch_kms_key_arn" {
  description = "The ARN of the KMS key encrypting the cluster CloudWatch log groups, resolved from settings.cloudwatch or falling back to the module managed key, null when the log groups use AWS default encryption"
  value       = local.cw_kms_key_arn
}

output "cluster_performance_insights_kms_key_arn" {
  description = "The ARN of the KMS key encrypting Performance Insights, null when Performance Insights or its encryption is disabled"
  value       = local.perf_kms_key_arn
}
