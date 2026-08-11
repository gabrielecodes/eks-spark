variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "kms_key_alias" {
  type        = string
  description = "kms key alias for the spark buckets"
}

variable "enable_versioning" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}

