# #########################################
# Secrets - These will already exist
# #########################################
data "aws_secretsmanager_secret_version" "api_gateway_header" {
  secret_id = "${local.config_var_prefix}header-x-secret"
}

data "aws_secretsmanager_secret_version" "device-check" {
  secret_id = "${local.config_var_prefix}device-check"
}

data "aws_secretsmanager_secret_version" "encrypt" {
  secret_id = "${local.config_var_prefix}encrypt"
}

data "aws_secretsmanager_secret_version" "exposures" {
  secret_id = "${local.config_var_prefix}exposures"
}

data "aws_secretsmanager_secret_version" "jwt" {
  secret_id = "${local.config_var_prefix}jwt"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = "${local.config_var_prefix}rds"
}

# #########################################
# Optional secrets - These exist for some instances
# #########################################
data "aws_secretsmanager_secret_version" "cct" {
  count     = contains(var.optional_secrets_to_include, "cct") ? 1 : 0
  secret_id = "${local.config_var_prefix}cct"
}

data "aws_secretsmanager_secret_version" "cso" {
  count     = contains(var.optional_secrets_to_include, "cso") ? 1 : 0
  secret_id = "${local.config_var_prefix}cso"
}

data "aws_secretsmanager_secret_version" "twilio" {
  count     = contains(var.optional_secrets_to_include, "twilio") ? 1 : 0
  secret_id = "${local.config_var_prefix}twilio"
}
