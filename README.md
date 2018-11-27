# Cloud Platform Infrastructure

[![CircleCI](https://circleci.com/gh/ministryofjustice/cloud-platform-infrastructure.svg?style=svg)](https://circleci.com/gh/ministryofjustice/cloud-platform-infrastructure)

## Introduction
This repository will contain all that's required to create a Cloud Platform Kubernetes cluster. The majority of this repo is made up of Terraform scripts that will be actioned by a pipeline.

Here you'll also find instruction on how to operate a Cloud Platform cluster.

## Table of contents
  - [Terraform and Cloud Platform environment management](#terraform-and-cloud-platform-environment-management)
  - [Cloud Platform environments](#cloud-platform-environments)
  - [Terraform modules](#terraform-modules)
  - [How to add your examples](#how-to-add-your-examples)
  - [How to create a new cluster](#how-to-create-a-new-cluster)
  - [How to delete a cluster](#how-to-delete-a-cluster)
  - [Disaster recovery](docs/disaster-recovery/README.md)
  - [Prometheus config and install](https://github.com/ministryofjustice/cloud-platform-prometheus#cloud-platform-prometheus)
  - [Logging](docs/logging/README.md)

## Terraform and Cloud Platform environment management

Terraform is used to manage all AWS resources, except those managed by [Kops](https://github.com/kubernetes/kops/), with Terraform resources stored in the `terraform/` directory.

Terraform resources are split into four directories with matching state objects in S3, `terraform/global-resources`, `terraform/cloud-platform`, `terraform/cloud-platform-account` and `terraform/cloud-platform-components`:

- `global-resources` contains 'global' AWS resources that are not part of specific clusters or platform environments - e.g. elasticsearch and s3.
- `cloud-platform` contains resources for the Cloud Platform environments - e.g. bastion hosts and kops. 
- `cloud-platform-account` contains account specifics like cloud-trail. We decided to seperate account level Terraform and global "run once" as we're currently running from multiple AWS accounts.
- `cloud-platform-components` contains appications required to bootstrap a cluster i.e. getting a Cloud Platform cluster into a functional state.  

As all four resources are defined with separate state backends, `terraform plan` and `apply` must be run separately:

```bash
$ cd terraform/global-resources
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
$ cd ../cloud-platform
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
$ cd terraform/cloud-platform-account
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
$ cd ../cloud-platform-components
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
```

All resources share a single S3 state bucket called `cloud-platform-terraform-state` located on the [aws-cloud-platform](https://moj-cloud-platform-test-2.eu.auth0.com/samlp/WAgw4FygIHs1Vny6whAjfnem6BiUr4qv) account. `tfstate` files however are seperated by `workspace_key_prefix` defined in each directories `main.tf` and `environment` defined by workspace. 

The s3 state store structure appears as follows:

```bash
├── cloud-platform-terraform-state
    ├── cloud-platform-account/
    │   ├── cloud-platform/
    │   │   └── terraform.tfstate
    │   ├── mojdsd-platform-integration/
    │   │   └── terraform.tfstate
    ├── cloud-platform-components/
    │   ├── cloud-platform-live-0/
    │   │   └── terraform.tfstate
    │   ├── cloud-platform-test-1/
    │   │   └── terraform.tfstate
    ├── cloud-platform/
    │   ├── cloud-platform-live-0/
    │   │   └── terraform.tfstate
    │   ├── cloud-platform-test-1/
    │   │   └── terraform.tfstate
    ├── global-resources/
    │   └── terraform.tfstate
```

`cloud-platform`, and `cloud-platform-components` resources can refer to output values of other Terrform states by using the [Terraform remote state data resource](https://www.terraform.io/docs/providers/terraform/d/remote_state.html):

```bash
data "terraform_remote_state" "global" {
  backend = "s3"
  config {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

module "cluster_dns" {
  source = "../modules/cluster_dns"

  parent_zone_id = "${data.terraform_remote_state.global.k8s_zone_id}"
}
```

This structure allows us to reduce the blast radius of errors when compared to  a single state store, and also allows us to separate infrastructure into multiple logical areas, with different access controls for each.

### Cloud Platform environments

[Terraform workspaces](https://www.terraform.io/docs/state/workspaces.html) are used to manage multiple instances of the `cloud-platform`, `cloud-platform-account` and `cloud-platform-components` resources. To see the workspaces/environments that currently exist:

```bash
$ terraform workspace list
* default
  cloud-platform-live-0
  cloud-platform-test-1
```

**Note:** the default workspace is not used.

To select a workspace/environment:

```bash
$ terraform workspace select cloud-platform-test-1
```

The selected Terraform workspace is [interpolated](https://www.terraform.io/docs/state/workspaces.html#current-workspace-interpolation) in Terraform resource declarations to create per-environment AWS resources, e.g.:

```
locals {
    cluster_name = "${terraform.workspace}"
}
```

## Terraform modules

All `cloud-platform` resources are defined as Terraform modules, stored in `terraform/modules`, and any new resources should also be managed as modules, and imported into `terraform/cloud-platforms/main.tf`. This model allows us to encapsulate multiple resources as logical blocks, and will (later) allow us to manage and version modules separately from the main repository.

## How to add your examples

Generally speaking, follow the Ministry of Justice's [Using git](https://ministryofjustice.github.io/technical-guidance/guides/using-git/#commit-locally-regularly) guide.

### 1. Clone the repo

```
git clone git@github.com:ministryofjustice/cloud-platform-infrastructure.git
```

### 2. Create a branch

For example:

```
git checkout -b spike/monitoring-investigation
```

I used `spike/monitoring-investigation` as an example of a pattern for branch names. You can come up with your own branch name that matches the pattern (e.g. `feature/a-new-monitoring-stack` or `idea/deploy-using-bash-scripts`).

### 3. Add your work to the branch

Think about where to put it &mdash; perhaps in a directory with a useful name (e.g. "prometheus") and collect together similar things (e.g. put "prometheus" directory under a "monitoring" directory).

### 4. Document what you've done

Add (or add to) a `README.md` in the aforementioned folder describing the work you've done, why you've done it, how people can use it, or what it might mean.

If you need to add more documentation than seems appropriate for a readme, add a `docs` directory somewhere that makes sense, and create `.md` files with names describing what you're documenting.

### 5. Commit your code

Write a commit message that might be useful for people who come to the code to find out why you've made the change. This might be helpful: [How to write a git commit message](https://chris.beams.io/posts/git-commit/).

Here's an example:

```
Add contributing instructions

I added some instructions to the repo in a README file so that
other members of the team would know how to add code to the repo.

I aimed to make the instructions clear and simple to follow. I also
wanted to make sure that people left good context for the contributions
that they were making, so I added quite a lot about commit messages.
```

The first (subject) line should be written so that it completes the sentence "If applied, this commit will…", and not end with a full stop.

### 6. Raise a pull request

Raise a pull request by pushing your branch to the GitHub:

```
git push origin spike/monitoring-investigation
```

and then navigating to the repo in GitHub and using the create a new pull request button.

When you do this you have the option of adding a reviewer. It's good to share your pull request for review so add a reviewer. Let the reviewer know that you are adding them so they have a chance to plan some time to do the review.

### Kops

The `kops/` directory contains the cluster specification, including an additional IAM policy to allow Route53 management, and config for OIDC authentication and RBAC. To make changes, edit `kops/sandboc_cluster.yaml` and:

```
$ cd kops
$ kops replace -f test_cluster.yaml
$ kops cluster update
$ kops cluster update --yes
```

If your changes require changes to instances or launch configs, you will also need to perform a rolling update to replace instances:

```
$ kops cluster rolling-update
$ kops cluster rolling-update --yes
```

## How to create a new cluster

0. Before you begin, there are a few pre-reqs:

- You must ensure your local `helm` version is => `2.11`. Also, `helm repo update` or you might see some failures at step 6.

- The Auth0 Terraform provider isn't listed in the official Terraform repository. You must download the provider using the instructions here:
https://github.com/yieldr/terraform-provider-auth0#using-the-provider
For the auth0 provider, setup the following environment variables locally:
```
  AUTH0_DOMAIN="moj-cloud-platforms-dev.eu.auth0.com"
  AUTH0_CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  AUTH0_CLIENT_SECRET="yyyyyyyyyyyyyyyyyyyyyyyyyyyy"
```
The values are from the `terraform-provider-auth0` app

1. To create a new cluster, you must create a new terraform workspace and apply the `cloud-platform` resources. Ensure at all times that you are in the correct workspace with `$ terraform workspace list`.
```bash
$ export AWS_PROFILE=moj-pi
$ cd terraform/cloud-platform
$ terraform init
$ terraform workspace new <clusterName e.g. cloud-platform-test-3>
$ terraform plan
$ terraform apply
```
2. Set more environment variables.
```bash
$ export KOPS_STATE_STORE="s3://$(terraform output kops_state_store)"
$ export CLUSTER_NAME=$(terraform output cluster_name)
```
3. Terraform creates a `kops/${CLUSTER_NAME}.yaml` file in your local directory. K8s release should track the version supported by Kops, check https://github.com/kubernetes/kops/releases. Use `kops` to create your cluster.
```bash
$ kops create -f ../../kops/${CLUSTER_NAME}.yaml
```
4. Create SSH public key in kops state store.
```bash
$ kops create secret --name ${CLUSTER_NAME}.k8s.integration.dsd.io sshpublickey admin -i ~/.ssh/id_rsa.pub
```
5. Create cluster resources in AWS.
aka update cluster in AWS according to the yaml specification:
```bash
kops update cluster ${CLUSTER_NAME}.k8s.integration.dsd.io --yes
```
When complete (takes a few minutes), you can check the progress with:
```bash
$ kops validate cluster
```
Once it reports Your cluster `${CLUSTER_NAME}.k8s.integration.dsd.io is ready` you can proceed to use kubectl to interact with the cluster.

6. Now you need to install the `cloud-platform-components`.
```bash
$ cd ../cloud-platform-components
$ terraform init
$ terraform workspace new <clusterName e.g. cloud-platform-test-3>
$ terraform plan
$ terraform apply
```
*Warning* a failure while installing `tiller` will make `helm` downgrade itself to v2.9, and nothing will work from there, doublecheck with 
```
$ helm version
Client: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
```
fix / destroy / apply again if the values don't match.

*Warning* the kuberos app itself is not fully parametrized yet, after logging on login.apps.${CLUSTER_NAME}.k8s.integration.dsd.io the output has references to `live-0` but the other values are correct; just sed/live-0/${CLUSTER_NAME}/ before using. 

7. We haven't yet fully automated the proxies for Grafana and Prometheus so you'll need to apply the following in the `monitoring` namespace:
- Apply the [grafana-dashboard-aggregator](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/grafana-dashboard-aggregator.yaml) and the [grafana-auth-secret](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/grafana-auth-secret.yaml).
- Follow the instructions [here](https://github.com/ministryofjustice/cloud-platform-prometheus#how-to-expose-the-web-interfaces-behind-an-oidc-proxy) and apply the [oidc-proxy](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/oidc-proxy.yaml) and [secret](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/oidc-proxy-secret.yaml) for Prometheus/AlertManager.

### How to delete a cluster

1. To delete a cluster you must first export the following:
```
$ export AWS_PROFILE=moj-pi
$ export KOPS_STATE_STORE=s3://moj-cp-k8s-investigation-kops
```
2. After changing directory, run the following command which will destroy all cluster components.
```bash
$ cd terraform/cloud-platform-components
$ terraform init
$ terraform workspace select <clusterName e.g. cloud-platform-test-3>
$ terraform destroy
```
3. Then run the following `kops` command (this will not delete the cluster). Append it with `--yes` to confirm deletion.
```
$ kops delete cluster --name <clusterName>
```
4. Change directories and perform the following, destroying the cluster essentials.
```bash
$ cd ../cloud-platform
$ terraform init
$ terraform workspace select <clusterName e.g. cloud-platform-test-3>
$ terraform destroy
```
5. Additional cleanup (optional): ensure all references to `<clusterName>` are gone from `KOPS_STATE_STORE`, `terraform workspace delete <clusterName>`
