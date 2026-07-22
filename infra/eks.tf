module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster-name
  kubernetes_version = var.cluster-version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # service_ipv4_cidr = var.cluster-service-cidr

  eks_managed_node_groups = {
    default = {
      name = var.eks-nodes-group-name

      min_size     = 2
      max_size     = 3
      desired_size = 3

      instance_types = [
        "t3.small"
      ]

      capacity_type = "ON_DEMAND"

      subnet_ids = module.vpc.private_subnets
    }
  }

  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "True"
  }
}
