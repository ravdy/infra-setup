output "integration_external_id" {
  value = var.integration_id == "" ? datadog_integration_aws.main[0].external_id : var.integration_id
}
