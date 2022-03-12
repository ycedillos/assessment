resource "aws_lb" "front_end" {
  name               = "frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_http_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# It is important to have"200-302" in matcher property.
# Because WordPress will send 302 to start the configuration of Wordpress in the wizard. If you have only 200 the Load Balancer will fail!.
resource "aws_lb_target_group" "example" {
  name        = "tf-example-lb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.websites.id
  health_check {
    enabled             = true
    protocol            = "HTTP"
    unhealthy_threshold = 2
    path                = "/"
    timeout             = 10
    port                = "traffic-port"
    interval            = 30
    healthy_threshold   = 3
    matcher             = "200-302"

  }
}
