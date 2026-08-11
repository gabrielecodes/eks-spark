variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "nodes_instance_type" {
  type    = string
  default = "t3.small"
}

variable "nodes_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "subnet_ids" {
  type = list(string)
}

variable "kms_key_alias_prefix" {
  type        = string
  description = "kms key alias prefix for the spark buckets. The full alias of the keys follow the convention <prefix>/<bucket_name>"
}

variable "bucket_names" {
  type        = list(string)
  description = "Names of the S3 bucket the nodes can have access to"
}

variable "tags" {
  type    = map(string)
  default = {}
}
