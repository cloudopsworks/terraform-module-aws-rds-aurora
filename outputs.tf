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
  value = try(var.settings.managed_password_rotation, false) ? data.aws_secretsmanager_secret.rds_managed[0].name : aws_secretsmanager_secret.rds[0].name
}
