# Cloud Platform Prometheus

This repository will allow you to create a monitoring namespace in a MoJ Cloud Platform cluster. It will also contain the neseccary values to perform an installation of Prometheus-Operator and Kube-Prometheus. 

  - [Pre-reqs](#prereq)
  - [Creating a monitoring namespace](#installation)
  - [Installing Prometheus-Operator](#output-example)
  - [Installng Kube-Prometheus](#usage)
  - [Exposing the port](#features-and-advantages-of-this-project)  
  - [How to tear it all down](#am-i-missing-some-essential-feature)
  - [Contributing](#contributing)

```
TL;DR
# Copy ./monitoring dir to the namespace dir in the cloud-platform-environments repository.

# Add CoreOS Helm repo
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

# Install prometheus-operator
$ helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring -f ./helm/prometheus-operator/values.yaml

# Install kube-prometheus
$ helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring -f ./helm/kube-prometheus/values.yaml

# Expose the Prometheus port to your localhost
$ kubectl port-forward -n monitoring prometheus-kube-prometheus-0 9090
```

## Pre-reqs
It is assumed that you have authenticated to an MoJ Cloud-Platform Cluster and you have Helm installed and configured.

## Creating a monitoring namespace
To create a monitoring namespace you will need to copy the `./monitoring` directory in this repository to a branch in the [Cloud-Plarform-Environments](https://github.com/ministryofjustice/cloud-platform-environments/tree/master/namespaces). Once this branch has been reviewed and merged to `master` a pipeline is kicked off, creating a namespace called `monitoring`. 

## Installing Prometheus-Operator
> The mission of the Prometheus Operator is to make running Prometheus
> on top of Kubernetes as easy as possible, while preserving
> configurability as well as making the configuration Kubernetes native.
> [https://coreos.com/operators/prometheus/docs/latest/user-guides/getting-started.html](https://coreos.com/operators/prometheus/docs/latest/user-guides/getting-started.html)

The Prometheus Operator provides easy monitoring for Kubernetes services and deployments besides managing Prometheus, Alertmanager and Grafana configuration.

To install Prometheus Operator, run:
```
$ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

$ helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring -f ./monitoring/helm/prometheus-operator/values.yaml
```
And then confirm the operator is running in the monitoring namspace:
```
$ kubectl get pods -n monitoring
```

## Installing Kube-Prometheus
Prometheus is an open source toolkit to monitor and alert, inspired by Google Borg Monitor. It was previously developed by SoundCloud and afterwards donated to the CNCF.

To install kube-prometheus, run:
```
$ helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring -f ./monitoring/helm/kube-prometheus/values.yaml
```
## Exposing the port
Due to a lack of auth options, we've decided to use port forwarding to prevent unauthorised access. Forward the Prometheus server to your machine so you can take a better look at the dashboard by opening http://localhost:9090.
```
$ kubectl port-forward -n monitoring prometheus-kube-prometheus-0 9090
```
## How to tear it all down
If you need to uninstall kube-prometheus and the prometheus-operator then you will simple need to run the following:
```
$ helm del --purge kube-prometheus && helm del --purge prometheus-operator
```
