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