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

2. Create the service account for the spark pods and attach permissions

```bash
kubectl apply -f k8s/spark-apps/spark-pods-sa.yaml
```

3. Install spark using the Spark Operator Helm chart.

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm install <release> spark-operator/spark-operator \
  --namespace spark-operator \
  --set spark.jobNamespaces[0]=spark-jobs \
  --create-namespace \
  --wait
```

You can add multiple job namespaces adding multiple `--set spark.jobNamespaces[i]=<namespace>` statements (where `i` is a progressive index).

4. Install the kube prometheus stack

```bash
helm upgrade --install <release> \
  oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --version 88.1.5 \
  --namespace monitoring \
  --create-namespace \
  -f ./prometheus/values.yaml
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
             ┌───────────────┐
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


### JVM

| metric                  | definition                                         | meaning             |
|-------------------------|----------------------------------------------------|---------------------|
| JVM heap utilization    | 100 * metrics_executor_JVM_heap_used / metrics_executor_JVM_heap_max | JVM's memory usage  |
| GC Overhead Ratio (%)   | 100 * (rate(metrics_executor_jvmGCTime_total[5m]) / 1000 ) / rate(metrics_executor_executorRunTime_total[5m]) | Proportion of runtime spent inside garbage collection pauses |
| Old Gen Pool Usage      | metrics_executor_JVM_pools_G1_Old_Gen_usage or metrics_executor_JVM_pools_PS_Old_Gen_usage | Tracks long-lived memory accumulation |
| Memory Spill Rate (Bytes/sec) | rate(metrics_executor_memoryBytesSpilled_total[5m]) | Tracks execution memory (joins/sorts/aggregations) overflowing to disk |
| Storage Memory Usage (Bytes) | metrics_executor_storageMemory | Measures memory consumed by cached DataFrames/RDDs |
| Off-Heap / Non-Heap Memory Used (Bytes) | metrics_executor_JVM_non_heap_used | Tracks native allocations, JVM Metaspace, and Netty network buffers outside the managed Java heap.

### Spark

- Driver heap utilization
- Driver post-GC heap
- Executor GC time / executor run time
- Executor shuffle read
- Executor shuffle write
- Executor peak execution memory / spills

- Disk spill
- Memory spill
- Shuffle read/write
- Executor/task failures

---

## TODO

- test new spark image
- test prom ebs volume
- test delta
- write a SparkAppliaction manifest Template

driver metrics:

- jvm_heap_used
- jvm_heap_max
- jvm_pools_*_used_after_gc
- jvm_non_heap_used

executor metrics:

- executor_totalGCTime_seconds_total
- executor_totalDuration_seconds_total
- executor_totalShuffleRead_bytes_total
- executor_totalShuffleWrite_bytes_total
- executor_totalInputBytes_bytes_total
- executor_failedTasks
- executor_activeTasks