output "arn" {
  value = data.aws_secretsmanager_secret.datadog.arn
}

output "api_key" {
  value = local.secret.api_key
}

output "app_key" {
  value = local.secret.app_key
}

output "integration_id" {
  value = local.secret.aws_integration_external_id
}
