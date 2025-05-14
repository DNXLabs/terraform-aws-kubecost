# output "cloud_integration" {
#   value = {
#     athenaBucketName = ""
#     athenaRegion     = ""
#     athenaDatabase   = ""
#     athenaTable      = ""
#     athenaWorkgroup  = ""
#     projectID        = ""
#     masterPayerARN   = ""
#   }
# }

output "cur_s3_bucket" {
  value = {
    name   = aws_s3_bucket.cur.bucket
    region = aws_s3_bucket.cur.region
    arn    = aws_s3_bucket.cur.arn
    id     = aws_s3_bucket.cur.id
  }
}

output "athena_s3_bucket" {
  value = {
    name   = aws_s3_bucket.athena_results.bucket
    region = aws_s3_bucket.athena_results.region
    arn    = aws_s3_bucket.athena_results.arn
    id     = aws_s3_bucket.athena_results.id
  }
}

output "athena_workgroup" {
  value = {
    name       = aws_athena_workgroup.athena.name
    #region     = aws_athena_workgroup.kubecost.region
    arn        = aws_athena_workgroup.athena.arn
    id         = aws_athena_workgroup.athena.id
    db_name    = local.athena_db_name
    # table_name = local.athena_table_name
  }
}

output "cur_report_definition" {
  value = {
    report_name            = aws_cur_report_definition.cur.report_name
    time_unit              = aws_cur_report_definition.cur.time_unit
    format                 = aws_cur_report_definition.cur.format
    compression            = aws_cur_report_definition.cur.compression
    s3_bucket              = aws_cur_report_definition.cur.s3_bucket
    s3_region              = aws_cur_report_definition.cur.s3_region
    s3_prefix              = aws_cur_report_definition.cur.s3_prefix
    report_versioning      = aws_cur_report_definition.cur.report_versioning
    refresh_closed_reports = aws_cur_report_definition.cur.refresh_closed_reports
  }
}
