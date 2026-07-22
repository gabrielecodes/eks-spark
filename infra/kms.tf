resource "aws_kms_key" "spark" {
  description             = "KMS key for Spark data lake"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "spark" {
  name          = "alias/spark-data"
  target_key_id = aws_kms_key.spark.key_id
}
