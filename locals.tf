# #########################################
# Locals
# #########################################
locals {
  # Pick one, using the var if it is set, else failback to the one we maanage
  alb_push_certificate_arn = coalesce(var.push_eu_certificate_arn, join("", aws_acm_certificate.wildcard_cert.*.arn))

  # Based on flag
  bastion_enabled_count = var.bastion_enabled ? 1 : 0

  # Cloudtrail S3 bucket name
  cloudtrail_s3_bucket_name = format("%s-cloudtrail", module.labels.id)

  # Will be used as a prefix for AWS parameters and secrets
  config_var_prefix = "${module.labels.id}-"

  # Based on flag
  enable_certificates_count = var.enable_certificates ? 1 : 0

  # Based on flag
  enable_cloudtrail_count = var.enable_cloudtrail ? 1 : 0

  # Based on flag
  enable_dns_count = var.enable_dns ? 1 : 0

  # PENDING: Revisit this
  # Need to only create one of these for an account/region
  # Logic is all the dev envs are in a single account, and assumes all the other envs are in a dedicated account/region
  gateway_api_account_count = (var.environment == "dev" && var.namespace == "fight-together") || var.environment != "dev" ? 1 : 0

  # Pick one, using the var if it is set, else failback to the one we maanage
  gateway_api_certificate_arn = coalesce(var.api_us_certificate_arn, join("", aws_acm_certificate.wildcard_cert_us.*.arn))

  # Based on either of DNS enabled OR (We have an api_dns AND and api_us_certificate_arn)
  gateway_api_domain_name_count = var.enable_dns || (var.api_dns != "" && var.api_us_certificate_arn != "") ? 1 : 0

  # cso lambda creation count
  lambda_cso_count = contains(var.optional_lambdas_to_include, "cso") ? 1 : 0
}
