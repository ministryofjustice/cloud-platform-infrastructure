# Kubernetes Investigations

  - [Overview](#kubernetes-investigations)
  - [Terraform and Cloud Platform environment management](#terraform-and-cloud-platform-environment-management)
  - [Cloud Platform environments](#cloud-platform-environments)
  - [Terraform modules](#terraform-modules)
  - [How to add your examples](#how-to-add-your-examples)
  - [How to create a new cluster](#how-to-create-a-new-cluster)
  - [How to delete a cluster](#how-to-delete-a-cluster)
  - [Cluster creation pipeline](#cluster-creation-pipeline)
  - [Disaster recovery](docs/disaster-recovery/README.md)
  - [Prometheus config and install](https://github.com/ministryofjustice/cloud-platform-prometheus#cloud-platform-prometheus)
  - [Logging](docs/logging/README.md)

A space to collect code related to the cloud platform team's Kubernetes investigations.

As we complete spikes or investigations into how we want to run Kubernetes we can collect useful code that we have written here so that it is available to the team.

We will also document some of the thinking behind how the code is written so that it is available to people who are new to the team or ourselves when we forget why we are doing it.

## Terraform and Cloud Platform environment management

Terraform is used to manage all AWS resources, except those managed by [Kops](https://github.com/kubernetes/kops/), with Terraform resources stored in the `terraform/` directory.

Terraform resources are split into two directories with matching state objects in S3, `terraform/global-resources` and `terraform/cloud-platform`:

- `global-resources` contains 'global' AWS resources that are not part of specific clusters or platform environments - e.g. parent DNS zone, S3 buckets for Kops and Terraform state storage for `cloud-platform` environments
- `cloud-platform` contains resources for the Cloud Platform environments - cluster DNS, and ACM certificates with DNS validation, and soon VPC, subnets etc

As 'global' and 'platform' resources are defined with separate state backends, `terraform plan` and `apply` must be run separately:

```
$ cd terraform/global-resources
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
$ cd ../cloud-platform
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
...
```

`cloud-platform` resources can refer to output values of `global-resources` by using the [Terraform remote state data resource](https://www.terraform.io/docs/providers/terraform/d/remote_state.html):

```
data "terraform_remote_state" "global" {
    backend = "s3"
    config {
        bucket = "moj-cp-k8s-investigation-global-terraform"
        region = "eu-west-1"
        key = "terraform.tfstate"
    }
}

module "cluster_dns" {
    source = "../modules/cluster_dns"

    parent_zone_id = "${data.terraform_remote_state.global.k8s_zone_id}"
}
```

This structure allows us to reduce the blast radius of errors when compared to  a single state store, and also allows us to separate infrastructure into multiple logical areas, with different access controls for each.

### Cloud Platform environments

[Terraform workspaces](https://www.terraform.io/docs/state/workspaces.html) are used to manage multiple instance of the `cloud-platform` resources. To see the workspaces/environments that currently exist:

```
$ terraform workspace list
* default
  non-production
```

**Note:** the default workspace is not used.

To select a workspace/environment:

```
$ terraform workspace select cloud-platforms-test
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
git clone git@github.com:ministryofjustice/kubernetes-investigations.git
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

If you can't find anyone add Kerin or Kalbir.

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

- You must ensure your local `helm` version is => `2.11`.

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
$ export AWS_PROFILE=mojds-platforms-integration
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

7. We haven't yet fully automated the proxies for Grafana and Prometheus so you'll need to apply the following in the `monitoring` namespace:
- Apply the [grafana-dashboard-aggregator](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/grafana-dashboard-aggregator.yaml) and the [grafana-auth-secret](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/grafana-auth-secret.yaml).
- Follow the instructions [here](https://github.com/ministryofjustice/cloud-platform-prometheus#how-to-expose-the-web-interfaces-behind-an-oidc-proxy) and apply the [oidc-proxy](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/oidc-proxy.yaml) and [secret](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/oidc-proxy-secret.yaml) for Prometheus/AlertManager.

### How to delete a cluster

1. To delete a cluster you must first export the following:
```
$ export AWS_PROFILE=mojds-platforms-integration
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
