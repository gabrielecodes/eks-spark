resource "aws_s3_bucket" "spark" {
  bucket = var.spark_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "spark" {
  bucket = aws_s3_bucket.spark.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.spark.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "spark" {
  bucket = aws_s3_bucket.spark.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "spark" {
  bucket = aws_s3_bucket.spark.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
