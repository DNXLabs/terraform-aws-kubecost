resource "aws_athena_workgroup" "athena" {
  name        = var.name
  description = "Workgroup for queries"
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/athena-query-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_glue_catalog_table" "report_status_table" {
  database_name = aws_glue_catalog_database.athena_cur_database.name
  catalog_id    = var.payer_account_id
  name          = "cost_and_usage_data_status"
  table_type    = "EXTERNAL_TABLE"
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.athena_results.bucket}/${aws_cur_report_definition.cur.s3_prefix}/${aws_cur_report_definition.cur.report_name}/cost_and_usage_data_status"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
    columns {
      name = "status"
      type = "string"
    }
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket_prefix = "${var.name}-aws-athena-query-results-"
  force_destroy = true
}

# Set proper ownership controls for Athena results bucket
resource "aws_s3_bucket_ownership_controls" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add lifecycle policy for Athena results
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    id     = "cost"
    status = "Enabled"
    expiration {
      days = 30
    }
  }
}

