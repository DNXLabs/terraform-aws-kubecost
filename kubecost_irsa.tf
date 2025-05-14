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

