
output "dd_api_key" {
  value = jsondecode( data.aws_secretsmanager_secret_version.datadog.secret_string )["api_key"]
}
output "dd_app_key" {
  value = jsondecode( data.aws_secretsmanager_secret_version.datadog.secret_string )["app_key"]
}
output "dd_aws_integration_external_id" {
  value = jsondecode( data.aws_secretsmanager_secret_version.datadog.secret_string )["aws_integration_external_id"]
}

output "aws_account_id" {
  value = jsondecode( data.aws_secretsmanager_secret_version.core.secret_string )["aws_account_id"]
}

output "public_domain_name" {
  value = jsondecode( data.aws_secretsmanager_secret_version.core.secret_string )["public_domain_name"]
}

output "public_route53_zone_id" {
  value = jsondecode( data.aws_secretsmanager_secret_version.core.secret_string )["public_route53_zone_id"]
}


output "segment_vpc_cidr_prefix" {
  value = jsondecode( data.aws_secretsmanager_secret_version.segment_core.secret_string )["vpc_cidr_prefix"]
}

output "segment_vpn_cidr_prefix" {
  value = jsondecode( data.aws_secretsmanager_secret_version.segment_core.secret_string )["vpn_cidr_prefix"]
}


