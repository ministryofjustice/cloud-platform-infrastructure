# ECR credentials and Repository creation                                                                                                    
module "webops_ecr_credentials" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=master"

  repo_name = "cloud-platform-reference-app"
  team_name = "webops"
}
