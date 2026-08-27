##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

terraform {
  # 1.11.1 is required by the write-only master_password_wo arguments
  required_version = ">= 1.11.1"
  # Complete with required providers for the module
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
