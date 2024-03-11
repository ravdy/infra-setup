# --------------- Set Up Archiving from Datadog ---------------
resource "datadog_logs_archive" "main" {
  name = "${var.cluster}-datadog-logs-archive"

  include_tags = true
  query = "env:${var.environment} segment:${var.segment}"
  rehydration_tags = [ "rehydrated:${var.environment}" ]

  s3_archive {
    bucket = local.bucket
    path = ""
    account_id = var.account
    role_name = var.role
  }
}


# --------------- S3 Bucket Definition ---------------
resource "aws_s3_bucket" "datadog_logs" {
  bucket = "${var.cluster}-datadog-logs"

  object_lock_enabled = true
}
locals { bucket = aws_s3_bucket.datadog_logs.id }

# Ownership and Access
resource "aws_s3_bucket_ownership_controls" "datadog_logs" {
  bucket = local.bucket
  lifecycle { prevent_destroy = true }

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "datadog_logs" {
  bucket = local.bucket
  lifecycle { prevent_destroy = true }

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "datadog_logs" {
  name = "${var.cluster}-datadog-log-access"

  policy = templatefile(
    "${path.module}/policies/access-datadog-logs.json",
    { bucket = local.bucket }
  )
}

resource "aws_iam_role_policy_attachment" "datadog_logs" {
  role = var.role
  policy_arn = aws_iam_policy.datadog_logs.arn
}

# Bucket Life Cycle
resource "aws_s3_bucket_object_lock_configuration" "datadog_logs" {
  bucket = local.bucket

  rule {
    default_retention {
      mode = "GOVERNANCE"
      years = var.log_retention_years
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "datadog_logs" {
  bucket = local.bucket

  rule {
    id = "archive-old-datadog-logs"
    status = "Enabled"

    transition {
      days = 60
      storage_class = "GLACIER"
    }
  }
}

# Encryption: We are going with KMS encryption. The logs may include secret data, including client
# data, and needs a higher standard of security. Weighed against the risk of losing access to the
# logs during mandatory rotation, the risk of losing client data to the outside world is much
# higher. In addition, the trade-off of region-specific is less of an issue: the logs _are_
# region-specific. On the other hand, client-side has a much higher risk of locking the logs
# forever, more overhead (especially given the need for developers and ops teams to view the logs
# on a regular basis), and only marginal improvements in the total security.
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
  bucket = local.bucket
  lifecycle { prevent_destroy = true }

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


