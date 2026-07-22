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

variable "cluster-name" {
  type        = string
  description = "cluster name"
  default     = "spark-cluster"
}

variable "cluster-version" {
  type        = string
  description = "cluster version"
  default     = "1.36"
}

variable "eks-vpc-name" {
  type        = string
  description = "eks vpc name"
  default     = "eks-vpc"
}

variable "eks-vpc-cidr" {
  type        = string
  description = "eks vpc cidr"
  default     = "10.0.0.0/16"
}

variable "vpc-azs" {
  type        = list(string)
  description = "availability zones for the vpc"
}

variable "public-subnets-cidrs" {
  type        = list(string)
  description = "cidrs for the public subnets"
}

variable "private-subnets-cidrs" {
  type        = list(string)
  description = "cidrs for the private subnets"
}

# NODE GROUP

variable "eks-nodes-group-name" {
  type        = string
  description = "name of the node group"
  default     = "private-eks-nodes"
}

# ALB

variable "alb-role-name" {
  type        = string
  description = "name for the alb role"
  default     = "eks-load-balancer-controller"
}

# SPARK

variable "spark-bucket-name" {
  type        = string
  description = "spark data s3 bucket name"
  default     = "spark_test_datasets"
}
