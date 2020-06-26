data "archive_file" "stats" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_stats.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "stats_policy" {
  statement {
    actions = [
      "s3:*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "secretsmanager:GetSecretValue",
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "stats_assume_role" {
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

resource "aws_iam_policy" "stats_policy" {
  name   = "${module.labels.id}-lambda-stats-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.stats_policy.json
}

resource "aws_iam_role" "stats" {
  name               = "${module.labels.id}-lambda-stats"
  assume_role_policy = data.aws_iam_policy_document.stats_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "stats_policy" {
  role       = aws_iam_role.stats.name
  policy_arn = aws_iam_policy.stats_policy.arn
}

resource "aws_iam_role_policy_attachment" "stats_logs" {
  role       = aws_iam_role.stats.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "stats" {
  filename         = "${path.module}/.zip/${module.labels.id}_stats.zip"
  function_name    = "${module.labels.id}-stats"
  source_code_hash = data.archive_file.stats.output_base64sha256
  role             = aws_iam_role.stats.arn
  runtime          = "nodejs10.x"
  handler          = "stats.handler"
  memory_size      = 128
  timeout          = 15
  tags             = module.labels.tags

  vpc_config {
    security_group_ids = [module.lambda_sg.id]
    subnet_ids         = module.vpc.private_subnets
  }

  environment {
    variables = {
      CONFIG_VAR_PREFIX = local.config_var_prefix,
      NODE_ENV          = "production"
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }
}

module "lambda_sg" {
  source      = "./modules/security-group"
  open_egress = true
  name        = "${module.labels.id}-lambda-stats"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = module.labels.tags
}

resource "aws_security_group_rule" "lambda_ingress" {
  description       = "Allows backend services to accept connections from ALB"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = module.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_egress_vpc" {
  description       = "Allows outbound connections to VPC CIDR block"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = module.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_egress_endpoints" {
  description       = "Allows outbound connections to VPC S3 endpoint"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.vpc_endpoint_s3_pl_id]
  security_group_id = module.lambda_sg.id
}

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "${module.labels.id}-every-ten-minutes"
  description         = "Fires every ten minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "pull_stats_every_ten_minutes" {
  rule      = aws_cloudwatch_event_rule.every_ten_minutes.name
  target_id = "stats"
  arn       = aws_lambda_function.stats.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_stats" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stats.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}
