# CloudFront Cortex XSIAM logging bucket 
module "cloudfront_cortex_logs" {
  source                 = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=5.3.0"
  team_name              = var.team_name
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
  namespace              = "cloud-platofrom-infrastructure"
  versioning             = var.versioning
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_cortex_logs" {
  depends_on = [module.cloudfront_cortex_logs]
  bucket = module.cloudfront_cortex_logs.bucket_name
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_cortex_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_cortex_logs]

  bucket = module.cloudfront_cortex_logs.bucket_name
  acl    = "log-delivery-write"
}