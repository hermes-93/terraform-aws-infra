variable "name" {
  description = "Name prefix for all ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (tasks only accept traffic from it)"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "container_image" {
  description = "Docker image to run (e.g. ghcr.io/hermes-93/cicd-pipeline-demo:1.0.1)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "Task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of task replicas"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks (autoscaling)"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks (autoscaling)"
  type        = number
  default     = 4
}

variable "cpu_target_percent" {
  description = "Target CPU utilization % for autoscaling"
  type        = number
  default     = 70
}

variable "use_spot" {
  description = "Use FARGATE_SPOT capacity provider (cheaper, may be interrupted)"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region (used for CloudWatch log config)"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
