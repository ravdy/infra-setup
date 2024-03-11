data "local_file" "aws_lbc_policyfile" {
  filename = "${path.module}/files/iam-policy-aws-load-balancer-controller.txt"
}

resource "aws_iam_policy" "aws_lbc" {
  name   = "${var.environment}-${var.segment}-aws-lbc-policy"
  policy = data.local_file.aws_lbc_policyfile.content
}

resource "aws_iam_role" "aws_lbc" {
  name = "${var.environment}-${var.segment}-aws-lbc-role"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Effect = "Allow",
          Principal = {
            Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
          },
          Action = "sts:AssumeRoleWithWebIdentity",
          Condition = {
            "ForAnyValue:StringEquals" = {
              "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = [
                "system:serviceaccount:kube-system:aws-load-balancer-controller"
              ]
            }
          },
        }
      ],
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}

resource "helm_release" "aws_lbc" {
  namespace  = "kube-system"
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = var.helm_aws_load_balancer_controller_version

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lbc.arn
  }

  set {
    name  = "podLabels.tags\\.datadoghq\\.com/env"
    value = var.environment
  }

  set {
    name  = "podLabels.tags\\.datadoghq\\.com/service"
    value = local.aws_load_balancer_controller
  }

  set {
    name  = "defaultSSLPolicy"
    value = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  }
}

locals {
  aws_load_balancer_controller = "aws-load-balancer-controller"
}
