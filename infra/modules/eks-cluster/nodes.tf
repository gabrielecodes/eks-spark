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
  cluster_name    = aws_eks_cluster.this.name
  version         = var.cluster_version
  node_group_name = "${var.environment}-${var.cluster_name}-spark-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [
    var.nodes_instance_type
  ]

  capacity_type = var.nodes_capacity_type

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

data "aws_kms_key" "spark" {
  key_id = var.kms_key_alias
}

data "aws_s3_bucket" "this" {
  for_each = toset(var.bucket_names)

  bucket = each.value
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
          "s3:ListBucket"
        ]

        Resource = [
          for bucket in data.aws_s3_bucket.this : bucket.arn
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          for bucket in data.aws_s3_bucket.this : "${bucket.arn}/*"
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

        Resource = data.aws_kms_key.spark.arn
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
    name = "spark-jobs"
  }
}

resource "kubernetes_service_account" "spark_pod" {
  metadata {
    name      = "spark-pod"
    namespace = kubernetes_namespace.spark.metadata[0].name
  }
}

resource "aws_eks_pod_identity_association" "spark" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = kubernetes_namespace.spark.metadata[0].name
  service_account = kubernetes_service_account.spark_pod.metadata[0].name

  role_arn = aws_iam_role.spark_pods_role.arn
}
