##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "random_password" "randompass" {
  count = local.generate_password ? 1 : 0
  keepers = {
    rotation_rfc3339 = time_rotating.randompass[0].rotation_rfc3339
  }
  length           = 20
  special          = false
  override_special = "=_-@"
  min_upper        = 2
  min_special      = 1
  min_numeric      = 2
  min_lower        = 1
}

resource "time_rotating" "randompass" {
  count         = local.generate_password ? 1 : 0
  rotation_days = try(var.settings.password_rotation_period, 90)
}
