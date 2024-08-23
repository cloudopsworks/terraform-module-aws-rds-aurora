##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  create_sg = try(var.security_groups.create, false)
  security_group_ids = concat(
    aws_security_group.this[*].id,
    data.aws_security_group.this[*].id
  )
  allow_security_groups_names = {
    for sg in try(var.security_groups.allow_security_groups, []) : sg => sg
    if local.create_sg
  }
  allow_security_groups = {
    for k, v in local.allow_security_groups_names : k => data.aws_security_group.allow_sg[k].id
  }
}

resource "aws_security_group" "this" {
  count       = local.create_sg ? 1 : 0
  name        = "rds-${var.settings.name_prefix}-${local.system_name}-sg"
  description = "Security group for RDS instance - ${var.settings.name_prefix}-${local.system_name}"
  vpc_id      = var.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.all_tags, tomap({
      Name = "rds-${var.settings.name_prefix}-${local.system_name}-sg"
    })
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this_cidr" {
  for_each = {
    for cidr in try(var.security_groups.allow_cidrs, []) : cidr => cidr
    if local.create_sg
  }
  from_port         = local.rds_port
  to_port           = local.rds_port
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  tags              = local.all_tags
}


data "aws_security_group" "allow_sg" {
  for_each = local.allow_security_groups_names
  name     = each.value
}

resource "aws_vpc_security_group_ingress_rule" "this_sg" {
  for_each                     = local.allow_security_groups
  from_port                    = local.rds_port
  to_port                      = local.rds_port
  ip_protocol                  = "TCP"
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  tags                         = local.all_tags
}

data "aws_security_group" "this" {
  count = !local.create_sg ? 1 : 0
  name  = var.security_groups.name
}