# #########################################
# SNS Monitoring Topic
# #########################################
resource "aws_sns_topic" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name = "${module.labels.id}-monitoring"
  tags = module.labels.tags
}

# #########################################
# Lambda Slack Notifier
# #########################################
resource "aws_sns_topic_subscription" "notify_slack" {
  count = var.enable_monitoring ? 1 : 0

  topic_arn = aws_sns_topic.monitoring[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack[0].arn
}

resource "aws_lambda_permission" "notify_slack" {
  count = var.enable_monitoring ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.monitoring[0].arn
}

data "archive_file" "notify_slack" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_notify_slack.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "notify_slack_policy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "notify_slack_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "notify_slack_policy" {
  count = var.enable_monitoring ? 1 : 0

  name   = "${module.labels.id}-lambda-notify-slack-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.notify_slack_policy.json
}

resource "aws_iam_role" "notify_slack" {
  count = var.enable_monitoring ? 1 : 0

  name               = "${module.labels.id}-lambda-notify-slack"
  assume_role_policy = data.aws_iam_policy_document.notify_slack_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "verification_policy" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.notify_slack[0].name
  policy_arn = aws_iam_policy.notify_slack_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "verification_logs" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.notify_slack[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "notify_slack" {
  count = var.enable_monitoring ? 1 : 0

  function_name = "${module.labels.id}-notify-slack"

  role             = aws_iam_role.notify_slack[0].arn
  handler          = "notify_slack.handler"
  filename         = "${path.module}/.zip/${module.labels.id}_notify_slack.zip"
  source_code_hash = data.archive_file.notify_slack.output_base64sha256
  runtime          = "nodejs10.x"
  timeout          = 15
  memory_size      = 128

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SLACK_USERNAME    = var.slack_username
      NODE_ENV          = "production"
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  tags = module.labels.tags
}

# #########################################
# API Gateway 5XX Rate error Alarm
# #########################################
resource "aws_cloudwatch_metric_alarm" "gw_5xx_count" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name                = "${module.labels.id}-5XX"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "5XXError"
  namespace                 = "AWS/ApiGateway"
  period                    = var.period_5xx
  statistic                 = "Sum"
  threshold                 = var.threshold_5xx
  treat_missing_data        = "notBreaching"
  alarm_description         = format("HTTPCode %v count for %v are more than %v in the last %d minute(s) over %v period(s)", "5XX", module.labels.id, var.threshold_5xx, var.period_5xx / 60, 1)
  alarm_actions             = [aws_sns_topic.monitoring[0].arn]
  ok_actions                = [aws_sns_topic.monitoring[0].arn]
  insufficient_data_actions = []

  dimensions = {
    ApiName = "${module.labels.id}-gw"
  }
}

# #########################################
# API Gateway 4XX Rate error Alarm
# #########################################
resource "aws_cloudwatch_metric_alarm" "gw_4xx_count" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name                = "${module.labels.id}-4XX"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "4XXError"
  namespace                 = "AWS/ApiGateway"
  period                    = var.period_4xx
  statistic                 = "Sum"
  threshold                 = var.threshold_4xx
  treat_missing_data        = "notBreaching"
  alarm_description         = format("HTTPCode %v count for %v are more than %v in the last %d minute(s) over %v period(s)", "4XX", module.labels.id, var.threshold_4xx, var.period_4xx / 60, 1)
  alarm_actions             = [aws_sns_topic.monitoring[0].arn]
  ok_actions                = [aws_sns_topic.monitoring[0].arn]
  insufficient_data_actions = []

  dimensions = {
    ApiName = "${module.labels.id}-gw"
  }
}

# #########################################
# API Gateway Latency Alarm
# #########################################
resource "aws_cloudwatch_metric_alarm" "gw_p95_latency" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name                = "${module.labels.id}-p95-latency"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "Latency"
  namespace                 = "AWS/ApiGateway"
  period                    = var.period_latency
  extended_statistic        = "p95"
  threshold                 = var.threshold_latency
  treat_missing_data        = "notBreaching"
  alarm_description         = format("API Gateway p95 latency for %v is more than %v milliseconds for the last %d minute(s) over %v period(s)", module.labels.id, var.threshold_latency, var.period_latency / 60, 1)
  alarm_actions             = [aws_sns_topic.monitoring[0].arn]
  ok_actions                = [aws_sns_topic.monitoring[0].arn]
  insufficient_data_actions = []

  dimensions = {
    ApiName = "${module.labels.id}-gw"
  }
}
