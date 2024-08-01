resource "aws_ecr_repository" "demo_ecr_repo" {
  name = var.ecr_repo_name
}