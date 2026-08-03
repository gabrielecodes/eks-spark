variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for server-side encryption."
  type        = string
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
