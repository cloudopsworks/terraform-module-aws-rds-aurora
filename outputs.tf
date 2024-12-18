##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "rds_password" {
  description = "The password for the RDS instance"
  value       = random_password.randompass.result
  sensitive   = true
}

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

output "cluster_secrets_admin_user" {
  value = aws_secretsmanager_secret.dbuser.name
}

output "cluster_secrets_admin_password" {
  value = aws_secretsmanager_secret.randompass.name
}

output "cluster_secrets_credentials" {
  value = aws_secretsmanager_secret.rds.name
}