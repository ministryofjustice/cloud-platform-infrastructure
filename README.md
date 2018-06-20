# Cloud-Platform Prometheus
==================
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
# Copy dir to your namespace in the cloud-platform-environments repository.

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


## Installing Prometheus-Operator
## Installing Kube-Prometheus
## Exposing the port
## How to tear it all down

Necessary configuration to initiate a monitoring namespace in an MoJ Cloud Platform. 
