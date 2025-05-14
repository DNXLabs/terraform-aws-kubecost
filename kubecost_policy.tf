resource "aws_iam_policy" "kubecost" {
  name        = "${var.environment}-${data.aws_region.current.name}-kubecost-policy"
  description = "Provides necessary permissions for KubeCost"
  path        = "/"
  policy      = data.aws_iam_policy_document.combined.json
}

# Combine all policy documents
data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.kubecost_core.json,
    data.aws_iam_policy_document.kubecost_athena.json,
    data.aws_iam_policy_document.kubecost_s3.json,
    data.aws_iam_policy_document.kubecost_ec2.json,
    data.aws_iam_policy_document.kubecost_eks.json,
    # Optional policy for organizations access
    var.organization_access_enabled ? data.aws_iam_policy_document.kubecost_org[0].json : data.aws_iam_policy_document.empty.json
  ]
}

# Empty policy document for conditional inclusion
data "aws_iam_policy_document" "empty" {
  statement {
    sid       = "EmptyStatement"
    effect    = "Allow"
    actions   = []
    resources = []
  }
}

# Core KubeCost permissions
data "aws_iam_policy_document" "kubecost_core" {
  statement {
    sid    = "KubecostPricing"
    effect = "Allow"
    actions = [
      "pricing:GetProducts",
      "pricing:DescribeServices",
      "pricing:GetAttributeValues"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "KubecostCE"
    effect = "Allow"
    actions = [
      "ce:GetCostAndUsage",
      "ce:GetTags",
      "ce:GetDimensionValues",
      "ce:GetCostCategories"
    ]
    resources = ["*"]
  }
}

# S3 access for CUR and Athena results
data "aws_iam_policy_document" "kubecost_s3" {
  statement {
    sid    = "KubecostS3ReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.cur.arn, "${aws_s3_bucket.cur.arn}/*"]
  }

  statement {
    sid    = "KubecostS3AthenaResultsAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]
    resources = [aws_s3_bucket.athena_results.arn, "${aws_s3_bucket.athena_results.arn}/*"]
  }
}

# Athena permissions
data "aws_iam_policy_document" "kubecost_athena" {
  statement {
    sid    = "KubecostAthenaAccess"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StopQueryExecution",
      "athena:ListQueryExecutions"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${aws_athena_workgroup.kubecost.name}"
    ]
  }

  statement {
    sid    = "KubecostGlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:BatchGetPartition"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:database/${local.athena_db_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:table/${local.athena_db_name}/*"
    ]
  }
}

# EC2 pricing data access
data "aws_iam_policy_document" "kubecost_ec2" {
  statement {
    sid    = "KubecostEC2Access"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesModifications",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeSavingsPlans",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotPriceHistory"
    ]
    resources = ["*"]
  }
}

# EKS data access
data "aws_iam_policy_document" "kubecost_eks" {
  statement {
    sid       = "KubecostEKSAccess"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = ["*"]
  }
}

# Organizations access (optional)
data "aws_iam_policy_document" "kubecost_org" {
  count = var.organization_access_enabled ? 1 : 0
  statement {
    sid    = "KubecostOrganizationsAccess"
    effect = "Allow"
    actions = [
      "organizations:ListAccounts",
      "organizations:DescribeOrganization",
      "organizations:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

