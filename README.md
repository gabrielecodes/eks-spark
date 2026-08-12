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

The AWS Load Balancer Controller is deployed to the Kubernetes installing its helm chart (see [main.tf](./infra/main.tf)).

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

spark-pods-role
    |
    +-- S3
    +-- CloudWatch
    +-- KMS

spark-history-server-role
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

helm install <release> spark-operator/spark-operator \
  --namespace spark-operator \
  --set spark.jobNamespaces[0]=spark-jobs \
  --create-namespace
  --wait
```

You can add multiple job namespaces adding multiple `--set spark.jobNamespaces[i]=<namespace>` statements (where `i` is a progressive index).

3. Install the kube prometheus stack

```bash
kubectl create namespace monitoring

helm install <release> oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --version 88.1.5 \
  --namespace monitoring \
  --create-namespace \
  --set serviceMonitorSelectorNilUsesHelmValues=false \
  --set podMonitorSelectorNilUsesHelmValues=false
```

4. Create the service account for the spark pods and attach permissions

```bash
kubectl apply -f k8s/spark-apps/spark-pods-sa.yaml
```

For an overview of the spark operator [see the architecture overview](https://spark.kubeflow.org/en/latest/overview/#architecture).


## Cluster Metrics

```
             ┌───────────────┐
             │    Grafana    │
             └───────┬───────┘
                     │
              PromQL queries
                     │
             ┌───────▼───────┐
             │   Prometheus  │
             └───────┬───────┘
                     │
          ┌──────────┴──────────┐
          │                     │
     Spark metrics       Kubernetes metrics
          │                     │
    Driver/Executors       Nodes/Pods
```

### Kubernetes

Kubernetes monitoring is provided by default dashboard available in grafana installed with the kube-prometheus-stack. Metrics to look at:

- Node health
- CPU
- Memory
- Pod count
- Pending pods
- OOMs
- Evictions
- Network/disk
- Spark applications

### Spark Applications

*Driver*:
- restarts
- cpu usage, request, limit
- memory working set, request, limit
- JVM heap used, heap committed, max
- GC time/rate
- off-heap memory