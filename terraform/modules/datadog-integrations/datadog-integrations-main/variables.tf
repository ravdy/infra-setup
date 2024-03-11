variable "environment" {
  type = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}

variable "segment" {}

variable "segments" {
  type = list(string)
  description = "A specific stack in environment. I.e., active/active might have 'east' and 'west'."
  default = [
    "east",
    "west"
  ]
}

variable "datadog_api_key" {}
variable "datadog_app_key" {}

variable "integration_role" {
  type = string
  description = "(Optional) The name of the IAM Role which Datadog assumes for monitoring purposes."
  default = "DatadogAWSIntegrationRole"
}

variable "log_retention_years" {
  type = number
  description = "(Optional; default 1 year) The number of years that logs will be (almost) undeletable"
  default = 1
}

variable "create_monitors" {
  type = bool
  description = "(Optional; default true) Whether or not to create baseline Datadog monitors."
  default = true
}

variable "notification_channel" {
  type = string
  description = "(Optional) Monitor notifications go to this channel: email, Slack, PagerDuty, etc."
  default = ""
}
