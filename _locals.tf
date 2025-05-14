locals {
  cur_bucket_name      = "${var.name}-cur-athena-export-"
  athena_db_name       = "athenacurcfn_${var.name}_c_u_r"
  athena_table         = "${var.name}cur"
  glue_crawler_s3_path = "${aws_cur_report_definition.cur.s3_prefix}/${aws_cur_report_definition.cur.report_name}/${aws_cur_report_definition.cur.report_name}"

}

