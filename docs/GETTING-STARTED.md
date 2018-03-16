# Deploying to Kubernetes Clusters

## Install Kubernetes CLI

The Kubernetes CLI is required to interact with clusters:
```
brew install kubectl
```
Confirm installation:
```
kubectl version
```

## Authenticating with the Cluster

Follow the URL and when prompted, connect your GitHub account with Kuberos: [Kuberos Link](http://login.apps.non-production.k8s.integration.dsd.io)

Follow the instruction to save the provided config file in the specified location.

*Note: If you've already authenticated with another cluster, then you should follow the 'Authenticate Manually' steps.*

You can then confirm the authentication with the cluster:
```
kubectl config get-contexts
```
or
```
kubectl get ing
```
