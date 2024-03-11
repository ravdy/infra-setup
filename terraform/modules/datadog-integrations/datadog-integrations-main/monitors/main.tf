locals {
  context = "in `${var.environment}`. ${var.notification_channel}"
  elb_controller = "aws-load-balancer-controller"  # should this be passed in?
  tags_env_only = [ "env:${var.environment}" ]
  tags_w_service = [
    "env:${var.environment}",
    "service:${local.elb_controller}"
  ]
}


resource "datadog_monitor" "high_cpu" {
  name = "CPU Load average on AWS LBC pod is above 70% for last 5 minutes"
  type = "metric alert"

  # Note: divides CPU usage by `1000000000` to convert nano cores into "cores"
  # before calculating the percent of available cores used
  query = "avg(last_5m):(avg:kubernetes.cpu.usage.total{env:${var.environment},service:${local.elb_controller}} by {pod_name} / 1000000000) / avg:kubernetes.cpu.limits{env:${var.environment},service:${local.elb_controller}} by {pod_name} > 70"

  message = "{{pod_name}} container CPU utilization {{#is_alert}}is over 70 percent{{/is_alert}}{{#is_recovery}}is below 70 percent{{/is_recovery}} ${local.context}"

  monitor_thresholds {
    critical = 70
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_w_service
}

resource "datadog_monitor" "container_down" {
  name = "AWS LBC container running"
  type = "query alert"
  query = "min(last_1m):default_zero(min:kubernetes_state.container.running{env:${var.environment},service:${local.elb_controller}} by {pod_name}) <= 0"
  message = "{{pod_name}} container is {{#is_alert}}down{{/is_alert}}{{#is_recovery}}up and running now{{/is_recovery}} ${local.context}"
  escalation_message = "*Container is still down!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_w_service
}

resource "datadog_monitor" "container_restarts" {
  name = "AWS LBC container restarts"
  type = "query alert"
  query = "max(last_2m):monotonic_diff(default_zero(sum:kubernetes_state.container.restarts{env:${var.environment},service:${local.elb_controller}} by {pod_name})) > 0"
  message = "{{pod_name}} service container is {{#is_alert}}restarting{{/is_alert}}{{#is_recovery}}stable now{{/is_recovery}} ${local.context}"
  escalation_message = "*Containers are still restarting!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_w_service
}

resource "datadog_monitor" "error_logging" {
  name = "AWS LBC error logging"
  type = "log alert"
  query = "logs(\"env:${var.environment} service:${local.elb_controller} status:error\").index(\"*\").rollup(\"count\").by(\"service\").last(\"5m\") > 0"
  message = "{{ service }} service is {{#is_recovery}}no longer{{/is_recovery}} experiencing abnormal levels of ERROR logging ${local.context}"
  escalation_message = "*Still logging errors!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  evaluation_delay = 30
  enable_logs_sample = false
  include_tags = true
  tags = local.tags_w_service
}

resource "datadog_monitor" "node_status" {
  name = "EKS Node is unschedulable"
  type = "query alert"
  query = "avg(last_5m):default_zero(sum:kubernetes_state.node.status{env:${var.environment},status:unschedulable} by {node}) > 0"
  message = "EKS Node {node} is {{#is_alert}}unschedulable{{/is_alert}}{{#is_recovery}}stable now{{/is_recovery}} ${local.context}"
  escalation_message = "*EKS Node is still unschedulable!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_env_only
}

resource "datadog_monitor" "node_disk_pressure" {
  name = "EKS Node is under disk pressure"
  type = "query alert"
  query = "avg(last_5m):default_zero(sum:kubernetes_state.node.by_condition{env:${var.environment},condition:diskpressure,status:unknown} by {node}) > 0"
  message = "EKS Node {node} is {{#is_alert}}under disk pressure{{/is_alert}}{{#is_recovery}}stable now{{/is_recovery}} ${local.context}"
  escalation_message = "*EKS Node is still under disk pressure!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_env_only
}

resource "datadog_monitor" "node_memory_pressure" {
  name = "EKS Node is under memory pressure"
  type = "query alert"
  query = "avg(last_5m):default_zero(sum:kubernetes_state.node.by_condition{env:${var.environment},condition:memorypressure,status:unknown} by {node}) > 0"
  message = "EKS Node {node} is {{#is_alert}}under memory pressure{{/is_alert}}{{#is_recovery}}stable now{{/is_recovery}} ${local.context}"
  escalation_message = "*EKS Node is still under memory pressure!*"
  monitor_thresholds {
    critical = 0
  }
  notify_no_data = false
  new_group_delay = 300
  renotify_interval = 10
  include_tags = true
  tags = local.tags_env_only
}
