module "eks" {
  source = "./modules/eks-cluster"

  environment     = var.environment
  cluster_name    = "${var.environment}-${var.cluster_name}"
  cluster_version = var.cluster_version
  role_name       = "${var.environment}-${var.cluster_name}-role"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name = module.eks.cluster_name
}

# spark workflows bucket
module "spark_workflows_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name = var.spark_workflows_bucket_name
  kms_key_arn = aws_kms_key.spark.arn

  tags = {
    Terraform   = "true"
    Application = "spark"
    Environment = var.environment
  }
}

# spark event logs bucket
module "spark_event_logs_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name = var.spark_event_logs_bucket_name
  kms_key_arn = aws_kms_key.spark.arn

  tags = {
    Terraform   = "true"
    Application = "spark"
    Environment = var.environment
  }
}

# spark data bucket
module "spark_data_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name = var.spark_data_bucket_name
  kms_key_arn = aws_kms_key.spark.arn

  tags = {
    Terraform   = "true"
    Application = "spark"
    Environment = var.environment
  }
}
