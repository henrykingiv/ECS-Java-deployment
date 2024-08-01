variable "demo_app_cluster_name" {
  description = "ecs-cluster"
  type = string
}

variable "demo_app_task_family" {
  description = "ecs-task-family"
  type = string
}
variable "demo_app_task_name" {
  description = "ecs-app-task-name"
  type = string
}
variable "ecr_repo" {
  description = "ecr-url"
  type = string
}
variable "ecs_task_execution_role_name" {
  description = "ecs-task-execution"
  type = string
}
variable "app_loadbalancer" {
  description = "ecs-app-lb"
  type = string
}
# variable "availability_zone" {
#   description = "eu-west-2-AZs"
#   type = list(string)
# }
variable "target_group" {
  description = "tg-name"
  type = string
}

variable "demo_app_service_name" {
  description = "ecs-app-service"
  type = string
}
variable "prod-subnet" {}
variable "lb-sg" {}
variable "vpc-id" {}
variable "certificate_arn" {}
variable "mysql_db" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
