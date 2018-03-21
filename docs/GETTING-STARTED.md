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
## Creating and Switching to the correct Context

Once you have confirmed that you are authenticated and connected to the Cluster, you will need to go ahead and create a context.

Contexts are used by Kubernetes to allow you to easily switch between namespaces. Initially you will be pointed at the default context/namespace.

The context that you have been given privileges for is 'laa-fee-calculator-dev'.

To create this context run the command below, making sure to insert your GitHub email address:
```
kubectl config set-context laa-fee-calculator-dev --cluster non-production.k8s.integration.dsd.io --user="INSERT_GITHUB_EMAIL"
```

To switch to this context:
```
kubectl config use-context laa-fee-calculator-dev
```
Confirm you have successfully switched context and privileges have been applied correctly:
```
kubectl get services
```
