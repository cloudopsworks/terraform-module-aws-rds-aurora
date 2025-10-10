##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  default_cluster_categories  = ["failover", "failure", "maintenance"]
  default_instance_categories = ["availability", "failover", "failure", "maintenance", "low storage"]
}

data "aws_sns_topic" "events" {
  count = try(var.settings.events.sns_topic_arn, "") != "" && try(var.settings.events.enabled, false) ? 1 : 0
  name  = var.settings.events.sns_topic_name
}

resource "aws_db_event_subscription" "events_cluster" {
  count            = try(var.settings.events.enabled, false) ? 1 : 0
  name             = "${local.cluster_identifier}-c-events"
  sns_topic        = try(var.settings.events.sns_topic_arn, "") != "" ? var.settings.events.sns_topic_arn : data.aws_sns_topic.events[0].arn
  source_type      = "db-cluster"
  source_ids       = [aws_rds_cluster.this.id]
  event_categories = try(var.settings.events.categories, local.default_cluster_categories)
}

resource "aws_db_event_subscription" "events_instances" {
  count            = try(var.settings.events.enabled, false) && try(var.settings.events.instances, false) ? 1 : 0
  name             = "${local.cluster_identifier}-i-events"
  sns_topic        = try(var.settings.events.sns_topic_arn, "") != "" ? var.settings.events.sns_topic_arn : data.aws_sns_topic.events[0].arn
  source_type      = "db-instance"
  source_ids       = aws_rds_cluster_instance.this[*].identifier
  event_categories = try(var.settings.events.categories, local.default_instance_categories)
}
