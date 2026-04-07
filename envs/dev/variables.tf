variable "name" {
  description = "Base name for all resources"
  type        = string
  default     = "cicd-pipeline-demo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "ghcr.io/hermes-93/cicd-pipeline-demo:1.0.1"
}
