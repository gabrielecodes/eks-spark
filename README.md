# AWS EKS deployment for Spark + Delta Lake

## Architecture

Kubernetes cluster running on Amazon EKS with worker nodes in private subnets. Applications are exposed through an internet-facing Application Load Balancer (ALB) managed by the AWS Load Balancer Controller. Access is protected using an identity-aware proxy. A single NAT Gateway is used to minimize infrastructure cost.

```text
                         Internet
                            |
                    Internet Gateway
                            |
              +-------------+-------------+
              |                           |
       Public Subnet A              Public Subnet B
            AZ-a                        AZ-b
              |                           |
        NAT Gateway         Application Load Balancer
              |              (provisioned by controller)
              +-------------+-------------+
                            |
                     Private subnets
                            |
              +-------------+-------------+
              |                           |
       Private Subnet A            Private Subnet B
            AZ-a                         AZ-b
              |                           |
          EKS nodes                   EKS nodes
```

The EKS infrastructure is provisioned using Terraform. The provisioned AWS resources include:

- VPC
- Amazon EKS cluster
- Managed node group
- EKS Pod Identity
- IAM role and permissions for Spark workloads
- Amazon S3 bucket
- AWS KMS key
- Security groups
- EKS add-ons

The AWS Load Balancer Controller is deployed to the Kubernetes cluster using Kubernetes manifests. It provisions and manages the Application Load Balancer (ALB) based on Kubernetes Ingress resources.

## Identities and Permissions

```
EKS Cluster Role
    |
    +-- AmazonEKSClusterPolicy

EC2 Node Role
    |
    +-- AmazonEKSWorkerNodePolicy
    +-- AmazonEKS_CNI_Policy
    +-- AmazonEC2ContainerRegistryReadOnly

AWSLoadBalancerControllerRole
    |
    +-- AWSLoadBalancerControllerIAMPolicy

SparkPodRole
    |
    +-- S3
    +-- CloudWatch
    +-- KMS
```

## Installation

1. Apply the Terraform configuration to provision the EKS cluster and supporting AWS infrastructure.

2. Install spark using the Spark Operator Helm chart.

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --set spark.jobNamespaces[0]=spark \
  --create-namespace  \
  --wait
```

You can add multiple job namespaces adding multiple `--set spark.jobNamespaces[i]=<namespace>` statements (where `i` is a progressive index).

3. install the kube prometheus stack

```bash
helm install <release_name> oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --version 88.1.5 \
  --namespace monitoring \
  --create-namespace
```

For an overview of the spark operator [see the architecture overview](https://spark.kubeflow.org/en/latest/overview/#architecture).
