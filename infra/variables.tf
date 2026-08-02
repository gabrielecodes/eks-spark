variable "environment" {
  type        = string
  description = "environment"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "deployment region"
  default     = "eu-west-1"
}

# EKS
variable "account_id" {
  type        = string
  description = "account id where for the eks cluster"
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
  default     = "spark-cluster"
}

variable "cluster_version" {
  type        = string
  description = "cluster version"
  default     = "1.36"
}

# VPC
variable "vpc_name" {
  type        = string
  description = "eks vpc name"
  default     = "eks-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "eks vpc cidr"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr_number" {
  type        = number
  description = "number of cidrs for the public subnets"
  default     = 2

  validation {
    condition     = var.public_subnets_cidr_number >= 2
    error_message = "At least 2 public subnets are required for a highly available internet-facing ALB."
  }

}

variable "private_subnets_cidr_number" {
  type        = number
  description = "number of cidrs for the private subnets"
  default     = 2

  validation {
    condition     = var.private_subnets_cidr_number >= 2
    error_message = "At least 2 private subnets are required to distribute EKS nodes across Availability Zones."
  }
}

# NODE GROUP

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

# ALB

variable "alb_role_name" {
  type        = string
  description = "name for the alb role"
  default     = "eks-load-balancer-controller"
}

# SPARK

variable "spark_bucket_name" {
  type        = string
  description = "spark data s3 bucket name"
}
