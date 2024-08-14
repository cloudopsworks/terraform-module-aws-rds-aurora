##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "settings" {
  description = "Settings for RDS instance"
  type        = any
  default     = {}
}

variable "vpc" {
  description = "VPC for RDS instance"
  type        = any
  default     = {}
}

variable "security_groups" {
  description = "Security groups for RDS instance"
  type        = any
  default     = {}
}