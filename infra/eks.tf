module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster-name
  kubernetes_version = var.cluster-version

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  iam_role_arn = aws_iam_role.eks_cluster.arn

  eks_managed_node_groups = {
    default = {
      name         = var.eks-nodes-group-name
      iam_role_arn = aws_iam_role.nodes.arn

      min_size     = 2
      max_size     = 3
      desired_size = 3

      instance_types = [
        "t3.small"
      ]

      capacity_type = "ON_DEMAND"

      subnet_ids = aws_subnet.private[*].id
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

resource "aws_eks_cluster" "this" {
  name     = var.cluster-name
  role_arn = aws_iam_role.spark.arn
  version  = var.cluster-version

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  tags = {
    Environment = var.environment
    Terraform   = "True"
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.eks-nodes-group-name
  node_role_arn   = aws_iam_role.spark.arn

  subnet_ids = aws_subnet.private[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 2
  }

  instance_types = [
    "t3.small"
  ]

  capacity_type = "ON_DEMAND"
}
