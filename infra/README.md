# AWS EKS deployment for Spark + Delta Lake

## Architecture
Kubernetes cluster accessible via ALB and nodes in a private subnet.

```text             
              Internet
                  |
            Public Subnet
                  |
      AWS Application Load Balancer     
                  |                       public internet
------------------------------------------------ 
                  |
          Kubernetes Service
                  |
   +---------------------------------+
   |            EKS Cluster          |
   |                                 |
   |   Private Subnets               |
   |   +-------------------------+   |
   |   | Managed Node Group      |   |
   |   | EC2 Worker Nodes        |   |
   |   +-------------------------+   |
   |                                 |
   |   NAT Gateway                   |
   +---------------------------------+
                  |
           Internet Gateway
```

The EKS cluster and related infrastructure is provisioned via terraform. The provisioned resources are:

- VPC
- EKS cluster
- Node group
- Pod Identity
- Spark IAM role & permissions
- S3 Bucket
- KMS Key
- Security Groups
- Add-ons

Kubernetes manages the following resources:

- Spark Namespace
- Service Account for the pods
- AWS Load Balancer Controller
- Ingress

Resources automatically created by AWS:

- Application Load Balancer
- Target Group
- Listeners
- Listener Rules

## Identities and Permissions

Kubernetes objects:
- Pod Service Account
- Pod Identity Association

with permissions:
- S3
- KMS
- Logs

AWS Role:
- Spark Role (called `spark-workload-role`, see the `aws_iam_role.spark` resource) associated to the spark pods