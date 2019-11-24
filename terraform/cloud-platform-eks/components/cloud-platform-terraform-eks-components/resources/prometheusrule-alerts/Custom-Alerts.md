# Custom Alarms

## Node-Disk-Space-Warning
```
Node-Disk-Space-Warning
Severity: warning
```
This alert is triggered when a node will run out of disk space in the next 6 hours at the current usage rate.

Expression:
```
expr: predict_linear(node_filesystem_free[6h], 3600 * 24) < 0
for: 30m
```
### Action

Run the following command to confirm disk shortage on a node:
`kubectl describe nodes`

You are looking for the boolean condition of:
`OutOfDiskSpace`

Please read the documentation from [Kubernetes](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type) regarding the best possible actions.

[Changing the root volume size or type](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type)
[Resize an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#resize-an-instance-group)
[Change the instance type in an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#change-the-instance-type-in-an-instance-group)

## Node-Disk-Space-Low
```
Node-Disk-Space-Low
Severity: warning
```
This alert is triggered when a node has less than 10% disk space for 30 minutes. 

Expression:
```
expr: ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes) < 10
for: 30m
```
### Action

Run the following command to confirm disk shortage on a node:
`kubectl describe nodes`

You are looking for the boolean condition of:
`OutOfDiskSpace`

Please read the documentation from [Kubernetes](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type) regarding the best possible actions.

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
expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes) * 100 > 80
for: 5m
```
### Action

Run the following to get a breakdown of memory usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentation of the [Meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)

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
expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes) * 100 > 95
for: 5m
```
### Action

Run the following to get a breakdown of memory usage:
```bash
kubectl describe node <node_name>
```
Please read the Kubernetes documentation of the [Meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)

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
expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
for: 5m
```
### Action

Run the following to get a breakdown of CPU usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentation of the [Meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu)

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
expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
for: 5m
```
### Action

Run the following to get a breakdown of CPU usage:
```bash
kubectl describe node <node_name>
```

Please read the Kubernetes documentation of the [Meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu)

You can [set CPU limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/) to pods and containers, as by default - pods run with unbounded CPU limits.

Limits can also be set on a [Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/cpu-default-namespace/)

## KubeDNSDown

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

### Action

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

```
External-DNSDown
Severity: warning
```
This alert is triggered when '0' external-dns pods are running for longer than 5 minutes.

Expression:
```
kube_deployment_status_replicas_available{deployment="external-dns"} == 0
for: 5m
```
### Action

Check if the external-dns pod is running. If so, describe the pod to check events and check the logs:

```
$ kubectl get pods -n kube-system
$ kubectl describe pod <external-dns-container> -n kube-system
$ kubectl logs <external-dns-container> -n kube-system
```

If the external-dns is not present, check the helm deployment status to see if all of the resources are running:

`$ helm status external-dns`

Check to see if the external-dns pod is running in the `kube-system` namespace:

`$ kubectl get pods -n kube-system`

## NginxIngressPodDown

```
NginxIngressPodDown
Severity: warning
```
This alert is triggered when less than 6 nginx-ingress pods are running for 5 minutes.

Expression:
```
kube_deployment_status_replicas_available{deployment="nginx-ingress-controller"} < 6
for: 5m
```

### Action

Check how many nginx-ingress pods are running. There should be at least 6 with the status `Running`.

`$ kubectl get pods -n nginx-controllers`

If a container is failing, describe the pod to check if there are any failures. If nothing is obvious, check the logs:

```
$ kubectl describe pod <nginx-ingress-container> -n nginx-controllers
$ kubectl logs <nginx-ingress-container> -n nginx-controllers
```

If the pod is missing or you think it's possible to scale up, do the following:

`$ kubectl scale --current-replicas=2 --replicas=3 deployment/nginx-ingress-controller -n nginx-controllers`

The above example shows that 2 nginx-ingress pods are running and we need 3. The command will increase the number of pods.

## NginxIngressDown

```
NginxIngressDown
Severity: critical
```

This alert is triggered when no nginx-ingress pods have been running for 5 minutes.

Expression:
```
kube_deployment_status_replicas_available{deployment="nginx-ingress-controller"} == 0
for: 5m
```

### Action

Check why the nginx-ingress pods are failing:

```
$ kubectl get pods -n nginx-controllers
$ kubectl describe pod <nginx-ingress-container> -n nginx-controllers
$ kubectl logs <nginx-ingress-container> -n nginx-controllers
```

## Root Volume Utilisation - High

```
RootVolUtilisation-High
Severity: warning
```
This alert is triggered when the root volume has 85% of the capacity used

Expression:
```
expr: (node_filesystem_size_bytes {mountpoint="/"} - node_filesystem_avail_bytes {mountpoint="/"} ) / (node_filesystem_size_bytes {mountpoint="/"} ) * 100 >85
for: 5m
```

### Action

Run the following command to get a list of nodes and confirm the node with the issue is in the expected cluster:

`$ kubectl get nodes`

`$ kubectl describe node <node_name>`

Look at the 'Conditions' Section for possible more info such as a disk space issue on the node is general and not just root.

SSH into the node and run `lsblk` and `df -h` to list the block devices attached to the instance and disk usage.

The following command can be used to search files by size to help identify/delete/backup files that may be causing the disk to fill up:

```bash
sudo find / -type f -size +100M -exec ls -lh {} \;
```

If the file system needs resizing, please follow the [offical AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html) to expand the volume

## Root Volume Utilisation - Critical

```
RootVolUtilisation-Critical
Severity: critical
```
This alert is triggered when the root volume has 95% of the capacity used

Expression:
```
expr: (node_filesystem_size_bytes {mountpoint="/"} - node_filesystem_avail_bytes {mountpoint="/"} ) / (node_filesystem_size_bytes {mountpoint="/"} ) * 100 >95
for: 1m
```

### Action

Run the following command to get a list of nodes and confirm the node with the issue is in the expected cluster:

`$ kubectl get nodes`

`$ kubectl describe node <node_name>`

Look at the 'Conditions' Section for possible more info such as a disk space issue on the node is general and not just root.

SSH into the node and run `lsblk` and `df -h` to list the block devices attached to the instance and disk usage.

The following command can be used to search files by size to help identify/delete/backup files that may be causing the disk to fill up:

```bash
sudo find / -type f -size +100M -exec ls -lh {} \;
```

If the file system needs resizing, please follow the [offical AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html) to expand the volume

## Curator Cronjob Failure

```
CuratorCronjobFailure
Severity: warning
```

This alert is triggered when the curator cronjob fails.

Expression:
```
kube_job_status_failed{job-name=~"elasticsearch-curator-cronjob.+"} > 0
for: 1h
```

### Action

Check why the curator cronjob is failing:

```
$ kubectl get cronjobs -n logging
$ kubectl describe cronjob <cronjob-name> -n logging
$ kubectl logs <cronjob-name> -n logging
```

The following links have more information on [Kubernetes Cronjobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) and [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)

## Curator Cronjob Running

```
CuratorCronJobRunning
Severity: warning
```

This alert is triggered when the curator cronjob is running longer than 1 hour

Expression:
```
time() - kube_cronjob_next_schedule_time {cronjob="elasticsearch-curator-cronjob"} > 3600
for: 1h
```

### Action

Check why the curator cronjob is running for over 1 hour:

```
$ kubectl get cronjobs -n logging
$ kubectl describe cronjob <cronjob-name> -n logging
$ kubectl logs <cronjob-name> -n logging
```

The following links have more information on [Kubernetes Cronjobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) and [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)

## Curator Job Completion

```
CuratorJobCompletion
Severity: warning
```

This alert is triggered when job completion is taking longer than 1 hour to complete curator cronjob

Expression:
```
kube_job_spec_completions - kube_job_status_succeeded {job_name=~"elasticsearch-curator-cronjob.+"} > 0      
for: 1h
```

### Action

Check why the job completion for curator cronjob is running for over 1 hour:

```
$ kubectl get cronjobs -n logging
$ kubectl describe cronjob <cronjob-name> -n logging
$ kubectl logs <cronjob-name> -n logging
```

The following links have more information on [Kubernetes Cronjobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) and [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)

## Nginx Config Reload Failure

```
NginxConfigReloadFailure
Severity: Critical
```

This alert is triggered when the nginx config fails to reload on an ingress-controller pod.

Expression:
```
nginx_ingress_controller_config_last_reload_successful == 0
```

### Action

Check why nginx config is not able to reload using the below:

The following two [`stern`](https://github.com/wercker/stern) commands can be run to confirm config is not reloading and for any errors marked as `[emerg]` which means the system is in an unusable state and requires immediate attention.

```
stern --namespace ingress-controllers nginx-ingress-acme-controller | grep "Unexpected failure reloading the backend"
stern --namespace ingress-controllers nginx-ingress-acme-controller | grep emerg
```

You can also run the following query on Kibana to check for the error:

`kubernetes.namespace_name:event-router emerg`

#### Nginx Error Log Severity Levels

The are a number of severity levels that can be defined in the error_log. The following is a list of all severity levels: 

+ debug - Useful debugging information to help determine where the problem lies.
+ info - Informational messages that aren’t necessary to read but may be good to know.
+ notice - Something normal happened that is worth noting.
+ warn - Something unexpected happened, however is not a cause for concern.
+ error - Something was unsuccessful.
+ crit - There are problems that need to be critically addressed.
+ alert - Prompt action is required.
+ emerg - The system is in an unusable state and requires immediate attention.
