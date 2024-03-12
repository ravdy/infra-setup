resource "aws_route53_zone" "internal" {
  name          = "${var.environment}-${var.segment}.${var.domain_suffix_internal}"
  comment       = "Managed by Terraform"
  force_destroy = false


  lifecycle {
    // Allow downstream (xmarkets) projects to add VPC associations outside of this project
    ignore_changes = [vpc]
  }

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}


#resource "aws_secretsmanager_secret" "route53_internal" {
#  name = "infra/${var.environment}/${var.segment}/route53_internal/id"
#  value = aws_route53_zone.internal.id
#  replica {
#    region = var.secret_replica_region
#  }
#}

