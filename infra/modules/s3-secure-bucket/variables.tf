variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = true
}

variable "kms_key_alias_prefix" {
  type        = string
  description = "kms key alias prefix for the spark buckets. The full alias of the keys follow the convention <prefix>/<bucket_name>"
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}

