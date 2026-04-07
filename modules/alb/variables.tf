variable "name" {
  description = "Name prefix for all ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB is deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB (minimum 2)"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application containers listen on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path used for ALB health checks"
  type        = string
  default     = "/health"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB (recommended for prod)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
