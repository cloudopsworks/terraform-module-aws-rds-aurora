##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

##  YAML Input Format (with inline documentation)
# settings:                                      # (Required) Root map for Aurora configuration
#   # Recovery
#   recovery:                                    # (Optional) Restore cluster from snapshot or another cluster; conflicts with creating a fresh cluster
#                                                #            Mutually exclusive with clone and s3_import
#     enabled: true | false                      # (Optional) Enable recovery mode; default: false
#     cluster_identifier: "rds-cluster-name"     # (Optional) Source cluster identifier when recovering from another cluster
#     snapshot_identifier: "cluster-snap-name"   # (Optional) Specific cluster snapshot identifier to restore from
#   # Clone / Point in time restore
#   clone:                                       # (Optional) Build the cluster by restoring an existing one to a point in time, mapped to the
#                                                #            aws_rds_cluster restore_to_point_in_time block. Mutually exclusive with recovery and
#                                                #            s3_import: the provider rejects the plan when more than one of the three is enabled
#     enabled: true | false                      # (Optional) Enable the point in time restore; default: false
#     source_cluster_identifier: "src-cluster"   # (Optional) Identifier of the source cluster, or its full ARN to clone from another account.
#                                                #            Either this or source_cluster_resource_id is required when enabled
#     source_cluster_resource_id: "cluster-ABCD" # (Optional) DbClusterResourceId of the source cluster; the only way to restore a cluster that
#                                                #            has already been deleted
#     restore_type: "copy-on-write"              # (Optional) One of: "copy-on-write" (clone sharing the source storage, same account and region
#                                                #            only) or "full-copy" (independent copy); default: "copy-on-write"
#     use_latest_restorable_time: true | false   # (Optional) Restore to the latest restorable time; default: unset. Conflicts with restore_to_time
#     restore_to_time: "2024-12-01T16:00:00Z"    # (Optional) UTC RFC3339 timestamp to restore to; default: unset. Conflicts with
#                                                #            use_latest_restorable_time
#                                                #            A point in time restore ignores database_name and master_username: AWS carries both over from
#                                                #            the source cluster, and both are force new. Set settings.database_name and
#                                                #            settings.master_username to the values the source cluster actually uses, otherwise every plan
#                                                #            after the first apply proposes replacing the restored cluster. The master password is not
#                                                #            carried over — the provider applies the module generated one right after the restore, so the
#                                                #            module managed secret stays accurate
#   # S3 import
#   s3_import:                                   # (Optional) Seed a new cluster from a database backup stored on S3, mapped to the aws_rds_cluster
#                                                #            s3_import block. Supported by aurora-mysql only, and mutually exclusive with recovery and clone
#     enabled: true | false                      # (Optional) Enable the S3 import; default: false
#     source_engine: "mysql"                     # (Required when enabled) Engine that produced the backup; AWS accepts "mysql" only
#     source_engine_version: "5.7.28"            # (Required when enabled) Full version of the engine that produced the backup
#     ingestion_role: "arn:aws:iam::...:role/x"  # (Required when enabled) ARN of the IAM role RDS assumes to read the backup from the bucket
#     bucket_name: "my-backup-bucket"            # (Required when enabled) Bucket holding the backup; must live in the cluster region
#     bucket_prefix: "backups/mydb"              # (Optional) Key prefix of the backup inside the bucket; default: null (bucket root)
#   # Cross region source
#   source_region: "us-east-1"                   # (Optional) Region the replication or restore source lives in; default: null. Required by AWS to
#                                                #            presign the cross region request when that source is encrypted and sits in another region, as
#                                                #            with a cross region migration or clone. Forces replacement when changed
#   # Global Cluster
#   global_cluster:                              # (Optional) Manage Aurora Global Database
#     create: true | false                       # (Optional) Create a new Global Cluster; default: false
#     id: "arn:aws:rds:...:global-cluster:mydb" # (Optional) Existing Global Cluster ARN/ID to join; conflicts with create=true
#   # Cluster general
#   name: "mydb-name"                            # (Optional) Explicit cluster identifier; if set, overrides name_prefix
#   name_prefix: "mydb"                          # (Required) When `name` not provided; used to build cluster/instances names
#   database_name: "mydb"                        # (Optional) Initial DB name; default: "cluster_db". Forced to null by the module when migration.enabled=true.
#                                                #            Set explicitly to null to skip the initial database, which also disables the module managed Secrets Manager entry
#                                                #            When clone.enabled=true it must be set to the database name the source cluster carries, see clone above
#   master_username: "admin"                     # (Optional) Master user name; default: "cluster_root". Forced to null by the module when migration.enabled=true
#                                                #            When clone.enabled=true it must be set to the master user the source cluster carries, see clone above
#   engine_type: "aurora-postgresql"            # (Required) One of: "aurora-postgresql", "aurora-mysql"
#   engine_version: "15.3"                       # (Required) Aurora engine version (e.g., Postgres 15.x, MySQL 8.0.x supported by AWS)
#   engine_mode: "provisioned" | "serverless"    # (Optional) Engine mode; for Serverless v2 this is kept as "provisioned" by AWS
#   auto_minor_upgrade: true | false              # (Optional) Auto minor version upgrade for instances; default: false
#   availability_zones: ["us-east-1a", "us-east-1b"] # (Required) List of AZs for cluster/instances
#   port: 5432                                    # (Optional) Cluster port; default: 5432. Use 3306 for aurora-mysql
#   apply_immediately: true | false               # (Optional) Apply changes immediately; default: true
#   insights_mode: "standard" | "advanced"        # (Optional) Database Insights mode; default: "standard"
#   publicly_accessible: true | false             # (Optional) Make instances public; default: false
#   encryption:                                   # (Optional) Cluster encryption settings; takes precedence over storage.encryption
#     enabled: true | false                       # (Optional) Enable at-rest encryption; default: false. Falls back to storage.encryption.enabled
#     kms_key_id: "1234abcd-..."                 # (Optional) Existing KMS key id. Falls back to storage.encryption.kms_key_id
#     kms_key_arn: "arn:aws:kms:...:key/..."     # (Optional) Existing KMS key ARN. Falls back to storage.encryption.kms_key_arn
#     kms_key_alias: "alias/my-key"              # (Optional) Existing KMS key alias, used only when no key id or ARN is set; the "alias/" prefix is added when missing.
#                                                #            Falls back to storage.encryption.kms_key_alias. When no key id, ARN or alias is set anywhere,
#                                                #            the module creates and manages its own KMS key, whose policy grants the account root, RDS through
#                                                #            kms:ViaService, and CloudWatch Logs for the /aws/rds/cluster/<identifier>/* log groups
#     deletion_window: 30                         # (Optional) Deletion window in days for the module managed key; default: 30. Alias: storage.encryption.deletion_window_in_days
#     rotation_enabled: true | false              # (Optional) Enable automatic rotation of the module managed key; default: true
#     rotation_period: 90                         # (Optional) Rotation period in days for the module managed key; default: 90. Alias: storage.encryption.rotation_period_in_days
#     multi_region: true | false                  # (Optional) Create the module managed key as multi-region; default: false
#   storage:                                      # (Optional) Storage configuration (iops/type for certain engines/modes only)
#     encryption:                                 # (Optional) Storage encryption settings. Superseded by the top level encryption block when both are set
#       enabled: true | false                     # (Optional) Enable at-rest encryption; default: false
#       kms_key_id: "1234abcd-..."               # (Optional) Use existing KMS key id
#       kms_key_arn: "arn:aws:kms:...:key/..."   # (Optional) Use existing KMS key ARN
#       kms_key_alias: "alias/aws/rds"           # (Optional) Use existing KMS key alias (with or without "alias/" prefix)
#       deletion_window_in_days: 30               # (Optional) If module creates KMS key; default: 30
#       rotation_period_in_days: 90               # (Optional) If module creates KMS key; default: 90
#       rotation_enabled: true | false            # (Optional) Enable automatic rotation of the module managed key; default: true
#       multi_region: true | false                # (Optional) Create the module managed key as multi-region; default: false
#     type: "" | "aurora-iopt1" | "io1" | "io2" # (Optional) Storage type; defaults to provider/account default; iops required for io1/io2
#     iops: 1000                                  # (Optional) Required when type is io1/io2
#   monitoring:
#     interval: 0                                 # (Optional) Enhanced monitoring interval seconds; one of: 0,1,5,10,15,30,60; default: 0 (disabled)
#   performance:                                  # (Optional) Performance Insights. Alias: performance_insights, which takes precedence when both are set
#     enabled: true | false                       # (Optional) Enable Performance Insights; default: false
#     retention_period: 7                         # (Optional) Retention in days; default: 7. Possible values: 7, 731 or any multiple of 31
#     encryption:                                 # (Optional) Encrypt Performance Insights
#       enabled: true | false                     # (Optional) Enable encryption for PI; default: false
#       kms_key_alias: "alias/pi-key"            # (Optional) Existing KMS alias, used only when no key id or ARN is set; the "alias/" prefix is added when missing.
#                                                #            When none is set the module creates and manages its own Performance Insights key
#       kms_key_id: "abcd-1234"                  # (Optional) Existing KMS key id
#       kms_key_arn: "arn:aws:kms:..."           # (Optional) Existing KMS key arn
#   performance_insights:                         # (Optional) Alias of the performance block, kept aligned with terraform-module-aws-rds-database.
#                                                #            Every key below takes precedence over its performance counterpart
#     enabled: true | false                       # (Optional) Enable Performance Insights; default: false
#     retention_period: 7                         # (Optional) Retention in days; default: 7
#     kms_key_id: "abcd-1234"                    # (Optional) Existing KMS key id for Performance Insights
#     kms_key_alias: "alias/pi-key"              # (Optional) Existing KMS key alias for Performance Insights; the "alias/" prefix is added when missing
#     kms_key_arn: "arn:aws:kms:..."             # (Optional) Existing KMS key ARN for Performance Insights
#     encryption:                                 # (Optional) Same shape as performance.encryption
#       enabled: true | false                     # (Optional) Enable encryption for PI; default: false
#   maintenance:
#     window: "sun:03:00-sun:04:00"               # (Optional) Preferred maintenance window; default: sun:03:00-sun:04:00
#   backup:
#     enabled: true | false                       # (Optional) Tag the cluster for an external AWS Backup plan; default: false
#     only_tag: true | false                      # (Optional) Only tag for AWS Backup, do not manage a plan; default: true.
#                                                 #            Applies only when backup.enabled is true
#     schedule: "daily"                           # (Optional) Value of the aws-backup-schedule tag; default: daily.
#                                                 #            Applies only when backup.enabled and backup.only_tag are true
#     retention_period: 7                         # (Optional) Snapshot retention days; default: 5
#     window: "01:00-02:30"                       # (Optional) Preferred backup window; default: 00:45-02:45
#     copy_tags: true | false                     # (Optional) Copy tags to snapshots; default: true
#   deletion_protection: true | false             # (Optional) Protect cluster from deletion; default: true
#   allow_upgrade: true | false                   # (Optional) Allow major version upgrade; default: true
#   # Instance specific
#   replicas:
#     count: 2                                    # (Optional) Number of instances; default: 1 (writer only)
#     replica_0:
#       availability_zone: "us-east-1a"           # (Optional) AZ override for this replica
#       promotion_tier: 10                         # (Optional) Lower number = higher failover priority (1-15)
#       maintenance_window: "wed:03:00-wed:04:00" # (Optional) Per-instance maintenance window
#     replica_1:
#       availability_zone: "us-east-1b"           # (Optional)
#       instance_size: "db.r5.xlarge"             # (Optional) Instance class override for this replica
#   instance_size: "db.r6g.large" | "db.serverless" # (Required) Instance class; use "db.serverless" for Serverless v1/v2
#   serverless:
#     enabled: true | false                        # (Optional) Enable Serverless mode; default: false
#     v2: true | false                             # (Optional) Use Serverless v2; default: false
#     scaling_configuration:
#       # for V2 and V1
#       min_capacity: 0.5                          # (Optional) Minimum ACU (v2) or capacity (v1)
#       max_capacity: 16.0                         # (Optional) Maximum ACU (v2) or capacity (v1)
#       seconds_until_auto_pause: 300              # (Optional) Auto pause after seconds (v1 and v2)
#       # V1 only
#       auto_pause: true | false                   # (Optional) v1 only
#       timeout_action: ForceApplyCapacityChange   # (Optional) v1 only; one of: ForceApplyCapacityChange | RollbackCapacityChange
#   managed_password: true | false                 # (Optional) Delegate the master password to AWS Secrets Manager; default: false. Ignored when migration.enabled=true.
#                                                  #            When false, the module generates the password and stores it on its own Secrets Manager secret,
#                                                  #            delivering it to the cluster through the write-only master_password_wo arguments so it never
#                                                  #            lands in state. No password is generated when migration.enabled or recovery.enabled is true,
#                                                  #            since the cluster then carries the credentials of its source instance or snapshot
#   managed_password_rotation: true | false        # (Optional) Enable rotation for the AWS managed secret; default: false. Only applies when managed_password is true
#   password_secret_kms_key_id: "arn:aws:kms:..." # (Optional) KMS key ID or alias for the password secret, applied whenever managed_password is true,
#                                                  #            and to the module managed secret otherwise; default: null (aws/secretsmanager)
#   password_secret_recovery_window: 30            # (Optional) Days Secrets Manager waits before deleting the module managed secret; default: null (AWS default of 30).
#                                                  #            One of 0 or 7 through 30; 0 deletes it immediately with no recovery. Consumed only by the
#                                                  #            DeleteSecret call at destroy time: neither CreateSecret nor UpdateSecret carries a recovery
#                                                  #            window, so changing it plans a state only diff and alters nothing on the live secret.
#                                                  #            Silently has no effect wherever the module managed secret is not created, which is whenever
#                                                  #            managed_password, migration.enabled or recovery.enabled is true, or database_name is null.
#                                                  #            The secret created for managed_password is owned by RDS through master_user_secret, and
#                                                  #            aws_rds_cluster exposes no recovery window for it
#   password_secret_import: true | false           # (Optional) Adopt an existing Secrets Manager secret of the same name instead of creating one; default: false.
#                                                  #            One-time switch, turn it off once the state holds the secret. The plan fails when no such secret
#                                                  #            exists, so it must stay false on a fresh deployment. Use it when a destroy left the secret inside
#                                                  #            its recovery window, which keeps the name taken and blocks re-creation. Only applies when
#                                                  #            managed_password is false
#   password_secret_replica:                       # (Optional) Cross region replicas of the module managed secret; default: none. Accepts a single object or a
#                                                  #            list of them. Only applies when managed_password is false
#     - region: "us-west-2"                       # (Required when replica defined) Region the secret is replicated to
#       kms_key_id: "arn:aws:kms:..."             # (Optional) KMS key of the replica region used to encrypt the replica; default: null (aws/secretsmanager).
#                                                  #            Must live in the replica region, password_secret_kms_key_id is never reused here
#   rotation_lambda_name: "rds-rotation-lambda"   # (Optional) Name of an existing Lambda used to rotate the module managed secret; only applies when managed_password is false
#   password_rotation_period: 90                   # (Optional) Rotation period in days; default: 90. Drives the Secrets Manager rotation when managed_password_rotation
#                                                  #            is true, and the regeneration cadence of the module generated password otherwise
#   rotation_duration: "1h"                        # (Optional) Rotation Lambda duration; default: 1h
#   iam:
#     database_authentication_enabled: true | false # (Optional) Enable IAM DB auth; default: true
#     authentication_roles:                        # (Optional) Attach IAM roles to cluster for auth
#       - "arn:aws:iam::123456789012:role/role-name"
#   cloudwatch:
#     retention_days: 90                           # (Optional) Log retention days; default: 90
#     retain: true | false                         # (Optional) Prevent log group destroy on delete; default: true
#     kms_key_id: "arn:aws:kms:..."               # (Optional) KMS key ID or ARN used to encrypt the log groups; default: null (AWS managed)
#     kms_key_alias: "alias/my-key"               # (Optional) KMS key alias used to encrypt the log groups, used only when kms_key_id is not set;
#                                                 #            the "alias/" prefix is added when missing. When neither is set, falls back to the module managed
#                                                 #            key only, never to an operator supplied encryption key, and to AWS default encryption when the
#                                                 #            module owns no key. A key the module does not own is not guaranteed to grant CloudWatch Logs,
#                                                 #            and an AWS managed key such as aws/rds grants none and cannot be edited
#     log_exports:                                 # (Optional) Enabled log exports; default: [postgresql] for PG, [audit,error] for MySQL
#       - error
#       - audit
#       - general
#       - iam-db-auth-error
#       - instance
#       - postgresql                               # (PostgreSQL)
#       - slowquery
#   # Parameter Group customization
#   cluster_parameter_group:                       # (Optional) Cluster-wide parameter group, applied to aws_rds_cluster
#     create: true | false                         # (Optional) Create a dedicated DB cluster parameter group; default: false
#     family: "aurora-postgresql15"               # (Optional) If not set, computed as engine_type+engine_version
#     parameters:
#       - name: "PARAM NAME"                      # (Required when parameters defined)
#         value: "PARAM VALUE"                    # (Required)
#         apply_method: "immediate" | "pending-reboot" # (Optional)
#   parameter_group:                               # (Optional) Instance parameter group, applied to every aws_rds_cluster_instance
#     create: true | false                         # (Optional) Create dedicated DB parameter group; default: false
#     family: "aurora-postgresql15"               # (Optional) If not set, computed as engine_type+engine_version
#     skip_destroy: true | false                   # (Optional) Keep parameter group on destroy; default: false
#     parameters:
#       - name: "PARAM NAME"                      # (Required when parameters defined)
#         value: "PARAM VALUE"                    # (Required)
#         apply_method: "immediate" | "pending-reboot" # (Optional)
#   migration:                                     # (Optional) Migrate from RDS instance (replication)
#     enabled: true | false                        # (Optional) Enable replication from source RDS; default: false. When true the cluster
#                                                  #            inherits the credentials of its source, so no master password is generated
#     source_rds_instance: "rds-instance-id"      # (Required when enabled) Source RDS instance identifier
#   hoop:                                          # (Optional) Generate Hoop connection outputs for terraform-module-hoop-connection
#     enabled: true | false                        # (Optional) Enable Hoop outputs; default: false
#     agent_id: "hoop-agent-uuid"                 # (Required when enabled) Hoop agent UUID
#     community: true | false                      # (Optional) Use community secret prefix (_aws:) vs enterprise (_envs/aws#); default: true
#     import: true | false                         # (Optional) Import existing Hoop connection; default: false
#     tags: {key: "value"}                         # (Optional) Tags map for Hoop connection
#     access_control: ["group1"]                   # (Optional) Access control groups for Hoop connection
#   events:                                        # (Optional) RDS Events subscriptions
#     enabled: true | false                        # (Optional) Enable event subscriptions; default: false
#     sns_topic_arn: "arn:aws:sns:...:my-topic"   # (Optional) Existing SNS topic ARN
#     sns_topic_name: "my-sns-topic"              # (Required if sns_topic_arn not provided) SNS topic name to look up
#     categories: ["availability", "deletion", "failover", "failure", "low storage", "maintenance", "notification", "read replica", "recovery", "restore", "security", "storage"] # (Optional)
#     instances: true | false                      # (Optional) Also subscribe DB instances; default: false
#   custom_endpoints:                              # (Optional) Additional cluster endpoints
#     - name: "custom-endpoint-1"                 # (Required) Endpoint name
#       type: "READER" | "WRITER" | "ANY"        # (Required) Endpoint type
#       static_members: ["rds-instance-1"]         # (Optional) Static members to include
#       excluded_members: ["rds-instance-3"]       # (Optional) Members to exclude
variable "settings" {
  description = "Settings for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# vpc:                                           # (Required) Networking settings for the cluster
#   vpc_id: "vpc-12345678901234"                # (Required) Target VPC id
#   subnet_group: "db-subnet-group-name"        # (Required) Existing DB subnet group name covering private subnets
#   subnet_ids:                                  # (Optional) Subnet ids (used only in some auxiliary lookups); prefer using subnet_group
#     - "subnet-abcdef123456789"
#     - "subnet-abcdef123456781"
#     - "subnet-abcdef123456782"
variable "vpc" {
  description = "VPC for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# security_groups:                               # (Required) Ingress configuration for database port
#   create: true | false                         # (Optional) If true, create SG; else use existing by name; default: false
#   name: "sg-rds"                               # (Required when create=false) Existing SG name to attach
#   group_ids:                                   # (Optional) Extra security group ids to allow ingress from
#     - "sg-0123456789abcdef0"
#   allow_cidrs:                                 # (Optional) CIDR blocks allowed to connect to port
#     - "1.2.3.4/32"
#     - "10.0.0.0/16"
#   allow_security_groups:                       # (Optional) Security group NAMES to allow ingress from (resolved in the same VPC)
#     - "sg-name-123456"
#     - "sg-name-abcdef"
variable "security_groups" {
  description = "Security groups for RDS instance"
  type        = any
  default     = {}
}

