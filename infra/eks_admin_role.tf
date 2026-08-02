# data "aws_caller_identity" "current" {}


# for principal use var.account_id or data.aws_called_identity.current.account_id
resource "aws_iam_role" "eks_admin" {
  name = "EKSAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" : "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

# allow group members to assume eks_admin role
resource "aws_iam_policy" "admin_policy" {
  name = "EKSAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
        ]
        Resource = aws_eks_cluster.this.arn
      }
    ]
  })
}

# allow group members to assume eks_admin role
resource "aws_iam_policy" "assume_eks_admin" {
  name = "AssumeEKSAdmin"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AssumeEKSAdmin"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.eks_admin.arn
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "name" {
  group      = aws_iam_group.eks_admins.name
  policy_arn = aws_iam_policy.assume_eks_admin.arn
}

# use managed policy to allow admins to administer cluster
resource "aws_iam_role_policy_attachment" "spark_admin_eks" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["eks-admins"]
}
