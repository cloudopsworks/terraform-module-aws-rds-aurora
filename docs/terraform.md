## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.24.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.9 |

## Resources

| Name | Type |
|------|------|
| [aws_db_event_subscription.events_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_event_subscription) | resource |
| [aws_db_event_subscription.events_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_event_subscription) | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_global_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster) | resource |
| [aws_secretsmanager_secret.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_rotation.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.this_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [null_resource.hoop_connection_mysql](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.hoop_connection_mysql_managed](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.hoop_connection_postgres](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.hoop_connection_postgres_managed](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.randompass](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.final_snapshot](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_rotating.randompass](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_db_cluster_snapshot.recovery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_cluster_snapshot) | data source |
| [aws_iam_policy_document.rds_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_kms_key.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_lambda_function.rotation_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.rds_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_security_group.allow_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_sns_topic.events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Establish this is a HUB or spoke configuration | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | n/a | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_run_hoop"></a> [run\_hoop](#input\_run\_hoop) | Run hoop with agent, be careful with this option, it will run the HOOP command in output in a null\_resource | `bool` | `false` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security groups for RDS instance | `any` | `{}` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | Settings for RDS instance | `any` | `{}` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | n/a | `string` | `"001"` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | VPC for RDS instance | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_kms_key_alias"></a> [cluster\_kms\_key\_alias](#output\_cluster\_kms\_key\_alias) | n/a |
| <a name="output_cluster_kms_key_arn"></a> [cluster\_kms\_key\_arn](#output\_cluster\_kms\_key\_arn) | n/a |
| <a name="output_cluster_kms_key_id"></a> [cluster\_kms\_key\_id](#output\_cluster\_kms\_key\_id) | n/a |
| <a name="output_cluster_secrets_credentials"></a> [cluster\_secrets\_credentials](#output\_cluster\_secrets\_credentials) | n/a |
| <a name="output_cluster_secrets_credentials_arn"></a> [cluster\_secrets\_credentials\_arn](#output\_cluster\_secrets\_credentials\_arn) | n/a |
| <a name="output_hoop_connection_mysql"></a> [hoop\_connection\_mysql](#output\_hoop\_connection\_mysql) | n/a |
| <a name="output_hoop_connection_mysql_managed"></a> [hoop\_connection\_mysql\_managed](#output\_hoop\_connection\_mysql\_managed) | n/a |
| <a name="output_hoop_connection_postgres"></a> [hoop\_connection\_postgres](#output\_hoop\_connection\_postgres) | n/a |
| <a name="output_hoop_connection_postgres_managed"></a> [hoop\_connection\_postgres\_managed](#output\_hoop\_connection\_postgres\_managed) | n/a |
| <a name="output_rds_cluster_arn"></a> [rds\_cluster\_arn](#output\_rds\_cluster\_arn) | n/a |
| <a name="output_rds_cluster_endpoint"></a> [rds\_cluster\_endpoint](#output\_rds\_cluster\_endpoint) | n/a |
| <a name="output_rds_cluster_hosted_zone_id"></a> [rds\_cluster\_hosted\_zone\_id](#output\_rds\_cluster\_hosted\_zone\_id) | n/a |
| <a name="output_rds_cluster_instance_endpoints"></a> [rds\_cluster\_instance\_endpoints](#output\_rds\_cluster\_instance\_endpoints) | n/a |
| <a name="output_rds_cluster_instance_ids"></a> [rds\_cluster\_instance\_ids](#output\_rds\_cluster\_instance\_ids) | n/a |
| <a name="output_rds_cluster_master_username"></a> [rds\_cluster\_master\_username](#output\_rds\_cluster\_master\_username) | n/a |
| <a name="output_rds_cluster_port"></a> [rds\_cluster\_port](#output\_rds\_cluster\_port) | n/a |
| <a name="output_rds_cluster_reader_endpoint"></a> [rds\_cluster\_reader\_endpoint](#output\_rds\_cluster\_reader\_endpoint) | n/a |
| <a name="output_rds_global_cluster_id"></a> [rds\_global\_cluster\_id](#output\_rds\_global\_cluster\_id) | n/a |
| <a name="output_rds_security_group_ids"></a> [rds\_security\_group\_ids](#output\_rds\_security\_group\_ids) | n/a |
