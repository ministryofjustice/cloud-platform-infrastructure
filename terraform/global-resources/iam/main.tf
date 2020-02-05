terraform {
  backend "s3" {
    bucket = "cloud-platform-terraform-state"
    region = "eu-west-1"
    key    = "global-resources/iam/terraform.tfstate"
  }
}

###############
# AWS Account #
###############

module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 2.0"

  account_alias = "cloud-platform-aws"

  minimum_password_length = 6
}


# CP Team
module "iam_group_admins_with_policies" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 2.0"

  name = "admins"

  group_users = [
    module.iam_user_alejandro_garrido.this_iam_user_name,
    module.iam_user_poornimakrishnasamy.this_iam_user_name,
    module.iam_user_paulwyborn.this_iam_user_name,
    module.iam_user_kops.this_iam_user_name,
    module.iam_user_mouradtrabelsi.this_iam_user_name,
    module.iam_user_davidsalgado.this_iam_user_name,
    module.iam_user_sablumiah.this_iam_user_name,
    module.iam_user_jasonbirchall.this_iam_user_name,
    module.iam_user_vijayveeranki.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}

module "iam_user_alejandro_garrido" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "AlejandroGarrido"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_poornimakrishnasamy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "poornimakrishnasamy"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}
module "iam_user_paulwyborn" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "paulwyborn"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_kops" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "kops"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_mouradtrabelsi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "MouradTrabelsi"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_davidsalgado" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "DavidSalgado"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_sablumiah" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "SabluMiah"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_jasonbirchall" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "jasonBirchall"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user_vijayveeranki" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name                          = "VijayVeeranki"
  force_destroy                 = true
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}
