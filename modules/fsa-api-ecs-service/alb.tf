# Creating Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.name}-alb-sg-${var.mandatory_tags.Environment}"
  description = "Security Group for ALB targeting ${var.name}-${var.mandatory_tags.Environment}"

  ingress {
    description     = "HTTP port"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.web_app_sg_id]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-alb-sg-${var.mandatory_tags.Environment}"
    }
  )
}

resource "aws_alb" "alb" {
  name               = "${var.name}-alb-${var.mandatory_tags.Environment}"
  internal           = true
  load_balancer_type = "application"

  subnets         = var.private_subnets_ids
  security_groups = [aws_security_group.alb_sg.id]

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-alb-${var.mandatory_tags.Environment}"
    }
  )
}

resource "aws_alb_target_group" "alb_tg" {
  name_prefix = "alb-tg"
  vpc_id      = var.vpc_id
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    port                = var.app_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  load_balancing_algorithm_type = "round_robin"

  tags = merge(
    var.mandatory_tags,
    {
      Name = "alb-tg-${var.name}-${var.mandatory_tags.Environment}"
    }
  )
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb_tg.arn
    type             = "forward"
  }
}