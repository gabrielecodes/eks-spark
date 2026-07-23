resource "aws_vpc" "main" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.vpc-name
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.vpc-name}-igw"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public-subnets-cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public-subnets-cidrs[count.index]
  availability_zone       = var.vpc-azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.vpc-name}-public-${count.index + 1}"
    Environment                                 = var.environment
    Terraform                                   = "true"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name        = "${var.vpc-name}-nat-eip"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name        = "${var.vpc-name}-nat"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private-subnets-cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private-subnets-cidrs[count.index]
  availability_zone = var.vpc-azs[count.index]

  tags = {
    Name                                        = "${var.vpc-name}-private-${count.index + 1}"
    Environment                                 = var.environment
    Terraform                                   = "true"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "${var.vpc-name}-public-rt"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.vpc-name}-private-rt"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
