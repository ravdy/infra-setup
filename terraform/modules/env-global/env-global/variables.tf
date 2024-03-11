#
# AWS Locale Variables
#
variable "environment" {
  type        = string
  description = "Logical environment, for example dev-1,qa-1,uat-1,prod-1"
}

variable "datadog_aws_integration_external_id" {
  type        = string
  description = ""
}

#var for backup target encryption
variable "s3_backup_encryption" {
  default = "AES256"
  description = "The encryption type for the backup target bucket and replication bucket"
}

