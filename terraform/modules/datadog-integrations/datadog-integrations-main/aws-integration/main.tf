data "aws_caller_identity" "current" {}
locals { account = data.aws_caller_identity.current.account_id }

resource "datadog_integration_aws" "main" {
  count = var.integration_id == "" ? 1 : 0  # only create if no ID provided

  account_id  = local.account
  role_name   = var.role

  host_tags = [ "env:${var.environment}" ]
}

locals {
  integration_id = var.integration_id == "" ? datadog_integration_aws.main[0].external_id : var.integration_id
}

resource "aws_iam_role" "datadog_integration" {
  name = var.role
  description = "Role for Datadog AWS Integration"

  assume_role_policy = templatefile(
    "${path.module}/policies/datadog-assume-role.json",
    { integration_external_id = local.integration_id }
  )
}

resource "aws_iam_policy" "datadog_integration" {
  name = var.policy
  policy = file("${path.module}/policies/datadog-privileges.json")
}

resource "aws_iam_role_policy_attachment" "datadog_integration" {
  role = aws_iam_role.datadog_integration.name
  policy_arn = aws_iam_policy.datadog_integration.arn
}
