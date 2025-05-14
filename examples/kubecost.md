# Using this module with kubecost

First apply the module to create the Athena and CUR report resources:

```hcl
module "athena_cur" {
  source = ""
  name = "kubecost"
}
```

Then apply the irsa (IAM Roles for Service Accounts) so kubecost can have access to
the S3 bucket of CUR reports:

```hcl
module "kubecost_irsa" {
 source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 version = "~> 5.30"

 role_name_prefix              = "${var.environment}-${data.aws_region.current.name}-"
 assume_role_condition_test    = "StringLike"
 role_path                     = "/"
 role_permissions_boundary_arn = ""

 role_policy_arns = {
   policy = aws_iam_policy.kubecost.arn
 }

 oidc_providers = { for cluster in var.eks_clusters : cluster.name => {
   provider_arn               = cluster.oidc_provider
   namespace_service_accounts = ["${cluster.namespace}:*"]
 } }
}

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
    resources = [
      module.athena_cur.cur_s3_bucket.arn,
      "${module.athena_cur.cur_s3_bucket.arn}/*"
    ]
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
    resources = [
      module.athena_cur.athena_s3_bucket.arn,
      "${module.athena_cur.athena_s3_bucket.arn}/*"
    ]
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
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${module.athenas_cur.athena_workgroup.name}"
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
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:database/${module.athena_cur.athena_workgroup.db_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:table/${module.athena_cur.athena_workgroup.db_name}/*"
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
```

Apply helm chart:

```bash
helm
```
