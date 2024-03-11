# --------------- S3 Bucket Definition ---------------
resource "aws_s3_bucket" "logs" {
  bucket = "${var.environment}-${var.segment}-ingress-datadog-logs"

  object_lock_enabled = false
}
locals {
  logging_bucket = aws_s3_bucket.logs.id
  logging_prefix = "ingress_nginx"
}

# Ownership and Access
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = local.logging_bucket
  lifecycle { prevent_destroy = true }

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = local.logging_bucket
  lifecycle { prevent_destroy = true }

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs_writing" {
  bucket = local.logging_bucket
  policy = data.aws_iam_policy_document.logs_writing.json
}

data "aws_iam_policy_document" "logs_writing" {
  statement {
    principals {
      type = "Service"
      identifiers = [ "delivery.logs.amazonaws.com" ]
    }
    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = [ local.account_id ]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

# Bucket Life Cycle
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = local.logging_bucket

  rule {
    id = "delete-old-logs"
    status = "Enabled"

    filter { prefix = local.logging_prefix }
    expiration { days = 7 }
  }
}

# Encryption: SSE-S3 is required for network load balancer logs — KMS is incompatible.
#
# SSE-S3 Trade-Offs:
# * Adequate security: assumes IAM policies are sufficient.
# * Simplest encryption at rest.
#
# KMS Trade-Offs:
# * Higher standard of security. Usually targeted at secret data.
# * Limits access to a single region _or_ a more complicated multi-region key setup.
# * Required key rotation adds a (rare) failure mode that locks away the logs forever.
#
# Client-Side Trade-Offs:
# * Highest standard of security available. Usually targeted at very high-risk, high-value data.
# * Adds key-management to the list of things we have to manage.
# * Key rotation (recommended at a minimum every time a developer changes) is much more difficult.
resource "aws_s3_bucket_server_side_encryption_configuration" "datadog_logs" {
  bucket = local.logging_bucket
  lifecycle { prevent_destroy = true }

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}



