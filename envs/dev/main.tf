module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.name}-dev"
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = true   # cost-optimised for dev
}

module "alb" {
  source = "../../modules/alb"

  name                       = "${var.name}-dev"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  app_port                   = 8000
  health_check_path          = "/health"
  enable_deletion_protection = false
}

module "ecs" {
  source = "../../modules/ecs"

  name                  = "${var.name}-dev"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn

  container_image = var.container_image
  container_port  = 8000
  task_cpu        = 256
  task_memory     = 512
  desired_count   = 1
  min_capacity    = 1
  max_capacity    = 2
  use_spot        = true   # cheaper for dev

  environment = {
    APP_ENV          = "development"
    LOG_LEVEL        = "DEBUG"
    SERVICE_NAME     = var.name
    SERVICE_VERSION  = "1.0.1"
  }

  aws_region         = var.aws_region
  log_retention_days = 3
}
