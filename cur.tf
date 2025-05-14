resource "aws_cur_report_definition" "kubecost" {
  report_name                = "KubecostCUR"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cur.id
  s3_region                  = data.aws_region.current.name
  s3_prefix                  = "kubecost-cur"
  report_versioning          = "OVERWRITE_REPORT"

  # Required for KubeCost integration
  additional_artifacts = ["ATHENA"]

  # Ensure bucket policy is applied before creating the report
  depends_on = [aws_s3_bucket_policy.cur]
  # Cur Report is only available on us-east-1
  provider   = aws.us-east-1
}

resource "aws_s3_bucket" "cur" {
  bucket = local.cur_bucket_name
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "cur" {
  bucket = aws_s3_bucket.cur.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Set proper ownership controls
resource "aws_s3_bucket_ownership_controls" "cur" {
  bucket = aws_s3_bucket.cur.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket                  = aws_s3_bucket.cur.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cur" {
  bucket = aws_s3_bucket.cur.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cur" {
  bucket = aws_s3_bucket.cur.id
  rule {
    id     = "cost"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = var.cur_data_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "cur" {
  bucket = aws_s3_bucket.cur.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSBillingDelivery"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.cur.arn}/*"]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.id
            "aws:SourceArn"     = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.id}:definition/*"
          }
        }
      },
      {
        Sid    = "AWSBillingGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action   = ["s3:GetBucketAcl", "s3:GetBucketPolicy"]
        Resource = [aws_s3_bucket.cur.arn]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.id
            "aws:SourceArn"     = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.id}:definition/*"
          }
        }
      }
    ]
  })
}

