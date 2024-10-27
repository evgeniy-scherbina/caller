resource "aws_lb" "alb" {
  name               = "ecs-alb-${local.service_name}-${local.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in data.aws_subnet.default : s.id if s.map_public_ip_on_launch]
}

resource "aws_lb_target_group" "tg" {
  name     = "ecs-target-${local.service_name}-${local.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"
#  target_type = "instance"

  health_check {
    path                = "/user/yevhenii"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
