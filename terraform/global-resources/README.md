# global-resources

These are resources that are global in nature and therefore there are no workspaces in this terraform state.

---
**NOTE**

Since resources in multiple accounts are managed here, multiple AWS providers are defined.
You can see the list of providers in [main.tf](main.tf#L10-L29), as well as the names of the AWS profiles that must be configured for this to run properly.

---
# global-resources

These are resources that are global in nature and therefore there are no workspaces in this terraform state.

---
**NOTE**

Since resources in multiple accounts are managed here, multiple AWS providers are defined.
You can see the list of providers in [guardduty.tf](guardduty.tf#L10-L29), as well as the names of the AWS profiles that must be configured for this to run properly.

---

For instructions regarding AWS GuardDuty please see [AWS GuardDuty utilising Terraform](https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/global-resources/docs/GuardDutyREADME.md)
  
