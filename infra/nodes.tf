# Role for nodes
resource "aws_iam_role" "nodes" {
  name = "${var.environment}-${var.cluster_name}-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_eks_node_group" "default" {
  cluster_name    = var.cluster_name
  version         = var.cluster_version
  node_group_name = "${var.environment}-${var.cluster_name}-spark-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = aws_subnet.private[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [
    var.instance_type
  ]

  capacity_type = var.capacity_type

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]

  labels = { role = "spark" }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# pod identity role
resource "aws_iam_role" "spark_pods_role" {
  name = "${var.environment}-${var.cluster_name}-spark-pods-role"

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

resource "aws_iam_policy" "spark_pods_policy" {
  name = "${var.environment}-${var.cluster_name}-spark-pods-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          "${aws_s3_bucket.spark_workflows.arn}/*"
        ]
      },

      {
        Sid = "CloudWatchLogs"

        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      },

      {
        Sid = "KMS"

        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]

        Resource = aws_kms_key.spark.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pods_policy" {
  role       = aws_iam_role.spark_pods_role.name
  policy_arn = aws_iam_policy.spark_pods_policy.arn
}

resource "kubernetes_namespace" "spark" {
  metadata {
    name = "spark"
  }
}

resource "kubernetes_service_account" "spark_pod" {
  metadata {
    name      = "spark-pod"
    namespace = kubernetes_namespace.spark.metadata[0].name
  }
}

resource "aws_eks_pod_identity_association" "spark" {
  cluster_name    = module.eks.cluster_name
  namespace       = kubernetes_namespace.spark.metadata[0].name
  service_account = kubernetes_service_account.spark_pod.metadata[0].name

  role_arn = aws_iam_role.spark_pods_role.arn
}
