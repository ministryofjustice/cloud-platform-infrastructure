# Custom Alarms

## Node-Disk-Space-Low
```
Node-Disk-Space-Low
Severity: warning
```

### Observation
Run the following command to confirm disk shortage on a node:
`kubectl describe nodes`

You are looking for the boolean condition of:
`OutOfDiskSpace`

### Action
Please read the documentation from [Kubernetes](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type) regarding best possible actions.

[Changing the root volume size or type](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type)
[Resize an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#resize-an-instance-group)
[Change the instance type in an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#change-the-instance-type-in-an-instance-group)

## Memory-High
```
Memory-High
Severity: warning
```
This alert is triggered when the memory usage is at or over 95% for 5 minutes

Expression:
```
expr: (node_memory_MemTotal - node_memory_MemAvailable) / (node_memory_MemTotal) * 100 > 80
for: 5m
```
### Action

Run the following to get a breakdown of memory usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentaion of the [Meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)

You can [set Memory limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/) to pods and containers, as by default - pods run with unbounded memory limits.

Limits can also be set on a [Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)

## Memory-Critical
```
Memory-Critical
Severity: critical
```
This alert is triggered when the memory usage is at or over 95% for 5 minutes

Expression:
```
expr: (node_memory_MemTotal - node_memory_MemAvailable) / (node_memory_MemTotal) * 100 > 95
for: 5m
```
### Action

Run the following to get a breakdown of memory usage:
```bash
kubectl describe node <node_name>
```
Please read the Kubernetes documentaion of the [Meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)

You can [set Memory limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/) to pods and containers, as by default - pods run with unbounded memory limits.

Limits can also be set on a [Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)

## CPU-High
```
CPU-High
Severity: warning
```
This alert is triggered when the CPU for a node is running at or over 80% for 5 minutes

Expression:
```
expr: 100 - (avg by(instance) (irate(node_cpu{mode="idle"}[5m])) * 100) > 80
for: 5m
```
### Action

Run the following to get a breakdown of CPU usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentaion of the [Meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu)

You can [set CPU limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/) to pods and containers, as by default - pods run with unbounded CPU limits.

Limits can also be set on a [Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/cpu-default-namespace/)


## CPU-Critical
```
CPU-Critical
Severity: critical
```
This alert is triggered when the CPU for a node is running at or over 95% for 5 minutes

Expression:
```
expr: 100 - (avg by(instance) (irate(node_cpu{mode="idle"}[5m])) * 100) > 95
for: 5m
```
### Action

Run the following to get a breakdown of CPU usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentaion of the [Meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) 

You can [set CPU limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/) to pods and containers, as by default - pods run with unbounded CPU limits.

Limits can also be set on a [Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/cpu-default-namespace/)
