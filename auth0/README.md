# Auth0 authentication for Kuberos

Prerequisites:
1. A Tenant created on https://manage.auth0.com, EU region (use GH creds to login)
   ![tenant](tenant.png)
   No Applications (aka Clients) / Connections / Rules must exist initially, delete any defaults (TF cannot handle this yet)
1. A single ["Machine to Machine"](https://auth0.com/docs/applications/machine-to-machine) Application, granting it access to the Management API, all scopes. Ensure this app's "Client Secret" is kept safe as it allows the editing of authentication rules for the target app; a "rotate" option is available.
  ![m2m app](tf.png)
1. A k8s cluster, see [../kops/](../kops/) folder for existing ones, copy the live-0 yaml, commit to master and check pipeline output in [Circle](https://circleci.com/gh/ministryofjustice/kubernetes-investigations)
1. An **org-owned** [GH Oauth app](https://auth0.com/docs/connections/social/github), callback URL pointing to https://<tenant-name>.eu.auth0.com/login/callback
1. A "Social Connection" of type Github, using the credentials above and with read:org and read:user privs. The app can only have one instance named "github", any additional ones of the same type created via terraform or curl will not show up in the web interface.
1. Terraform and the [Yieldr Auth0 provider](https://github.com/yieldr/terraform-provider-auth0)

Steps:
1. Edit credentials.tf, add tenant domain, id and secret from the M2M App created above
1. `terraform plan && terraform apply`
