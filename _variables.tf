variable "name" {
  type        = string
  description = "Prefix to add to resources"
}

variable "environment" {
  type        = string
  description = "Environment of project"
}

#variable "eks_clusters" {
#  type = list(object({
#    name          = string
#    oidc_provider = string
#    namespace     = string
#  }))
#  description = "EKS Clusters to setup IRSA (IAM Roles for Service Accounts)"
#}

variable "cur_data_retention_days" {
  type    = number
  default = 90
}

variable "athena_results_retention_days" {
  type    = number
  default = 90
}

variable "organization_access_enabled" {
  type        = bool
  default     = false
  description = "If kubecost policy should have read-only access to organization"
}

variable "is_payer_account" {
  type    = bool
  default = false
}

variable "payer_account_id" {
  type        = string
  description = "Payer account ID for the organization"
  default     = ""
}

