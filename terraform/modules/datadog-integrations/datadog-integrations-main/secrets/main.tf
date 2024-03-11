# --------------- Datadog Secrets ---------------
data "aws_secretsmanager_secret" "datadog" {
  name = "${var.environment}/infra/datadog"
}

data "aws_secretsmanager_secret_version" "datadog" {
  secret_id = data.aws_secretsmanager_secret.datadog.id
}

locals {
  secret = jsondecode(data.aws_secretsmanager_secret_version.datadog.secret_string)
}
