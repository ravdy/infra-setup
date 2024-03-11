resource "aws_acm_certificate" "vpn_server" {
  domain_name       = "vpn.${var.environment}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "vpn_cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.vpn_server.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.vpn_server.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.vpn_server.domain_validation_options)[0].resource_record_type
  zone_id         = var.public_route53_zone_id
  ttl             = 60
}


resource "aws_acm_certificate_validation" "vpn_server" {
  certificate_arn         = aws_acm_certificate.vpn_server.arn
  validation_record_fqdns = [aws_route53_record.vpn_cert_validation.fqdn]
}


resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Client VPN example"
  client_cidr_block      = "${var.client_vpn_cidr_start}.4.0/22"
  split_tunnel           = true
  server_certificate_arn = aws_acm_certificate_validation.vpn_server.certificate_arn

  dns_servers = [
    aws_route53_resolver_endpoint.vpn_dns.ip_address.*.ip[0],
    aws_route53_resolver_endpoint.vpn_dns.ip_address.*.ip[1]
  ]

  authentication_options {
    type              = "federated-authentication"
    saml_provider_arn = var.vpn_client_saml_provider_arn
  }

  connection_log_options {
    enabled = false
  }

}

resource "aws_security_group" "vpn_access" {
  vpc_id = data.aws_vpc.edbence.id
  name   = "vpn-sg"

  ingress {
    from_port   = 443
    protocol    = "UDP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming VPN connection"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_ec2_client_vpn_network_association" "vpn_subnet_1_assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnets[0]
  security_groups        = [aws_security_group.vpn_access.id]

  //  lifecycle {
  //    // The issue why we are ignoring changes is that on every change
  //    // terraform screws up most of the vpn associations
  //    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
  //    ignore_changes = [subnet_id]
  //  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnet_2_assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnets[0]
  security_groups        = [aws_security_group.vpn_access.id]

  //  lifecycle {
  //    // The issue why we are ignoring changes is that on every change
  //    // terraform screws up most of the vpn associations
  //    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
  //    ignore_changes = [subnet_id]
  //  }
}

resource "aws_ec2_client_vpn_authorization_rule" "authorize_all_vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = data.aws_vpc.edbence.cidr_block
  authorize_all_groups   = true
  description            = "Authorize all VPC access"
}

resource "aws_route53_resolver_endpoint" "vpn_dns" {
  name               = "vpn-dns-access"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.vpn_dns_sg.id]
  ip_address {
    subnet_id = module.vpc.private_subnets[0]
  }
  ip_address {
    subnet_id = module.vpc.private_subnets[1]
  }
}

resource "aws_security_group" "vpn_dns_sg" {
  name   = "vpn_dns"
  vpc_id = data.aws_vpc.edbence.id
  ingress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [aws_security_group.vpn_access.id]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_inbound_vpn_to_k8s_cluster" {
  source_security_group_id = aws_security_group.vpn_access.id
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  description              = "VPN Access"
}

resource "aws_security_group_rule" "allow_outbound_vpn_to_k8s_cluster" {
  source_security_group_id = aws_security_group.vpn_access.id
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  description              = "VPN Access"
}
