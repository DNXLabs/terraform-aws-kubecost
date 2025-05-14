locals {
  cur_bucket_name      = "${var.name}-cur-athena-export-"
  athena_db_name       = "athenacurcfn_kubecost_c_u_r"
  athena_table         = "kubecostcur"
  glue_crawler_s3_path = "${aws_cur_report_definition.kubecost.s3_prefix}/${aws_cur_report_definition.kubecost.report_name}/${aws_cur_report_definition.kubecost.report_name}"
}

