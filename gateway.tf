# #########################################
# API Gateway REST API
# #########################################
resource "aws_api_gateway_rest_api" "main" {
  name = "${module.labels.id}-gw"
  tags = module.labels.tags

  binary_media_types = [
    "application/zip",
    "application/octet-stream"
  ]

  endpoint_configuration {
    types = ["EDGE"]
  }
}

## custom domain name
resource "aws_api_gateway_domain_name" "main" {
  count           = local.gateway_api_domain_name_count
  certificate_arn = local.gateway_api_certificate_arn
  domain_name     = var.api_dns
  security_policy = "TLS_1_2"

  depends_on = [
    aws_acm_certificate.wildcard_cert_us,
    aws_acm_certificate_validation.wildcard_cert_us
  ]
}

## execution role with s3 access
data "aws_iam_policy_document" "gw_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gateway" {
  name               = "${module.labels.id}-gw"
  assume_role_policy = data.aws_iam_policy_document.gw_assume_role_policy.json
}

data "aws_iam_policy_document" "gw" {
  statement {
    actions = ["s3:*", "logs:*"]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "gw" {
  name   = "${module.labels.id}-gw"
  path   = "/"
  policy = data.aws_iam_policy_document.gw.json
}

resource "aws_iam_role_policy_attachment" "gw" {
  role       = aws_iam_role.gateway.name
  policy_arn = aws_iam_policy.gw.arn
}

# #########################################
# API Gateway resources and mapping
# #########################################
## /
resource "aws_api_gateway_method" "root" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({ statusCode : 404 })
  }
}

resource "aws_api_gateway_method_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "404"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "404"
}

## /api
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

## /api/{proxy}
resource "aws_api_gateway_resource" "api_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api_proxy_options" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_proxy.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "api_proxy_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.api_proxy_options.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_method" "api_proxy_any" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "api_proxy_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_proxy.id
  http_method             = aws_api_gateway_method.api_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.api.dns_name}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy"              = "method.request.path.proxy",
    "integration.request.header.X-Routing-Secret" = "'${jsondecode(data.aws_secretsmanager_secret_version.api_gateway_header.secret_string)["header-secret"]}'",
    "integration.request.header.X-Forwarded-For"  = "'nope'"
  }
}

resource "aws_api_gateway_method_response" "api_proxy_any" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.api_proxy_any.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "api_proxy_any_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.api_proxy_any.http_method
  status_code = aws_api_gateway_method_response.api_proxy_any.status_code
}

## /api/healthcheck
resource "aws_api_gateway_resource" "api_healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "healthcheck"
}

resource "aws_api_gateway_method" "api_healthcheck_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_healthcheck.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "api_healthcheck_get_integration" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.api_healthcheck.id
  http_method          = aws_api_gateway_method.api_healthcheck_get.http_method
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  type                 = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 204
    })
  }
}

resource "aws_api_gateway_method_response" "api_healthcheck_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_healthcheck.id
  http_method = aws_api_gateway_method.api_healthcheck_get.http_method
  status_code = "204"
}

resource "aws_api_gateway_integration_response" "api_healthcheck_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_healthcheck.id
  http_method = aws_api_gateway_method.api_healthcheck_get.http_method
  status_code = aws_api_gateway_method_response.api_healthcheck_get.status_code
}

## /api/settings
resource "aws_api_gateway_resource" "api_settings" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "settings"
}

resource "aws_api_gateway_method" "api_settings_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_settings.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "api_settings_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_settings.id
  http_method             = aws_api_gateway_method.api_settings_get.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${aws_s3_bucket.assets.id}/settings.json"
  credentials             = aws_iam_role.gateway.arn
}

resource "aws_api_gateway_method_response" "api_settings_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_settings.id
  http_method = aws_api_gateway_method.api_settings_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Content-Length" = false,
    "method.response.header.Content-Type"   = false
  }
}

resource "aws_api_gateway_integration_response" "api_settings_get_integration" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.api_settings.id
  http_method       = aws_api_gateway_method.api_settings_get.http_method
  selection_pattern = aws_api_gateway_method_response.api_settings_get.status_code
  status_code       = aws_api_gateway_method_response.api_settings_get.status_code
  response_parameters = {
    "method.response.header.Content-Length" = "integration.response.header.Content-Length",
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

## /api/stats
resource "aws_api_gateway_resource" "api_stats" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "stats"
}

resource "aws_api_gateway_method" "api_stats_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_stats.id
  http_method      = "GET"
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.main.id
  api_key_required = false
}

resource "aws_api_gateway_integration" "api_stats_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_stats.id
  http_method             = aws_api_gateway_method.api_stats_get.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${aws_s3_bucket.assets.id}/stats.json"
  credentials             = aws_iam_role.gateway.arn
}

resource "aws_api_gateway_method_response" "api_stats_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_stats.id
  http_method = aws_api_gateway_method.api_stats_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Content-Length" = false,
    "method.response.header.Content-Type"   = false
  }
}

resource "aws_api_gateway_integration_response" "api_stats_get_integration" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.api_stats.id
  http_method       = aws_api_gateway_method.api_stats_get.http_method
  selection_pattern = aws_api_gateway_method_response.api_stats_get.status_code
  status_code       = aws_api_gateway_method_response.api_stats_get.status_code
  response_parameters = {
    "method.response.header.Content-Length" = "integration.response.header.Content-Length",
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

## /api/data
resource "aws_api_gateway_resource" "api_data" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "data"
}

## /api/data/exposures
resource "aws_api_gateway_resource" "api_data_exposures" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api_data.id
  path_part   = "exposures"
}

## /api/data/exposures/{item}
resource "aws_api_gateway_resource" "api_data_exposures_item" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api_data_exposures.id
  path_part   = "{item+}"
}

resource "aws_api_gateway_method" "api_data_exposures_item_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_data_exposures_item.id
  http_method      = "GET"
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.main.id
  api_key_required = false
  request_parameters = {
    "method.request.path.item" = true
  }
}

resource "aws_api_gateway_integration" "api_data_exposures_item_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_data_exposures_item.id
  http_method             = aws_api_gateway_method.api_data_exposures_item_get.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${aws_s3_bucket.assets.id}/exposures/{item}"
  credentials             = aws_iam_role.gateway.arn
  request_parameters = {
    "integration.request.path.item" = "method.request.path.item"
  }
}

resource "aws_api_gateway_method_response" "api_data_exposures_item_get_success" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_data_exposures_item.id
  http_method = aws_api_gateway_method.api_data_exposures_item_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty",
    "application/zip"  = "Empty"
  }
  response_parameters = {
    "method.response.header.Content-Length" = false,
    "method.response.header.Content-Type"   = false
  }
}

resource "aws_api_gateway_method_response" "api_data_exposures_item_get_error" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_data_exposures_item.id
  http_method = aws_api_gateway_method.api_data_exposures_item_get.http_method
  status_code = "404"
}

resource "aws_api_gateway_integration_response" "api_data_exposures_item_get_integration_success" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.api_data_exposures_item.id
  http_method       = aws_api_gateway_method.api_data_exposures_item_get.http_method
  status_code       = aws_api_gateway_method_response.api_data_exposures_item_get_success.status_code
  selection_pattern = aws_api_gateway_method_response.api_data_exposures_item_get_success.status_code
  response_parameters = {
    "method.response.header.Content-Length" = "integration.response.header.Content-Length",
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "api_data_exposures_item_get_integration_error" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.api_data_exposures_item.id
  http_method       = aws_api_gateway_method.api_data_exposures_item_get.http_method
  status_code       = aws_api_gateway_method_response.api_data_exposures_item_get_error.status_code
  selection_pattern = "[45][0-9]{2}"
  response_templates = {
    "application/json" : jsonencode({
      message = "Not found"
    }),
    "application/zip" : jsonencode({
      message = "Not found"
    })
  }
}

# #########################################
# API Gateway Deployment
# #########################################
resource "aws_api_gateway_deployment" "live" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  stage_description = filemd5("${path.module}/gateway.tf")

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.api_proxy_options_integration,
    aws_api_gateway_integration.api_proxy_any_integration,
    aws_api_gateway_integration.api_healthcheck_get_integration,
    aws_api_gateway_integration.api_settings_get_integration,
    aws_api_gateway_integration.api_stats_get_integration,
    aws_api_gateway_integration.api_data_exposures_item_get_integration
  ]
}

# Should only have one per account/region - hence it is conditional
resource "aws_api_gateway_account" "gw" {
  count               = local.gateway_api_account_count
  cloudwatch_role_arn = aws_iam_role.gateway.arn
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "${module.labels.id}-gw-access-logs"
  retention_in_days = var.logs_retention_days
}

resource "aws_api_gateway_stage" "live" {
  deployment_id = aws_api_gateway_deployment.live.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "live"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = "[$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }

  lifecycle {
    ignore_changes = [
      cache_cluster_size
    ]
  }
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.live.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_rate_limit  = 10000
    throttling_burst_limit = 5000
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  count       = local.gateway_api_domain_name_count
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = "live"
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
}

resource "aws_api_gateway_authorizer" "main" {
  name                   = "main"
  rest_api_id            = aws_api_gateway_rest_api.main.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.authorizer.arn
}
