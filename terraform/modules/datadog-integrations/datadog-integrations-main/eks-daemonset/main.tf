data "aws_eks_cluster" "cluster" { name = var.cluster }


# --------------- Making Secrets Available to Kubernetes ---------------
resource "kubernetes_secret" "datadog" {
  metadata {
    name = "datadog-keys"
    namespace = "kube-system"
  }

  data = {
    "api-key" = var.api_key
    "app-key" = var.app_key
  }

  type = "Opaque"
}


# --------------- Managing EKS Datadog via Official Helm Chart ---------------
resource "helm_release" "datadog" {
  depends_on = [ kubernetes_secret.datadog ]

  namespace = "kube-system"
  name = "datadog"

  repository = "https://helm.datadoghq.com"
  chart = "datadog"
  version = var.datadog_helm_chart_version

  values = ["'datadog': {'tags': ['env:${var.environment}', 'segment:${var.segment}']}"]

  dynamic "set" {
    # The 'helm' provider did not implement the 'iterator' argument, local.x, or var.x in dynamic
    # blocks, so we can't make this a variable {} declaration with defaults. If they ever do
    # implement it, we can make this more configurable.
    # https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
    for_each = {
      "registry" = "public.ecr.aws/datadog"

      # Access to Datadog
      "datadog.apiKeyExistingSecret" = "datadog-keys"
      "datadog.appKeyExistingSecret" = "datadog-keys"

      # Tags for Datadog identification
      "datadog.clusterName" = data.aws_eks_cluster.cluster.name
      "datadog.nodeLabelsAsTags.node\\.kubernetes\\.io/instance-type" = "aws-instance-type"
      "datadog.nodeLabelsAsTags.topology\\.kubernetes\\.io/region" = "region"
      "datadog.nodeLabelsAsTags.topology\\.kubernetes\\.io/zone" = "availability_zone"

      # --- What Do We Send? ---
      # Basic logging of all sorts
      "datadog.logLevel" = "INFO"  # this is the default
      "datadog.logs.enabled" = true
      "datadog.logs.containerCollectAll" = true
      "datadog.processAgent.processCollection" = true
      "datadog.kubeStateMetricsCore.enabled" = true  # default
      "datadog.kubeStateMetricsEnabled" = false  # default

      # Shared Process Namespace
      # https://docs.datadoghq.com/agent/autodiscovery/clusterchecks
      # https://docs.datadoghq.com/agent/kubernetes/cluster/
      "datadog.clusterChecks.shareProcessNamespace" = true
      "datadog.clusterAgent.shareProcessNamespace" = true
      "agents.shareProcessnamespace" = true

      # DogStatsD: https://docs.datadoghq.com/developers/dogstatsd/?tab=hostagent
      "datadog.dogstatsd.useSocketVolume" = false
      "datadog.dogstatsd.useHostPort" = true

      # APM is enabled by default, but needs to be told to use a port
      "datadog.apm.portEnabled" = true

      # Prometheus: https://docs.datadoghq.com/agent/kubernetes/prometheus/
      "datadog.prometheusScrape.enabled" = true
      "datadog.prometheusScrape.serviceEndpoints" = true

      # Helm Checks
      "datadog.helmCheck.enabled" = true
      "datadog.helmCheck.collectEvents" = true
    }

    content {
      name = set.key
      value = set.value
    }
  }
}
