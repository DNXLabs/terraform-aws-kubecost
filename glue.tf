resource "aws_glue_catalog_database" "athena_cur_database" {
  name        = "athenacurcfn_${aws_cur_report_definition.kubecost.report_name}"
  catalog_id  = var.payer_account_id
  description = "Athena database for Cost and Usage Report"
  provider    = aws
}

resource "aws_iam_role" "crawler_exec_role" {
  name               = "cur-athena-glue-crawler"
  assume_role_policy = data.aws_iam_policy_document.crawler_exec_role_assume_role.json
}

data "aws_iam_policy_document" "crawler_exec_role_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "crawler_exec_role" {
  role       = aws_iam_role.crawler_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "crawler_exec_role_inline" {
  role     = aws_iam_role.crawler_exec_role.name
  name     = "crawler-access"
  policy   = data.aws_iam_policy_document.crawler_exec_role_inline.json
  provider = aws
}

data "aws_iam_policy_document" "crawler_exec_role_inline" {
  statement {
    effect    = "Allow"
    sid       = "AllowPutLogs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect = "Allow"
    sid    = "AllowGlueAccess"
    actions = [
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
      "glue:CreateTable",
      "glue:ImportCatalogToGlue"
    ]
    resources = [
      # this is a * grant in the cloudformation
      "arn:aws:glue:${aws_s3_bucket.athena_results.region}:${var.is_payer_account ? data.aws_caller_identity.current.id : var.payer_account_id}:catalog",
      aws_glue_catalog_database.athena_cur_database.arn,
      "arn:aws:glue:${aws_s3_bucket.athena_results.region}:${var.is_payer_account ? data.aws_caller_identity.current.id : var.payer_account_id}:table/${aws_glue_catalog_database.athena_cur_database.name}/*"
    ]
  }
  statement {
    effect    = "Allow"
    sid       = "AllowS3Access"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.athena_results.arn}/${local.glue_crawler_s3_path}*"]
  }
}

resource "aws_glue_crawler" "crawler" {
  name          = "cur-glue-crawler"
  description   = "A recurring crawler that keeps your CUR table in Athena up-to-date."
  database_name = aws_glue_catalog_database.athena_cur_database.name
  role          = aws_iam_role.crawler_exec_role.arn
  s3_target {
    path       = "s3://${aws_s3_bucket.athena_results.bucket}/${local.glue_crawler_s3_path}"
    exclusions = ["**.json", "**.yml", "**.sql", "**.csv", "**.gz", "**.zip"]
  }
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DELETE_FROM_DATABASE"
  }
}

