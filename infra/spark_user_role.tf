# data "aws_caller_identity" "current" {}

# for principal use var.account_id or data.aws_called_identity.current.account_id
resource "aws_iam_role" "spark_user" {
  name = "SparkUser"

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

resource "aws_iam_policy" "spark_user_policy" {
  name = "SparkUserRolePolicy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

# allow members of the group to assume the SparkUser role
resource "aws_iam_policy" "assume_spark_user" {
  name = "AssumeSparkUser"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AssumeSparkUser"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.spark_user.arn
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "spark_users" {
  group      = aws_iam_group.spark_users.name
  policy_arn = aws_iam_policy.spark_user_policy.arn
}

resource "aws_iam_role_policy_attachment" "spark_user_eks" {
  role       = aws_iam_role.spark_user.name
  policy_arn = aws_iam_policy.assume_spark_user.arn
}

resource "aws_eks_access_entry" "spark_user" {
  cluster_name      = module.eks.cluster_arn
  principal_arn     = aws_iam_role.spark_user.arn
  kubernetes_groups = ["spark-users"]
}
