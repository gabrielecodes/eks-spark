# # Spark workflows S3 bucket
# resource "aws_s3_bucket" "spark_workflows" {
#   bucket = var.spark_workflows_bucket_name
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "spark" {
#   bucket = aws_s3_bucket.spark_workflows.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.spark.arn
#       sse_algorithm     = "aws:kms"
#     }

#     bucket_key_enabled = true
#   }
# }

# resource "aws_s3_bucket_versioning" "spark" {
#   bucket = aws_s3_bucket.spark_workflows.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "spark" {
#   bucket = aws_s3_bucket.spark_workflows.id

#   block_public_acls       = true
#   ignore_public_acls      = true
#   block_public_policy     = true
#   restrict_public_buckets = true
# }

# # Spark Event logs
# resource "aws_s3_bucket" "spark_event_logs" {
#   bucket = var.spark_event_logs_bucket_name
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.spark.arn
#       sse_algorithm     = "aws:kms"
#     }

#     bucket_key_enabled = true
#   }
# }

# resource "aws_s3_bucket_versioning" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   block_public_acls       = true
#   ignore_public_acls      = true
#   block_public_policy     = true
#   restrict_public_buckets = true
# }

# # Spark data
# resource "aws_s3_bucket" "spark_event_logs" {
#   bucket = var.spark_event_logs_bucket_name
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.spark.arn
#       sse_algorithm     = "aws:kms"
#     }

#     bucket_key_enabled = true
#   }
# }

# resource "aws_s3_bucket_versioning" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "spark" {
#   bucket = aws_s3_bucket.spark_event_logs.id

#   block_public_acls       = true
#   ignore_public_acls      = true
#   block_public_policy     = true
#   restrict_public_buckets = true
# }
