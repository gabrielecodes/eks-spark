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

