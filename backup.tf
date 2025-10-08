##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  backup_tags = try(var.settings.backup.enabled, false) && try(var.settings.backup.only_tag, true) ? {
    "aws-backup"          = "true"                                     # Tag to identify resources for AWS Backup
    "aws-backup-schedule" = try(var.settings.backup.schedule, "daily") # Tag to identify the backup plan
  } : {}
}