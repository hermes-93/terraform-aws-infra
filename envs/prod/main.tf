module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.name}-prod"
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = false   # HA: one NAT per AZ
}

module "alb" {
  source = "../../modules/alb"

  name                       = "${var.name}-prod"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  app_port                   = 8000
  health_check_path          = "/health"
  enable_deletion_protection = true
}

module "ecs" {
  source = "../../modules/ecs"

  name                  = "${var.name}-prod"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn

  container_image = var.container_image
  container_port  = 8000
  task_cpu        = 512
  task_memory     = 1024
  desired_count   = 2
  min_capacity    = 2
  max_capacity    = 10
  cpu_target_percent = 60
  use_spot        = false   # on-demand for prod reliability

  environment = {
    APP_ENV         = "production"
    LOG_LEVEL       = "WARNING"
    SERVICE_NAME    = var.name
    SERVICE_VERSION = "1.0.1"
  }

  aws_region         = var.aws_region
  log_retention_days = 30
}
