# KubeDNS-Down

## Alarm
```
KubeDNS-Down 
```

## Observation
Run the following command to confirm kube-dns is in the cluster:

`$ kubectl get deployments -n kube-system`

`$ kubectl get pods -n kube-system`

You are looking for the `kube-dns` deployment and pod. 

## Action

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

