##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# output "rds_password" {
#   description = "The password for the RDS instance"
#   value       = random_password.randompass[0].result
#   sensitive   = true
# }
# RDS Password will not be exposed by any means

output "rds_security_group_ids" {
  value = local.security_group_ids
}

output "rds_cluster_arn" {
  value = aws_rds_cluster.this.arn
}

output "rds_cluster_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "rds_cluster_hosted_zone_id" {
  value = aws_rds_cluster.this.hosted_zone_id
}

output "rds_cluster_reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}
output "rds_cluster_port" {
  value = aws_rds_cluster.this.port
}

output "rds_cluster_master_username" {
  value = aws_rds_cluster.this.master_username
}

output "rds_cluster_instance_ids" {
  value = aws_rds_cluster_instance.this[*].id
}

output "rds_cluster_instance_endpoints" {
  value = aws_rds_cluster_instance.this[*].endpoint
}

output "rds_global_cluster_id" {
  value = aws_rds_global_cluster.this[*].id
}

output "cluster_secrets_credentials" {
  value = try(var.settings.managed_password, false) ? local.master_user_secret_name : aws_secretsmanager_secret.rds[0].name
}

output "cluster_secrets_credentials_arn" {
  value = try(var.settings.managed_password, false) ? try(aws_rds_cluster.this.master_user_secret[0].secret_arn, "") : aws_secretsmanager_secret.rds[0].arn
}

output "cluster_kms_key_id" {
  value = try(var.settings.storage.encryption.enabled, false) ? try(var.settings.storage.encryption.kms_key_id, aws_kms_key.this[0].id) : null
}

output "cluster_kms_key_arn" {
  value = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_id, "") == "" ? aws_kms_key.this[0].arn : null
}

output "cluster_kms_key_alias" {
  value = try(var.settings.storage.encryption.enabled, false) && try(var.settings.storage.encryption.kms_key_id, "") == "" ? aws_kms_alias.this[0].name : null
}