# Node-Disk-Space-Low

## Alarm
```
Node-Disk-Space-Low
```

## Observation
Run the following command to confirm disk shortage on a node:
`kubectl describe nodes`

You are looking for the boolean condition of:
`OutOfDiskSpace`

## Action
Please read the documentation from [Kubernetes](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type) regarding best possible actions.

[Changing the root volume size or type](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#changing-the-root-volume-size-or-type)
[Resize an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#resize-an-instance-group)
[Change the instance type in an instance group](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#change-the-instance-type-in-an-instance-group)