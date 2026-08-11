# Resources for the spark history server

# pod identity role for the spark history server
resource "aws_iam_role" "spark_history_server_role" {
  name = "${var.environment}-${var.cluster_name}-spark-history-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# pod identity role policy for the spark history server
resource "aws_iam_policy" "spark_history_server_policy" {
  name = "${var.environment}-${var.cluster_name}-spark-history-server-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = ["arn:aws:s3:::${var.spark_event_logs_bucket_name}"]
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = ["arn:aws:s3:::${var.spark_event_logs_bucket_name}/*"]
      },

      {
        Sid = "KMS"

        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = "alias/spark/${var.spark_event_logs_bucket_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.spark_history_server_role.name
  policy_arn = aws_iam_policy.spark_history_server_policy.arn
}

resource "kubernetes_namespace" "spark_history" {
  metadata {
    name = "spark-history"
  }
}

resource "kubernetes_service_account" "spark_history_sa" {
  metadata {
    name      = "spark-history-sa"
    namespace = kubernetes_namespace.spark_history.metadata[0].name
  }
}

resource "aws_eks_pod_identity_association" "spark" {
  cluster_name    = module.eks.cluster_name
  namespace       = kubernetes_namespace.spark_history.metadata[0].name
  service_account = kubernetes_service_account.spark_history_sa.metadata[0].name
  role_arn        = aws_iam_role.spark_history_server_role.arn
}
