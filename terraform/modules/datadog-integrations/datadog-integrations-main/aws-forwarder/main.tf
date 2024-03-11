# --------------- Datadog Forwarder for non-EKS ---------------
# https://docs.datadoghq.com/logs/guide/forwarder/
# This builds a fair amount of infrastructure (including a Lambda function whose source can be seen
# here: https://github.com/DataDog/datadog-serverless-functions/releases ).
# Because Datadog uses CloudFormation, we're wrapping it in Terraform... which makes getting a list
# of the necessary outputs require data sources.
resource "aws_cloudformation_stack" "forwarder" {
  name = "datadog-forwarder"
  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/forwarder/latest.yaml"

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]
  parameters = {
    DdApiKeySecretArn = aws_secretsmanager_secret.api_key.arn
    DdSite = "datadoghq.com"
    FunctionName = "datadog-forwarder"

    DdTags = "env:${var.environment},segment:${var.segment}"
  }
}

# --------------- CloudWatch Subscription ---------------
data "aws_lambda_function" "forwarder" {
  depends_on = [ aws_cloudformation_stack.forwarder ]

  function_name = "datadog-forwarder"
}

data "aws_cloudwatch_log_group" "cluster" {
  name = "/aws/eks/${var.cluster}/cluster"
}

resource "aws_cloudwatch_log_subscription_filter" "forwarder" {
  name = "k8s-${var.cluster}"
  log_group_name = data.aws_cloudwatch_log_group.cluster.name
  filter_pattern = ""
  destination_arn = data.aws_lambda_function.forwarder.arn
}

# --------------- Datadog Secrets ---------------
# This module requires a singular Secret ARN with text, rather than a dictionary, so we create a
# copy here.
resource "aws_secretsmanager_secret" "api_key" {
  name = "${var.cluster}/managed-by-terraform/datadog/api_key"
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key
}
