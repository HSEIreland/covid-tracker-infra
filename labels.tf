# #########################################
# Labels
# #########################################
module "labels" {
  source  = "cloudposse/label/null"
  version = "0.16.0"
  name    = var.namespace
  stage   = var.environment

  tags = {
    Environment = var.environment
    Project     = var.full_name
  }
}