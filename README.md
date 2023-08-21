# Cloud Platform Infrastructure

## Introduction

This repository will contain all that's required to create a MoJ Cloud Platform Kubernetes cluster. The majority of this repo is made up of Terraform scripts that will be actioned by a pipeline.

Here you'll also find instruction on how to operate a MoJ Cloud Platform cluster.

## Table of contents

- [How to run Go tests](#how-to-run-go-tests)
- [How to update Go dependencies](#how-to-update-go-dependencies)
- [Terraform and Cloud Platform environment management](#terraform-and-cloud-platform-environment-management)
- [Cloud Platform environments](#cloud-platform-environments)
- [Terraform modules](#terraform-modules)
- [How to add your examples](#how-to-add-your-examples)
- [Create/Delete a cluster](#createdelete-a-cluster)

## How to run Go tests

### Prerequestites

To run `test/modsec_logging_test.go` you need to add your aws user arn to the opensearch. navigate to (opensearch dashboard)[https://logs.cloud-platform.service.justice.gov.uk/_dashboards/app/security-dashboards-plugin#/roles/edit/all_access/mapuser] -> add your user arn under trhe `users` section

### Running the tests

To run the integration tests on a MoJ Cloud Platform cluster you must have the following tools installed:
(Tool versioning is very important. I find it best to refer to the official MoJ Cloud Platform tools docker [image](https://github.com/ministryofjustice/cloud-platform-tools-image/blob/main/Dockerfile.cp-infrastructure))

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Go](https://go.dev/doc/install)
- [Ginkgo v2](https://onsi.github.io/ginkgo/#installing-ginkgo)

You can then either run:

```bash
make run-tests
```

or using Go:

```bash
go test -v ./...
```

or

```bash
cd test; ginkgo -r -v  # for realtime response
```

### Arguments

```bash
-cluster # [optional] specifies the cluster name you'd like to use. [default] current context

-kubeconfig # [optional] define where your kubeconfig file is located. [default] ~/.kube/config
```

### Running individual tests

A neat trick in Ginkgo is to place an "F" in front of the "Describe", "It" or "Context" functions. This marks it as [focused](https://onsi.github.io/ginkgo/#focused-specs).

So, if you have spec like:

```
    It("should be idempotent", func() {
```

You rewrite it as:

```
    FIt("should be idempotent", func() {
```

And it will run exactly that one spec:

```
[Fail] testing Migrate setCurrentDbVersion [It] should be idempotent
...
Ran 1 of 5 Specs in 0.003 seconds
FAIL! -- 0 Passed | 1 Failed | 0 Pending | 4 Skipped
```

### Making changes to Ginkgo tests

Ginkgo works best from the command-line, and [ginkgo watch](https://onsi.github.io/ginkgo/#watching-for-changes) makes it easy to rerun tests on the command line whenever changes are detected.

## How to update Go dependencies

With the repository cloned:

```bash
cd test; go get -u ./...
```

Perform the tests as outlined [above](#how-to-run-go-tests) and confirm they pass.

Create a PR and merge to main.

## Terraform and Cloud Platform environment management

Terraform is used to manage all AWS resources, with Terraform resources stored in the `terraform/` directory.

Terraform resources are split into four directories with matching state objects in S3, `terraform/global-resources`, `terraform/cloud-platform`, `terraform/cloud-platform-account` and `terraform/cloud-platform-components`:

- `global-resources` contains 'global' AWS resources that are not part of specific clusters or platform environments - e.g. elasticsearch and s3.
- `cloud-platform` contains resources for the Cloud Platform environments - e.g. bastion hosts.
- `cloud-platform-account` contains account specifics like cloud-trail. We decided to seperate account level Terraform and global "run once" as we're currently running from multiple AWS accounts.
- `cloud-platform-components` contains appications required to bootstrap a cluster i.e. getting a Cloud Platform cluster into a functional state.

As all four resources are defined with separate state backends, `terraform plan` and `apply` must be run separately:

```shell
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

All resources share a single S3 state bucket called `cloud-platform-terraform-state` located on the [aws-cloud-platform](https://justice-cloud-platform.eu.auth0.com/samlp/bnqndz9kxf7wDge8ndCWyVwIX1OEElYf) account. `tfstate` files however are seperated by `workspace_key_prefix` defined in each directories `main.tf` and `environment` defined by workspace.

The s3 state store structure appears as follows:

```shell
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

```hcl
data "terraform_remote_state" "global" {
  backend = "s3"
  config {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-2"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

module "cluster_dns" {
  source = "../modules/cluster_dns"

  parent_zone_id = "${data.terraform_remote_state.global.cp_zone_id}"
}
```

This structure allows us to reduce the blast radius of errors when compared to a single state store, and also allows us to separate infrastructure into multiple logical areas, with different access controls for each.

### Cloud Platform environments

[Terraform workspaces](https://www.terraform.io/docs/state/workspaces.html) are used to manage multiple instances of the `cloud-platform`, `cloud-platform-account` and `cloud-platform-components` resources. To see the workspaces/environments that currently exist:

```shell
$ terraform workspace list
* default
  cloud-platform-live-0
  cloud-platform-test-1
```

**Note:** the default workspace is not used.

To select a workspace/environment:

```shell
$ terraform workspace select cloud-platform-test-1
```

The selected Terraform workspace is [interpolated](https://www.terraform.io/docs/state/workspaces.html#current-workspace-interpolation) in Terraform resource declarations to create per-environment AWS resources, e.g.:

```hcl
locals {
    cluster_name = "${terraform.workspace}"
}
```

## Terraform modules

All `cloud-platform` resources are defined as Terraform modules, stored in `terraform/modules`, and any new resources should also be managed as modules, and imported into `terraform/cloud-platforms/main.tf`. This model allows us to encapsulate multiple resources as logical blocks, and will (later) allow us to manage and version modules separately from the main repository.

## How to add your examples

Generally speaking, follow the Ministry of Justice's [Using git](https://ministryofjustice.github.io/technical-guidance/guides/using-git/#commit-locally-regularly) guide.

### 1. Clone the repo

```shell
git clone git@github.com:ministryofjustice/cloud-platform-infrastructure.git
```

### 2. Create a branch

For example:

```shell
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

```text
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

```shell
git push origin spike/monitoring-investigation
```

and then navigating to the repo in GitHub and using the create a new pull request button.

When you do this you have the option of adding a reviewer. It's good to share your pull request for review so add a reviewer. Let the reviewer know that you are adding them so they have a chance to plan some time to do the review.

### Create/Delete a cluster

See [the runbooks site](https://runbooks.cloud-platform.service.justice.gov.uk)
