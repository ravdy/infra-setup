# aws iam policy doucment for, assume role , allow service s3 assume role sts
data "aws_region" "replication" {
  provider = aws.replication
}

data "aws_region" "target" {
  provider = aws.target
}


data "aws_iam_policy_document" "s3_assume_role_policy"{
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["s3.amazonaws.com"]
        }
    }
}
# aws iam role s3_db_backups_replication
resource "aws_iam_role" "s3_db_backups_replication_role" {
    name = "s3_db_backups_replication_role"
    assume_role_policy = "${data.aws_iam_policy_document.s3_assume_role_policy.json}"
}

# aws iam policy document replicat for s3 target
data "aws_iam_policy_document" "s3_db_backups_replication_policy_document" {
    statement {
        effect = "Allow"
        actions = ["s3:GetReplicationConfiguration",
                  "s3:ListBucket",
                  "s3:GetObjectVersion",
                  "s3:GetObjectVersionAcl",
                  "s3:GetObjectVersionForReplication",
                  "s3:GetObjectVersionAcl",
                  "s3:GetObjectVersionTagging"
                  ]
        resources = [aws_s3_bucket.s3_db_backups_target.arn,
                    "${aws_s3_bucket.s3_db_backups_target.arn}/*"
                    ]
    }
    statement {
        effect = "Allow"
        actions = ["s3:ReplicateObject",
                  "s3:ReplicateDelete",
                  "s3:ReplicateTags"]
        resources = ["${aws_s3_bucket.s3_bucket_backup_replication.arn}/*"]
    }
}
# resource iam policy replication 
resource "aws_iam_policy" "s3_db_backups_replication" {
    name = "s3_backup_replication_policy"
    policy = "${data.aws_iam_policy_document.s3_db_backups_replication_policy_document.json}"
}
# iam role policy attachment replication 
resource "aws_iam_role_policy_attachment" "replication" {
    role = "${aws_iam_role.s3_db_backups_replication_role.name}"
    policy_arn = "${aws_iam_policy.s3_db_backups_replication.arn}"
}

# lifecycle with retention, days are 1,3,7,21,30,60 
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_policy_s3_db_backups_replication"{
    provider = aws.replication
    bucket = "${aws_s3_bucket.s3_bucket_backup_replication.id}"

    rule {
        id = "1day"
        filter {
            prefix = "1day/"

        }
        status = "Enabled"
        expiration {
            days = 1
        }
    }
    rule {
        id = "3days"
        filter {
            prefix = "3days/"

        }
        status = "Enabled"
        expiration {
            days = 3
        }
    
    }
    rule {
        id = "7days"
        filter {
            prefix = "7days/"

        }
        status = "Enabled"
        expiration {
            days = 7
        }
    }
    rule {
        id = "21days"
        filter {
            prefix = "21days/"

        }
        status = "Enabled"
        expiration {
            days = 21
        }
    }
    rule {
        id = "30days"
        filter {
            prefix = "30days/"

        }
        status = "Enabled"
        expiration {
            days = 30
        }
    }
    rule {
        id = "60days"
        filter {
            prefix = "60days/"

        }
        status = "Enabled"
        expiration {
            days = 60
        }
    }
    
}
# region var = aws replication provider region



# replication bucket
resource "aws_s3_bucket" "s3_bucket_backup_replication" {
    bucket = "xpansiv-${var.environment}-${data.aws_region.replication.name}-replication"
    provider = aws.replication
    tags = {
        environment = "${var.environment}"
        region = "${data.aws_region.replication.name}"
        created_by = "terraform"
        created_with = "tf-modules/ENV-SEG"
    }
}
# acl for replication bucket
resource "aws_s3_bucket_acl" "s3_backup_acl_replication" {
    provider = aws.replication
    bucket = "${aws_s3_bucket.s3_bucket_backup_replication.id}"
    acl    = "private"
}
# aws bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_db_backups_replication_encryption" {
    provider = aws.replication
    bucket = "${aws_s3_bucket.s3_bucket_backup_replication.id}"
    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "${var.s3_backup_encryption}"
        }
    }
}


#aws bucket versioning
resource "aws_s3_bucket_versioning" "s3_db_backups_replication_versioning" {
  provider = aws.replication
  bucket = "${aws_s3_bucket.s3_bucket_backup_replication.id}"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "replication_acl" {
  provider = aws.replication
  bucket = aws_s3_bucket.s3_bucket_backup_replication.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# --------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "target_acl" {
  bucket = aws_s3_bucket.s3_db_backups_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# target backup bucket
resource "aws_s3_bucket" "s3_db_backups_target" {
    bucket = "xpansiv-${var.environment}-${data.aws_region.target.name}-backup"
    provider = aws.target
    tags = {
        environment = "${var.environment}"
        region = "${data.aws_region.target.name}"
        created_by = "terraform"
        created_with = "tf-modules/ENV-SEG"
    }
}

# acl for target bucket
resource "aws_s3_bucket_acl" "s3_backup_acl" {
  bucket = "${aws_s3_bucket.s3_db_backups_target.id}"
  acl    = "private"
}
# aws bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_db_backups_target_encryption" {
    bucket = "${aws_s3_bucket.s3_db_backups_target.id}"
    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "${var.s3_backup_encryption}"
        }
    }
}


#aws bucket versioning
resource "aws_s3_bucket_versioning" "s3_db_backups_target_versioning" {
  bucket = "${aws_s3_bucket.s3_db_backups_target.id}"
  versioning_configuration {
    status = "Enabled"
  }
}

# lifecycle with retention, days are 1,3,7,21,30,60 
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_policy_s3_target"{
    bucket = "${aws_s3_bucket.s3_db_backups_target.id}"
    rule {
        id = "1day"
        filter {
            prefix = "1day/"

        }
        status = "Enabled"
        expiration {
            days = 1
        }
    }
    rule {
        id = "3days"
        filter {
            prefix = "3days/"

        }
        status = "Enabled"
        expiration {
            days = 3
        }
    
    }
    rule {
        id = "7days"
        filter {
            prefix = "7days/"

        }
        status = "Enabled"
        expiration {
            days = 7
        }
    }
    rule {
        id = "21days"
        filter {
            prefix = "21days/"

        }
        status = "Enabled"
        expiration {
            days = 21
        }
    }
    rule {
        id = "30days"
        filter {
            prefix = "30days/"

        }
        status = "Enabled"
        expiration {
            days = 30
        }
    }
    rule {
        id = "60days"
        filter {
            prefix = "60days/"

        }
        status = "Enabled"
        expiration {
            days = 60
        }
    }

}




# replicates s3 bucket target to s3 bucket replication, using iam role replication  
resource "aws_s3_bucket_replication_configuration" "replication_s3_db_backups_lifecyclepolicy" {
    bucket = "${aws_s3_bucket.s3_db_backups_target.id}"
    role = "${aws_iam_role.s3_db_backups_replication_role.arn}"
    rule {
        id = "replication"
        filter {
            prefix =""
        }
        delete_marker_replication {
            status = "Enabled"
        }
        status = "Enabled"
        destination {
            bucket = "${aws_s3_bucket.s3_bucket_backup_replication.arn}"
            storage_class = "STANDARD"
        }
    }
}