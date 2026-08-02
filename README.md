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
2. Deploy the service account for the AWS Load Balancer Controller.

```bash
kubectl apply -f k8s/load-balancer-controller-serviceaccount.yaml
```

3. Obtain the vpc-id of the cluster

```bash
aws eks describe-cluster \
  --name <cluster-name> \
  --region <vpc-region> \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text
```

where `<cluster-name>` and `<vpc-region>` are the cluster name and region of the cluster, see `cluster` and `region` in [the variables file](infra/variables.tf).

4. Install the AWS Load Balancer Controller using the official Helm chart.

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --version 3.4.2
  --set clusterName=<cluster-name> \
  --set region=<vpc-region> \
  --set vpcId=<vpc-id>
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

where `<vpc-id>` was obtained in step 3. The Load Balancer Controller is installed in the `kube-system` namespace which exists by default on EKS.

5. Install spark using the Spark Operator Helm chart.

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --create-namespace
  --wait
```

For an overview of the spark operator [see the architecture overview](https://spark.kubeflow.org/en/latest/overview/#architecture).
