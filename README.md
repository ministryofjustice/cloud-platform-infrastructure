# Kubernetes Investigations

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
  cloud-platforms-sandbox
  non-production
```

**Note:** the default workspace is not used.

To select a workspace/environment:

```
$ terraform workspace select cloud-platforms-sandbox
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

## Sandbox Cluster

A sandbox cluster for experimentation has been created - `cloud-platforms-sandbox.k8s.integration.dsd.io` - using Terraform and Kops.

### Kops

The `kops/` directory contains the cluster specification, including an additional IAM policy to allow Route53 management, and config for OIDC authentication and RBAC. To make changes, edit `kops/sandboc_cluster.yaml` and:

```
$ cd kops
$ kops replace -f sandbox_cluster.yaml
$ kops cluster update
$ kops cluster update --yes
```

If your changes require changes to instances or launch configs, you will also need to perform a rolling update to replace instances:

```
$ kops cluster rolling-update
$ kops cluster rolling-update --yes
```

## How to create a new cluster

1. To create a new cluster, you must create a new terraform workspace and apply the `cloud-platform` resources:
```
$ cd terraform/cloud-platform
$ terraform init
$ terraform workspace new my-new-env-name
$ terraform plan
$ terraform apply
```
2. Set environment variables.
``` 
$ export AWS_PROFILE=mojds-platforms-integration
$ export KOPS_STATE_STORE=s3://moj-cp-k8s-investigation-kops
$ export CLUSTER_NAME=<clusterName>
```
3. Create a cluster configuration file in the kops directory `kops/CLUSTER_NAME.yaml`, ensuring you define your cluster name, new hosted zone and state store in the file. (I recommend copying an existing file in this folder and amending specifics)

4. Create cluster specification in kops state store.
```
$ kops create -f ${CLUSTER_NAME}.yaml
```
5. Create SSH public key in kops state store.
```
$ kops create secret --name ${CLUSTER_NAME}.integration.dsd.io sshpublickey admin -i ssh/${CLUSTER_NAME}_kops_id_rsa.pub
```
6. Create cluster resources in AWS.
aka update cluster in AWS according to the yaml specification:
```
$ kops update cluster ${CLUSTER_NAME}.integration.dsd.io --yes
```
When complete (takes a few minutes), you can check the progress with:
```
$ kops validate cluster
```
Once it reports Your cluster `${CLUSTER_NAME}.integration.dsd.io is ready` you can proceed to use kubectl to interact with the cluster.

### How to delete a cluster

1. To delete a cluster you must first export the following:
```
$ export AWS_PROFILE=mojds-platforms-integration
$ export KOPS_STATE_STORE=s3://moj-cp-k8s-investigation-kops
```
2. Then run the following command (this will not delete the cluster).
```
$ kops delete cluster --name <clusterName>
```
3. Confirm you would like to delete the cluster with a --yes.
```
$ kops delete cluster --name <clusterName>
```
This takes a while but will eventually delete.

### Cluster creation pipeline

As part of the MVE project we developed an automated way of creating new clusters. The flow used is the following:

1. A user creates a subset yaml file for the cluster definition in this repo, under the kops/ directory. The name of the yaml file will be the clusters resulting name.

2. Once this change is merged to master, an automated pipeline is triggered. This pipeline lives in AWS CodePipeline/CodeBuild. This pipeline will create the terraform workspace (if it does not exist), create the underlying terraform elements, such as the vpc and networking parts, apply those, and then based on the outputs of those terraform resources, run kops to create the cluster. The end result of this process will be a cluster, and its properties will be defined in the initial yaml file.

3. A notification for Success of Failure will be automatically pushed to the slack channel 'cp-build-notification'. The pipeline will notify Success once the cluster is ready and all its resources are healthy.

#### Parts that compose this project

1. The pipeline: The pipeline is based on AWS CodePipeline/Codebuild. It is triggered automatically after a change is promoted to master. The pipeline can be managed with the terraform templates that live in the ```cluster-pipeline/terraform``` directory. The pipeline will execute what ever is defined in ```cluster-pipeline/buildspec.yaml```

2. The scripts: The pipeline uses the scripts that live in ```bin/```. The initial script that is triggered is ```bin/create_clusters.py```. This script will determine what clusters need to be created, based on the yaml files located in ```kops/```, the terraform workspaces, and the live clusters, getting that list via kops. It will create as many clusters you define that are not properly alive.
For each cluster that needs to be created it will trigger the ```bin/create_cluster.sh``` script. This script will create the terraform workspace if it does not exist, create the networking parts based on the terraform templates for that workspace, create the ssh keys, and then run the ```bin/create_cluster_config.py``` script. This script will expand the subset yaml configuration defined in ```kops/``` with terraform outputs to create the full cluster spec. Back with ```bin/create_cluster.sh```, once the full yaml spec has been obtained, it will run kops against that yaml file to create the actual cluster, and wait for completion.
Any issue in this process will result in a broken build but the partially created resources will not be destroyed.

3. This is a work in progress, works for now but requires extensive testing and improvement before it is production ready. Hope you find this wonderful.
