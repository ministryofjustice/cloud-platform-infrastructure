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

## KubeDNSDown

## Alarm
```
KubeDNSDown 
Severity: critical
```
This alert is triggered when KubeDNS is not present on the cluster for 5 minutes

Expression:
```
absent(up{job="kube-dns"} == 1)
for: 5m
```

## Action

Run the following command to confirm kube-dns is in the cluster:

`$ kubectl get deployments -n kube-system`

`$ kubectl get pods -n kube-system`

You are looking for the `kube-dns` deployment and pod. 

If `kube-dns` pod(s) are present but failing, describe the pod to check events and check the logs:

```
$ kubectl get pods -n kube-system
$ kubectl describe pod <kube-dns-container> -n kube-system 
$ kubectl logs <kube-dns-container> -n kube-system` 
```
If the `kube-dns` pod(s) are missing, check to see if the `kube-dns` deployment is present. If the deployment is missing, apply the `kube-dns` [deployment template](https://github.com/kubernetes/kops/blob/release-1.9/upup/models/cloudup/resources/addons/kube-dns.addons.k8s.io/k8s-1.6.yaml.template) to the kube-system namespace.

Before applying, replace all templated syntax from the file with the cluster information.

`$ kubectl apply -f k8s-1.6.yaml.template -n kube-system`

**Note**: The template is for Kops 1.9.

## External-DNSDown

## Alarm
```
External-DNSDown 
Severity: warning
```
This alert is triggered when 0 external-dns pods are running for longer than 5 minutes

Expression:
```
kube_deployment_status_replicas_available{deployment="external-dns"} == 0
for: 5m
```
## Action

Check if the external-dns pod is running. If so, describe the pod to check events and check the logs:

```
$ kubectl get pods -n kube-system
$ kubectl describe pod <external-dns-container> -n kube-system
$ kubectl logs <external-dns-container> -n kube-system
```

If the external-dns is not present, check the helm deployment status to see if all of the resources are running:

`$ helm status external-dns`

If a resource is not running, either upgrade the helm deployment with the external-dns helm chart or delete the current helm deployment and reinstall:

```
$ git clone git@github.com:ministryofjustice/kubernetes-investigations.git
$ cd kubernetes-investigations
$ helm upgrade external-dns ./cluster-components/external-dns/<cluster-name>-helm-values.yaml --namespace kube-system
```

or

```
$ git clone git@github.com:ministryofjustice/kubernetes-investigations.git
$ cd kubernetes-investigations
$ helm delete --purge external-dns
$ helm install -n external-dns --namespace kube-system stable/external-dns -f ./cluster-components/external-dns/<cluster-name>-raz-helm-values.yaml
```

Check to see if the external-dns pod is running in the `kube-system` namespace:

`$ kubectl get pods -n kube-system`



