locals {
  # preprod was set up with _only_ a wildcard certificate. We'll want to fix that later,
  # but for now we're just keeping the environment as-is for testing.
  acm_san = (
    var.environment == "preprod"
    ?
    [ "*.${var.environment}.env.edbence.com", ]
    :
    [ "*.${var.environment}.env.edbence.com", "${var.environment}.env.edbence.com" ]
    )
}

resource "aws_acm_certificate" "main" {
  domain_name = "*.${var.environment}.env.edbence.com"
  subject_alternative_names = local.acm_san

  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
}


data "aws_route53_zone" "main" {
  name = "${var.environment}.env.edbence.com."
  private_zone = false
}


resource "aws_route53_record" "main" {
  for_each = {
    for rec in aws_acm_certificate.main.domain_validation_options : rec.domain_name => {
      name = rec.resource_record_name
      record = rec.resource_record_value
      type = rec.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [ each.value.record ]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.main.zone_id
}


# We want this Terraform module to complete only when the certificates are validated
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}
