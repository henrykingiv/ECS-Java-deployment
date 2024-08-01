locals {
  ecr_repo_name     = "ecr-repo-name"
  ecs_cluster_name  = "ecs_service"
  availability_zone = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  app_loadbalancer  = "alb"
  target_group      = "tglb"
  name              = "ecs-deployment"
}

data "aws_acm_certificate" "cert" {
  domain      = "henrykingroyal.co"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

module "vpc" {
  source         = "./modules/vpc"
  public-subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  azs            = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private-subnet = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

module "security_groups" {
  source = "./modules/security-group"
  vpc-id = module.vpc.vpc
  ecs_sg = module.ecscluster.ecs-sg
}

module "keypair" {
  source = "./modules/keypair"
}

module "route53" {
  source                = "./modules/route53"
  domain_name           = "henrykingroyal.co"
  jenkins_domain_name   = "jenkins.henrykingroyal.co"
  jenkins_lb_dns_name   = module.jenkins.jenkins-dns-name
  jenkins_lb_zone_id    = module.jenkins.jenkins-zone-id
  nexus_domain_name     = "nexus.henrykingroyal.co"
  nexus_lb_dns_name     = module.nexus.nexus-dns-name
  nexus_lb_zone_id      = module.nexus.nexus-zone-id
  sonarqube_domain_name = "sonarqube.henrykingroyal.co"
  sonarqube_lb_dns_name = module.sonarqube.sonarqube-dns-name
  sonarqube_lb_zone_id  = module.sonarqube.sonarqube-zone-id
  prod_domain_name      = "prod.henrykingroyal.co"
  prod_lb_dns_name      = module.ecscluster.ecs_dns_name
  prod_lb_zone_id       = module.ecscluster.ecs_zone_id
}

module "ssm" {
  source = "./modules/ssm"
}

module "ecr_repo" {
  source        = "./modules/ecr"
  ecr_repo_name = local.ecr_repo_name
}

module "ecscluster" {
  source                       = "./modules/ecs"
  demo_app_cluster_name        = local.ecs_cluster_name
  demo_app_task_family         = local.ecs_cluster_name
  demo_app_service_name        = local.ecs_cluster_name
  ecr_repo                     = module.ecr_repo.repositoty_url
  demo_app_task_name           = local.ecs_cluster_name
  ecs_task_execution_role_name = local.ecs_cluster_name
  app_loadbalancer             = local.app_loadbalancer
  target_group                 = local.target_group
  prod-subnet                  = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  lb-sg                        = module.security_groups.asg-sg
  vpc-id                       = module.vpc.vpc
  certificate_arn              = data.aws_acm_certificate.cert.arn
  mysql_db                     = module.az-db.db-instance
  db_name                      = "petclinic"
  db_username                  = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  db_password                  = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "MyDatabaseCredentials"
}
data "aws_secretsmanager_secret" "nr_credentials" {
  name = "MyNewRelicCredentials"
}


data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}
data "aws_secretsmanager_secret_version" "nr_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.nr_credentials.id
}

module "az-db" {
  source                  = "./modules/az-db"
  db_subnet_grp           = "db-subnetgrp"
  subnet                  = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tag-db-subnet           = "${local.name}-az-db"
  security_group_mysql_sg = module.security_groups.rds-sg
  db_name                 = "petclinic"
  db_username             = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  db_password             = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
}

module "jenkins" {
  source        = "./modules/jenkins"
  ami           = "ami-07d1e0a32156d0d21"
  subnet-id     = module.vpc.privatesub2
  jenkins-sg    = module.security_groups.jenkins-sg
  key-name      = module.keypair.keypair_Pub
  jenkins-name  = "${local.name}-jenkins"
  subnet-elb    = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn      = data.aws_acm_certificate.cert.arn
  iam-role-name = module.ssm.iam-role-name
  ecr-url       = module.ecr_repo.repositoty_url
  nr-key        = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelickey"]
  nr-acc-id     = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelicid"]
  nr-region     = "EU"
}

module "nexus" {
  source        = "./modules/nexus"
  ami           = "ami-07d1e0a32156d0d21"
  keypair       = module.keypair.keypair_Pub
  nexus-sg      = module.security_groups.nexus-sg
  subnet_id     = module.vpc.privatesub1
  nexus-name    = "${local.name}-nexus"
  elb-subnets   = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  iam-role-name = module.ssm.iam-role-name
  cert-arn      = data.aws_acm_certificate.cert.arn
  nr-key        = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelickey"]
  nr-acc-id     = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelicid"]
  nr-region     = "EU"
}

module "sonarqube" {
  source         = "./modules/sonarqube"
  ami            = "ami-07c1b39b7b3d2525d"
  sonarqube-sg   = module.security_groups.sonarqube-sg
  keypair        = module.keypair.keypair_Pub
  subnet_id      = module.vpc.privatesub3
  sonarqube-name = "${local.name}-sonarqube"
  elb-subnets    = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn       = data.aws_acm_certificate.cert.arn
  iam-role-name  = module.ssm.iam-role-name
  nr-key        = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelickey"]
  nr-acc-id     = jsondecode(data.aws_secretsmanager_secret_version.nr_credentials_version.secret_string)["newrelicid"]
  nr-region      = "EU"
}
