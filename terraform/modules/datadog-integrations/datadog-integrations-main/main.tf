terraform {
  backend "s3" {
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}

data "aws_caller_identity" "current" {}
locals { account = data.aws_caller_identity.current.account_id }

# --------------- Datadog External Integration ---------------
module "integration" {
  source = "./aws-integration"

  account = local.account
  environment = var.environment
  role = var.integration_role
}


# --------------- Datadog Secrets ---------------
module "secrets" {
  source = "./secrets"

  environment = var.environment
}

# At least one module requires a singular Secret ARN with text, rather than a dictionary, so we
# create a copy here.
resource "aws_secretsmanager_secret" "datadog_api_key" {
  depends_on = [ module.secrets ]
  name = "${var.environment}/managed-by-terraform/datadog/api_key"
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = module.secrets.api_key
}


# --------------- Datadog in EKS ---------------
module "eks_daemonset" {
  depends_on = [ module.secrets ]
  for_each = toset(var.segments)
  source = "./eks-daemonset"

  cluster = "${var.environment}-${each.value}"
  api_key = module.secrets.api_key
  app_key = module.secrets.app_key
}


# --------------- Datadog AWS Forwarder ---------------
module "aws_forwarder" {
  depends_on = [
    module.secrets,
    module.logs_archive
  ]
  for_each = toset(var.segments)
  source = "./aws-forwarder"

  cluster = "${var.environment}-${each.value}"
  api_key = module.secrets.api_key
}


# --------------- Datadog Logs Archival ---------------
module "logs_archive" {
  for_each = toset(var.segments)
  source = "./logs-archive"

  account = local.account
  environment = var.environment
  segment = each.value
  cluster = "${var.environment}-${each.value}"
  role = var.integration_role
  log_retention_years = var.log_retention_years
}


# --------------- Datadog Monitors ---------------
module "monitors" {
  count = var.create_monitors ? 1 : 0
  source = "./monitors"

  environment = var.environment
  notification_channel = var.notification_channel
}
