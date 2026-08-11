module "buckets" {
  source = "./modules/s3-secure-bucket"

  for_each = {
    spark_workflows_bucket  = var.spark_workflows_bucket_name
    spark_event_logs_bucket = var.spark_event_logs_bucket_name
    spark_data_bucket       = var.spark_data_bucket_name
  }

  bucket_name          = each.value
  kms_key_alias_prefix = var.kms_key_alias_prefix

  tags = {
    Terraform   = "true"
    Application = "spark"
    Environment = var.environment
  }
}

module "eks" {
  source = "./modules/eks-cluster"

  environment          = var.environment
  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  kms_key_alias_prefix = var.kms_key_alias_prefix

  subnet_ids = aws_subnet.private[*].id

  bucket_names = [
    for bucket in module.buckets : bucket.bucket_name
  ]

  depends_on = [module.buckets]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
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
