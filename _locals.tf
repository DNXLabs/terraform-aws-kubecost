locals {
  cur_bucket_name = "${var.name}-cur-${data.aws_caller_identity.current.id}"
  athena_db_name  = "athenacurcfn_kubecost_c_u_r"
  athena_table    = "kubecostcur"
}

