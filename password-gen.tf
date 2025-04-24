##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

resource "random_password" "randompass" {
  count            = try(var.settings.managed_password, false) ? 0 : 1
  length           = 20
  special          = false
  override_special = "=_-"
  min_upper        = 2
  min_special      = 1
  min_numeric      = 2
  min_lower        = 1

  lifecycle {
    replace_triggered_by = [
      time_rotating.randompass[0].rotation_rfc3339
    ]
  }
}

resource "time_rotating" "randompass" {
  count         = try(var.settings.managed_password, false) ? 0 : 1
  rotation_days = try(var.settings.password_rotation_period, 90)
}
