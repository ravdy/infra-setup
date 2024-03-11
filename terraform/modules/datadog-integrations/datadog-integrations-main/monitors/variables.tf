variable "environment" {
  type = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}

variable "notification_channel" {
  type = string
  description = "(Optional) Notifications go to this channel: email, Slack, PagerDuty, etc."
  default = ""
}
