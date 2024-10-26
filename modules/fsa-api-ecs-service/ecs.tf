data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
}

resource "aws_iam_role" "this" {
  name = "${var.name}-ECS-Role-${var.mandatory_tags.Environment}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ecs-tasks.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "this" {
  name = "${var.name}-ECS-Inline-Policy-${var.mandatory_tags.Environment}"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "CWACloudWatchServerPermissions",
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:PutMetricData",
            "ec2:DescribeVolumes",
            "ec2:DescribeTags",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"
          ],
          "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.name}-${var.mandatory_tags.Environment}:*"
        }
      ]
    }
  )
}

resource "aws_security_group" "ecs_service_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.name}-${var.mandatory_tags.Environment}-sg"
  description = "App security group"

  ingress {
    description     = "App port"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-${var.mandatory_tags.Environment}-sg"
    }
  )
}

#Creating Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.name}-task-${var.mandatory_tags.Environment}"
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = aws_iam_role.this.arn
  container_definitions    = <<DEFINITION
  [
    {
        "name":"${var.name}-task-${var.mandatory_tags.Environment}",
        "image":"${var.docker_image_url}",
        "memory": 512,
        "cpu": 256,
        "portMappings":[
          {
              "name":"${var.name}-${var.app_port}-tcp",
              "containerPort":${var.app_port},
              "hostPort":${var.app_port},
              "protocol":"tcp",
              "appProtocol":"http"
          }
        ],        
        "essential":true,
        "environment":[
          {
              "name":"PORT",
              "value":"${var.app_port}"
          },
          {
              "name":"DB_HOST",
              "value":"${var.db_host}"
          },
          {
              "name":"DB_USER",
              "value":"${var.db_admin_user}"
          },
          {
              "name":"DB_PWD",
              "value":"${var.db_pwd}"
          }, 
          {
              "name":"DB_NAME",
              "value":"${var.db_name}"
          },                                       
          {
              "name":"ANSWER_ENDPOINT",
              "value":"${var.answer_endpoint}"
          },
          {
              "name":"TZ",
              "value":"America/Tijuana"
          }
        ],
        "logConfiguration":{
          "logDriver":"awslogs",
          "options":{
              "awslogs-group":"/ecs/${var.name}-${var.mandatory_tags.Environment}",
              "mode":"non-blocking",
              "awslogs-create-group":"true",
              "max-buffer-size":"25m",
              "awslogs-region":"${data.aws_region.current.name}",
              "awslogs-stream-prefix":"ecs"
          },
          "secretOptions":[
              
          ]
        }
    }
  ]
  DEFINITION

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-task-${var.mandatory_tags.Environment}"
    }
  )
}

#Create an ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "${var.name}-service-${var.mandatory_tags.Environment}"
  cluster         = var.ecs_cluster_id                   # Reference the created Cluster
  task_definition = aws_ecs_task_definition.app_task.arn # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Set up the number of containers to 3

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_tg.arn # Reference the target group
    container_name   = aws_ecs_task_definition.app_task.family
    container_port   = var.app_port # Specify the container port
  }

  network_configuration {
    subnets          = var.private_subnets_ids
    assign_public_ip = false                                       # Provide the containers with public IPs
    security_groups  = ["${aws_security_group.ecs_service_sg.id}"] # Set up the security group
  }

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-service-${var.mandatory_tags.Environment}"
    }
  )
}