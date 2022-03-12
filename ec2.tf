data "template_file" "script" {
  template = file("scripts/configure_cloudinit.yaml")
  vars = {
    username = var.master_username
    password = var.master_password
    host     = [for o in aws_rds_cluster_instance.cluster_instances : o][0].writer ? [for o in aws_rds_cluster_instance.cluster_instances : o][0].endpoint : [for o in aws_rds_cluster_instance.cluster_instances : o][1].endpoint
    database = var.database_name
  }
}

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.script.rendered
  }

  # part {
  #   content_type = "text/x-shellscript"
  #   content      = "baz"
  # }

  # part {
  #   content_type = "text/x-shellscript"
  #   content      = "ffbaz"
  # }
}
