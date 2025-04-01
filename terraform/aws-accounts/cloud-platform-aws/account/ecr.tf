module "ecr_credentials" {
  source    = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=7.1.0"
  repo_name = "cloud-platform-terraform-label-pods"

  oidc_providers      = ["github"]
  github_repositories = ["cloud-platform-terraform-label-pods"]

  lifecycle_policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 30 dev and staging images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["dev", "staging"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 3,
            "description": "Keep the newest 100 images and mark the rest for expiration",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 100
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  namespace              = "cloud-platform-terraform-label-pods"
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}

module "ecr_credentials_github_teams_filter" {
  source    = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=7.1.0"
  repo_name = "cloud-platform-github-teams-filter"

  oidc_providers      = ["github"]
  github_repositories = ["cloud-platform-github-teams-filter"]

  lifecycle_policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 30 dev and staging images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["dev", "staging"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 3,
            "description": "Keep the newest 100 images and mark the rest for expiration",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 100
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name                   
  namespace              = "cloud-platform-github-teams-filter"
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}