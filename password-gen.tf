##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

resource "random_password" "randompass" {
  length           = 20
  special          = false
  override_special = "=_-+"
  min_upper        = 2
  min_special      = 1
  min_numeric      = 2
  min_lower        = 1

  lifecycle {
    replace_triggered_by = [
      time_rotating.randompass.rotation_rfc3339
    ]
  }
}

resource "time_rotating" "randompass" {
  rotation_days = try(var.settings.password_rotation_period, 90)
}

# Secrets saving
resource "aws_secretsmanager_secret" "randompass" {
  name = "${local.secret_store_path}/admin/password"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "randompass" {
  secret_id     = aws_secretsmanager_secret.randompass.id
  secret_string = random_password.randompass.result
}
