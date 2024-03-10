data "aws_secretsmanager_secret" "datadog" {
  name = "${var.environment}/infra/datadog"
}

data "aws_secretsmanager_secret_version" "datadog" {
  secret_id = data.aws_secretsmanager_secret.datadog.id
}

data "aws_secretsmanager_secret" "core" {
  name = "${var.environment}/infra/core"
}

data "aws_secretsmanager_secret_version" "core" {
  secret_id = data.aws_secretsmanager_secret.core.id
}


data "aws_secretsmanager_secret" "segment_core" {
  name = "${var.environment}/${var.segment}/core"
}

data "aws_secretsmanager_secret_version" "segment_core" {
  secret_id = data.aws_secretsmanager_secret.segment_core.id
}
