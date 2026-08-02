resource "aws_iam_group" "eks_admins" {
  name = "EKSAdmins"
  path = "/admins/"
}

resource "aws_iam_group" "spark_users" {
  name = "SparkUsers"
  path = "/users/"
}
