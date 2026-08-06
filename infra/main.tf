module "buckets" {
  source = "./modules/s3-secure-bucket"

  for_each = {
    spark_workflows_bucket  = var.spark_workflows_bucket_name
    spark_event_logs_bucket = var.spark_event_logs_bucket_name
    spark_data_bucket       = var.spark_data_bucket_name
  }

  bucket_name = each.value
  kms_key_arn = aws_kms_key.spark.arn

  tags = {
    Terraform   = "true"
    Application = "spark"
    Environment = var.environment
  }
}

module "eks" {
  source = "./modules/eks-cluster"

  environment     = var.environment
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  kms_key_alias   = var.kms_key_alias

  subnet_ids = aws_subnet.private[*].id

  bucket_names = [
    var.spark_workflows_bucket_name,
    var.spark_event_logs_bucket_name,
    var.spark_data_bucket_name
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  depends_on = [module.buckets]
}

module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name = module.eks.cluster_name
}


resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  # add version
  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = aws_vpc.main.id
    }
  ]

  depends_on = [module.eks_addons, module.eks]
}
