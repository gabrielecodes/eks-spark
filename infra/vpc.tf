module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.eks-vpc-name
  cidr = var.eks-vpc-cidr

  azs = var.vpc-azs

  public_subnets = var.public-subnets-cidrs

  private_subnets = var.private-subnets-cidrs

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
