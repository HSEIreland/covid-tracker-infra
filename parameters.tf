# #########################################
# Parameters
# #########################################
resource "aws_ssm_parameter" "api_host" {
  overwrite = true
  name      = "${local.config_var_prefix}api_host"
  type      = "String"
  value     = "0.0.0.0"
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "api_port" {
  overwrite = true
  name      = "${local.config_var_prefix}api_port"
  type      = "String"
  value     = var.api_listening_port
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "app_bundle_id" {
  overwrite = true
  name      = "${local.config_var_prefix}app_bundle_id"
  type      = "String"
  value     = var.app_bundle_id
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "callback_url" {
  overwrite = true
  name      = "${local.config_var_prefix}callback_url"
  type      = "String"
  value     = aws_sqs_queue.callback.id
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "cors_origin" {
  overwrite = true
  name      = "${local.config_var_prefix}cors_origin"
  type      = "String"
  value     = var.api_cors_origin
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_database" {
  overwrite = true
  name      = "${local.config_var_prefix}db_database"
  type      = "String"
  value     = var.rds_db_name
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_host" {
  overwrite = true
  name      = "${local.config_var_prefix}db_host"
  type      = "String"
  value     = module.rds_cluster_aurora_postgres.endpoint
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_port" {
  overwrite = true
  name      = "${local.config_var_prefix}db_port"
  type      = "String"
  value     = 5432
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_reader_host" {
  overwrite = true
  name      = "${local.config_var_prefix}db_reader_host"
  type      = "String"
  value     = module.rds_cluster_aurora_postgres.reader_endpoint
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_ssl" {
  overwrite = true
  name      = "${local.config_var_prefix}db_ssl"
  type      = "String"
  value     = "true"
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "default_country_code" {
  overwrite = true
  name      = "${local.config_var_prefix}default_country_code"
  type      = "String"
  value     = var.default_country_code
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "default_region" {
  overwrite = true
  name      = "${local.config_var_prefix}default_region"
  type      = "String"
  value     = var.default_region
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "enable_callback" {
  overwrite = true
  name      = "${local.config_var_prefix}enable_callback"
  type      = "String"
  value     = var.enable_callback
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "enable_check_in" {
  overwrite = true
  name      = "${local.config_var_prefix}enable_check_in"
  type      = "String"
  value     = var.enable_check_in
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "enable_metrics" {
  overwrite = true
  name      = "${local.config_var_prefix}enable_metrics"
  type      = "String"
  value     = var.enable_metrics
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "log_level" {
  overwrite = true
  name      = "${local.config_var_prefix}log_level"
  type      = "String"
  value     = var.log_level
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "metrics_config" {
  overwrite = true
  name      = "${local.config_var_prefix}metrics_config"
  type      = "String"
  value     = var.metrics_config
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "push_enable_sns_for_sms" {
  overwrite = true
  name      = "${local.config_var_prefix}push_enable_sns_for_sms"
  type      = "String"
  value     = var.push_enable_sns_for_sms
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "push_host" {
  overwrite = true
  name      = "${local.config_var_prefix}push_host"
  type      = "String"
  value     = "0.0.0.0"
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "push_port" {
  overwrite = true
  name      = "${local.config_var_prefix}push_port"
  type      = "String"
  value     = var.push_listening_port
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "s3_assets_bucket" {
  overwrite = true
  name      = "${local.config_var_prefix}s3_assets_bucket"
  type      = "String"
  value     = aws_s3_bucket.assets.id
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "security_code_lifetime_mins" {
  overwrite = true
  name      = "${local.config_var_prefix}security_code_lifetime_mins"
  type      = "String"
  value     = var.code_lifetime_mins
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "security_exposure_limit" {
  overwrite = true
  name      = "${local.config_var_prefix}security_exposure_limit"
  type      = "String"
  value     = var.exposure_limit
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "security_refresh_token_expiry" {
  overwrite = true
  name      = "${local.config_var_prefix}security_refresh_token_expiry"
  type      = "String"
  value     = var.refresh_token_expiry
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "security_token_lifetime_mins" {
  overwrite = true
  name      = "${local.config_var_prefix}security_token_lifetime_mins"
  type      = "String"
  value     = var.token_lifetime_mins
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "security_verify_rate_limit_secs" {
  overwrite = true
  name      = "${local.config_var_prefix}security_verify_rate_limit_secs"
  type      = "String"
  value     = var.verify_rate_limit_secs
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "sms_region" {
  overwrite = true
  name      = "${local.config_var_prefix}sms_region"
  type      = "String"
  value     = var.sms_region
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "sms_sender" {
  overwrite = true
  name      = "${local.config_var_prefix}sms_sender"
  type      = "String"
  value     = var.sms_sender
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "sms_template" {
  overwrite = true
  name      = "${local.config_var_prefix}sms_template"
  type      = "String"
  value     = var.sms_template
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "upload_token_lifetime_mins" {
  overwrite = true
  name      = "${local.config_var_prefix}upload_token_lifetime_mins"
  type      = "String"
  value     = var.refresh_token_expiry
  tags      = module.labels.tags
}

# #########################################
# Optional parameters - These exist for some instances
# #########################################
resource "aws_ssm_parameter" "arcgis_url" {
  count     = contains(var.optional_parameters_to_include, "arcgis_url") ? 1 : 0
  overwrite = true
  name      = "${local.config_var_prefix}arcgis_url"
  type      = "String"
  value     = var.arcgis_url
  tags      = module.labels.tags
}
