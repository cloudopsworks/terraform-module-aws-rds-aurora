locals {
  local_vars  = yamldecode(file("./inputs.yaml"))
  spoke_vars  = yamldecode(file(find_in_parent_folders("spoke-inputs.yaml")))
  region_vars = yamldecode(file(find_in_parent_folders("region-inputs.yaml")))
  env_vars    = yamldecode(file(find_in_parent_folders("env-inputs.yaml")))
  global_vars = yamldecode(file(find_in_parent_folders("global-inputs.yaml")))

  local_tags  = jsondecode(file("./local-tags.json"))
  spoke_tags  = jsondecode(file(find_in_parent_folders("spoke-tags.json")))
  region_tags = jsondecode(file(find_in_parent_folders("region-tags.json")))
  env_tags    = jsondecode(file(find_in_parent_folders("env-tags.json")))
  global_tags = jsondecode(file(find_in_parent_folders("global-tags.json")))

  tags = merge(
    local.global_tags,
    local.env_tags,
    local.region_tags,
    local.spoke_tags,
    local.local_tags
  )
}

include "root" {
  path = find_in_parent_folders("{{ .RootFileName }}")
}
{{ if .vpc_enabled }}
dependency "vpc" {
  config_path = "{{ .vpc_path }}"
  #skip_outputs = true
  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["validate", "destroy"]
  mock_outputs = {
    database_security_group_id = "sg-abcdef1234567"
    database_subnet_group      = "vpc-network-hub-aaaa-000-usea1"
    database_subnet_group_name = "database_subnet_group_name"
    database_subnets = [
      "subnet-abcdef123456789",
      "subnet-abcdef123456781",
      "subnet-abcdef123456782",
    ]
    private_subnets = [
      "subnet-01234567890123456",
      "subnet-01234567890123457",
      "subnet-01234567890123458",
    ]
    public_subnets = [
      "subnet-01234567890123456",
      "subnet-01234567890123457",
    ]
    vpc_id = "vpc-12345678901234"
  }
}
{{ end }}
terraform {
  source = "{{ .sourceUrl }}"
}

inputs = {
  is_hub     = {{ .is_hub }}
  org        = local.env_vars.org
  spoke_def  = local.spoke_vars.spoke
  {{- range .requiredVariables }}
  {{- if ne .Name "org" }}
  {{ .Name }} = local.local_vars.{{ .Name }}
  {{- end }}
  {{- end }}
  {{- range .optionalVariables }}
  {{- if not (eq .Name "extra_tags" "is_hub" "spoke_def" "org") }}
  {{- if and $.vpc_enabled (eq .Name "vpc")}}
  vpc = {
    vpc_id       = dependency.vpc.outputs.vpc_id
    subnet_ids   = dependency.vpc.outputs.{{ $.subnet_type }}_subnets
    subnet_group = dependency.vpc.outputs.{{ $.subnet_type }}_subnet_group_name
  }
  {{- else }}
  {{ .Name }} = try(local.local_vars.{{ .Name }}, {{ .DefaultValue }})
  {{- end }}
  {{- end }}
  {{- end }}
  extra_tags = local.tags
}