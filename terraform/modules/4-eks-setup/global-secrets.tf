data "aws_secretsmanager_secret" "docker_auth_file_secret" {
  name = var.docker_auth_file_secret
}

data "aws_secretsmanager_secret_version" "docker_auth_file" {
  secret_id = data.aws_secretsmanager_secret.docker_auth_file_secret.id
}


resource "kubernetes_secret" "artifactory_credentials" {
  metadata {
    name = "artifactory-credentials"
  }

  data = {
    ".dockerconfigjson" = data.aws_secretsmanager_secret_version.docker_auth_file.secret_string
  }

  type = "kubernetes.io/dockerconfigjson"
}
