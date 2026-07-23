# AWS EKS deployment for Spark + Delta Lake

## Architecture
Kubernetes cluster accessible via ALB with identity-aware proxying and nodes in private subnets. Single NAT for low cost.

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
        NAT Gateway                   ALB node
              |                           |
              +-------------+-------------+
                            |
                     Private subnets
              +-------------+-------------+
              |                           |
       Private Subnet A            Private Subnet B
            AZ-a                         AZ-b
              |                           |
          EKS nodes                   EKS nodes
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

1. Apply the Terraform Config
2. Add the service account for the load balancer

```bash
kubectl apply -f k8s/load-balancer-controller-serviceaccount
```

3. Get the vpc-id

```bash
aws eks describe-cluster \
  --name <cluster-name> \
  --region <vpc-region> \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text
```

where `<cluster-name>` corresponds to the Terraform variable `"cluster_name"` and `<vpc-region>` corresponds to he Terraform variable `"cluster_name"` (see [the variables file](infra/variables.tf)).
Alternatively the vpc id can be obtained via the console.

4. Install the official AWS load balancer via Helm Chart

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --region <vpc-region> \
  --set serviceAccount.create=false \
  --set vpcId=<vpc-id>
  --set serviceAccount.name=aws-load-balancer-controller
```

where `<vpc-id>` was obtained in step 3.