##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

##  YAML Input Format
# settings:
#   # Global Cluster
#   global_cluster:
#     create: true | false
#     id: "arn:aws:rds:us-east-1:123456789012:global-cluster:mydb" # Optional conflicts with create = true
#   # Cluster general
#   name_prefix: "mydb"
#   database_name: "mydb"
#   master_username: "admin"
#   engine_type: "aurora-postgresql" or "aurora-mysql"
#   engine_version: "10.7"
#   availability_zones: ["us-east-1a", "us-east-1b"]
#   rds_port: 5432
#   apply_immediately: true
#   encryption:
#     enabled: true
#     kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
#   backup:
#     retention_period: 7
#     window: "01:00-03:00"
#     copy_tags: true
#   deletion_protection: true
#   allow_upgrade: true
#   # Instance specific
#   replicas: 2
#   instance_size: "db.r5.large"
#   managed_password_rotation: false
#   hoop:
#     enabled: true | false
#     agent: hoop-agent-name
#     tags: ["tag1", "tag2"]
variable "settings" {
  description = "Settings for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# vpc:
#   vpc_id: "vpc-12345678901234"
#   subnet_group: "database_subnet_group_name"
#   subnet_ids:
#     - "subnet-abcdef123456789"
#     - "subnet-abcdef123456781"
#     - "subnet-abcdef123456782"
variable "vpc" {
  description = "VPC for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# security_groups:
#   create: true
#   name: sg-rds # Name of the security group if create = false
#   allow_cidrs:
#     - "1.2.3.4/32"
#     - "1.2.0.0/16"
#   allow_security_groups:
#     - "sg-name-123456"
#     - "sg-name-abcdef"
variable "security_groups" {
  description = "Security groups for RDS instance"
  type        = any
  default     = {}
}