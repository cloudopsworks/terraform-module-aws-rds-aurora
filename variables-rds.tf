##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

##  YAML Input Format
# settings:
#   # Recovery
#   recovery:
#     enabled: true | false # If true, the cluster will be recovered from snapshot on same clustername or other Cluster
#     cluster_identifier: "rds-cluster-name" # (optional) if recovery will be done from other Cluster
#     snapshot_identifier: "rds-cluster-snapshot-name" # (optional) if recovery will be done from snapshot
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
#   engine_mode: "provisioned" | "serverless" # (optional) if serverless.enabled is true
#   auto_minor_upgrade: true
#   availability_zones: ["us-east-1a", "us-east-1b"]
#   rds_port: 5432
#   apply_immediately: true
#   publicly_accessible: true | false # (optional) If true, the cluster will be publicly accessible
#   storage:
#     encryption:
#       enabled: true
#       kms_key_id: "12345678-1234-1234-1234-123456789012"
#       kms_key_arn: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
#       kms_key_alias: "aws/rds"
#     type: "" | aurora-iopt1 | io1 | io2
#     iops: 1000 # required if type is io1 or io2
#   monitoring:
#     interval: 0 # in seconds, 0 to disable, Valid Values: 0, 1, 5, 10, 15, 30, 60.
#   maintenance:
#     window: "sun:03:00-sun:04:00"
#   backup:
#     retention_period: 7
#     window: "01:00-02:30"
#     copy_tags: true
#   deletion_protection: true
#   allow_upgrade: true
#   # Instance specific
#   replicas:
#     count: 2
#     replica_0:
#       availability_zone: "us-east-1a"
#       promotion_tier: 10
#       maintenance_window: "wed:03:00-wed:04:00"
#     replica_1:
#       availability_zone: "us-east-1b"
#   instance_size: "db.r5.large" | "db.serverless"
#   serverless:
#     enabled: true | false
#     v2: true | false
#     scaling_configuration:
#       # for V2 and V1
#       min_capacity: 1
#       max_capacity: 10
#       seconds_until_auto_pause: 300
#       # V1 only
#       auto_pause: true
#       timeout_action: ForceApplyCapacityChange
#   managed_password: true | false # If true, the password will be managed by AWS Secrets Manager, defaults to false
#   managed_password_rotation: true | false # If true, the password will be rotated automatically by AWS Secrets Manager, defaults to false
#   password_secret_kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" # KMS key for the password secret or Alias
#   rotation_lambda_name: "rds-rotation-lambda" # Name of the lambda function to rotate the password, required if managed_password_rotation is false
#   password_rotation_period: 90 # Rotation period in days for the password, defaults to 90days
#   rotation_duration: "1h" # Duration of the lambda function to rotate the password, defaults to 1h
#   iam:
#     database_authentication_enabled: true | false # defaults to true
#     authentication_roles: # List of IAM roles to attach to the cluster, optional
#       - "arn:aws:iam::123456789012:role/role-name"
#   cloudwatch:
#     log_exports:
#       - error
#       - audit
#       - general
#       - iam-db-auth-error
#       - instance
#       - postgresql # (PostgreSQL)
#       - slowquery
#   #create_db_option
#   migration: (optional) Migration from RDS Database
#     enabled: true | false
#     promote: true | false
#     source_rds_instance: "RDS Instance Identifier"
#   hoop:
#     enabled: true | false
#     agent: hoop-agent-name
#     tags: ["tag1", "tag2"]
#   events:
#     enabled: true | false
#     sns_topic_arn: "arn:aws:sns:us-east-1:123456789012:my-sns-topic"
#     sns_topic_name: "my-sns-topic" # Required if sns_topic_arn is not provided
#     categories: ["availability", "deletion", "failover", "failure", "low storage", "maintenance", "notification", "read replica", "recovery", "restore", "security", "storage"]
#     instances: true | false # If true, the event subscription will be created for instances.
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

variable "run_hoop" {
  description = "Run hoop with agent, be careful with this option, it will run the HOOP command in output in a null_resource"
  type        = bool
  default     = false
}