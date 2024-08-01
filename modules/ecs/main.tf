resource "aws_ecs_cluster" "demo_app_cluster" {
  name = var.demo_app_cluster_name
}

resource "aws_ecs_task_definition" "demo_app_task" {
  family = var.demo_app_task_family
  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "${var.demo_app_task_name}"
      image     = "${var.ecr_repo}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.mysql_db
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "app_loadbalancer" {
  name               = var.app_loadbalancer
  load_balancer_type = "application"
  security_groups    = [var.lb-sg]
  subnets            = var.prod-subnet

}

resource "aws_lb_target_group" "target_group" {
  name     = var.target_group
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.vpc-id

  health_check {  
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
resource "aws_lb_listener" "prod-listener-https" {
  load_balancer_arn = aws_lb.app_loadbalancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn =aws_lb_target_group.target_group.arn
  }
}

resource "aws_ecs_service" "demo_app_service" {
  name            = var.demo_app_service_name
  cluster         = aws_ecs_cluster.demo_app_cluster.id
  task_definition = aws_ecs_task_definition.demo_app_task.arn
  desired_count   = 2
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.demo_app_task.family
    container_port   = 8080
  }

 network_configuration {
   subnets = var.prod-subnet
   assign_public_ip = true
   security_groups = [ "${aws_security_group.service_security_group.id}" ]
 }
}

resource "aws_security_group" "service_security_group" {
  name        = "ecs-sg"
  description = "ecs Security Group"
  vpc_id      = var.vpc-id

  #Inbound Rules
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}