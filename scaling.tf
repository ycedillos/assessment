resource "aws_launch_template" "template" {
  name_prefix            = "blog"
  image_id               = var.image_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_https_sg.id, aws_security_group.web_http_sg.id, aws_security_group.web_ssh_sg.id]
  user_data              = data.template_cloudinit_config.config.rendered
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  target_group_arns = [aws_lb_target_group.example.arn]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}
