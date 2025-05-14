resource "archive_file" "crawler_lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/invoke-crawler-lambda/index.js"
  output_path = "${path.cwd}/update-crawler-lambda-deployment.zip"
}

resource "aws_lambda_function" "cur_update_crawler_lambda" {
  function_name    = "invoke-crawler-on-cur-update"
  role             = aws_iam_role.crawler_lambda_executor.arn
  filename         = archive_file.crawler_lambda_payload.output_path
  source_code_hash = archive_file.crawler_lambda_payload.output_base64sha256
  runtime          = "nodejs18.x"
  handler          = "index.handler"
  environment {
    variables = {
      "CRAWLER_NAME" = aws_glue_crawler.crawler.name
    }
  }
  reserved_concurrent_executions = 1
  timeout                        = 30
  provider                       = aws
}

resource "aws_iam_role" "crawler_lambda_executor" {
  name               = "cur-athena-glue-lambda"
  assume_role_policy = data.aws_iam_policy_document.crawler_lambda_executor_assume_role.json
  provider           = aws
}
data "aws_iam_policy_document" "crawler_lambda_executor" {
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
      "glue:StartCrawler"
    ]
    resources = [
      aws_glue_crawler.crawler.arn
    ]
  }
  provider = aws
}
resource "aws_iam_role_policy" "crawler_lambda_executor" {
  role     = aws_iam_role.crawler_lambda_executor.name
  name     = "start-crawler-and-logs"
  policy   = data.aws_iam_policy_document.crawler_lambda_executor.json
  provider = aws
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cur_update_crawler_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.athena_s3_bucket.arn
  provider      = aws
}

resource "aws_s3_bucket_notification" "cur_bucket_notification" {
  bucket = aws_s3_bucket.athena_s3_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.cur_update_crawler_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.glue_crawler_s3_path
  }
  provider   = aws
  depends_on = [aws_lambda_permission.allow_bucket]
}
