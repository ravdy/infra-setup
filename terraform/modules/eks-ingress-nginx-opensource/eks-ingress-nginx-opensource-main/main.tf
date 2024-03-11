data "aws_caller_identity" "current" {}
locals { account_id = data.aws_caller_identity.current.account_id }
data "aws_region" "current" {}

resource "kubernetes_namespace" "ns_nginx" {
  metadata {
    name = "nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  depends_on = [kubernetes_namespace.ns_nginx]

  namespace  = "nginx"
  name       = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.helm_nginx_ingress_controller_version

  dynamic "set" {
    # The 'helm' provider did not implement the 'iterator' argument, local.x, or var.x in dynamic
    # blocks, so we can't make this a variable {} declaration with defaults. If they ever do
    # implement it, we can make this more configurable.
    # https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
    for_each = {
      # SSL Policy and Settings
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert" = var.ssl_cert_wildcard_arn
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports" = "https"

      # Load Balancer Design Elements
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type" = "external"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type" = "instance"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme" = "internet-facing"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-proxy-protocol" = "*"
      "controller.config.use-proxy-protocol" = "true"
      "controller.enableAnnotationValidations" = "true"
      "controller.service.targetPorts.https" = "http"

      # Logging
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-access-log-enabled" = "true"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-access-log-emit-interval" = "5"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-access-log-s3-bucket-name" = "${local.logging_bucket}"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-access-log-s3-bucket-prefix" = "${local.logging_prefix}"
    }

    content {
      name = set.key
      value = set.value
    }
  }

}

# --------------- S3 Bucket Subscription ---------------
# Because this gets added well after the Datadog forwarding Lambda function and S3 bucket,
# and there is no absolute certainty in the world...

data "aws_lambda_function" "forwarder" {
  function_name = "datadog-forwarder"
}

resource "aws_s3_bucket_notification" "forwarder" {
  bucket = local.logging_bucket
  lambda_function {
    lambda_function_arn = data.aws_lambda_function.forwarder.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.logging_prefix}"
  }
}

resource "helm_release" "internal_ingress_nginx" {
  depends_on = [kubernetes_namespace.ns_nginx]

  namespace  = "nginx"
  name       = "internal-ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.helm_nginx_ingress_controller_version

  dynamic "set" {
    # The 'helm' provider did not implement the 'iterator' argument, local.x, or var.x in dynamic
    # blocks, so we can't make this a variable {} declaration with defaults. If they ever do
    # implement it, we can make this more configurable.
    # https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
    for_each = {
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type" = "external"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type" = "instance"

      # Technically deprecated in `aws-load-balancer-controller`
      # but seems to be the needed one for now in ingress-nginx
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal" = "true"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme" = "internal"
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-proxy-protocol" = "*"
      "controller.config.use-proxy-protocol" = "true"
      "controller.ingressClassResource.name" = "internal-nginx"
      "controller.ingressClassResource.controllerValue" = "k8s.io/internal-ingress-nginx"
      "controller.service.targetPorts.https" = "http"
    }

    content {
      name = set.key
      value = set.value
    }
  }

}

data "kubernetes_service" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "nginx"
  }
  depends_on = [
    helm_release.ingress_nginx,
  ]
}


data "kubernetes_service" "ingress_nginx_controller_internal" {
  metadata {
    name      = "internal-ingress-nginx-controller"
    namespace = "nginx"
  }
  depends_on = [
    helm_release.internal_ingress_nginx,
  ]
}

resource "aws_route53_record" "public_lb" {
  name    = "${var.segment}-lb"
  type    = "CNAME"
  ttl     = 300
  zone_id = var.aws_route53_zone_public_id
  records = [data.kubernetes_service.ingress_nginx_controller.status.0.load_balancer.0.ingress.0.hostname]
}

resource "aws_route53_record" "wildcard_internal" {
  name    = "*"
  type    = "CNAME"
  ttl     = 300
  zone_id = var.aws_route53_zone_internal_id
  records = [data.kubernetes_service.ingress_nginx_controller_internal.status.0.load_balancer.0.ingress.0.hostname]
}
