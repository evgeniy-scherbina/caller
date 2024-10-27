resource "aws_ecs_cluster" "server" {
  name = "ecs-${local.service_name}-server-${local.environment}"
}

resource "aws_cloudwatch_log_group" "server" {
  name = "/ecs/server-${local.service_name}-server-${local.environment}"
}

resource "aws_ecs_task_definition" "server" {
  family                   = "server-${local.service_name}-${local.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name = "server"
      image     = "scherbina/caller-amd64:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/server-${local.service_name}-server-${local.environment}"
          awslogs-region        = var.caller_aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "server" {
  name            = "ecs-service-${local.service_name}-server-${local.environment}"
  cluster         = aws_ecs_cluster.server.id
  task_definition = aws_ecs_task_definition.server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 300

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "server"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role.ecs_execution_role,
    aws_iam_role.ecs_task_role,
    aws_cloudwatch_log_group.server,
  ]

  network_configuration {
    subnets = [for s in data.aws_subnet.default : s.id if s.map_public_ip_on_launch]
    assign_public_ip = "true"
  }
}
