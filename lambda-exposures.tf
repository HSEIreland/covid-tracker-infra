data "archive_file" "exposures" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_exposures.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "exposures_policy" {
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

data "aws_iam_policy_document" "exposures_assume_role" {
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

resource "aws_iam_policy" "exposures_policy" {
  name   = "${module.labels.id}-lambda-exposures-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.exposures_policy.json
}

resource "aws_iam_role" "exposures" {
  name               = "${module.labels.id}-lambda-exposures"
  assume_role_policy = data.aws_iam_policy_document.exposures_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "exposures_policy" {
  role       = aws_iam_role.exposures.name
  policy_arn = aws_iam_policy.exposures_policy.arn
}

resource "aws_iam_role_policy_attachment" "exposures_logs" {
  role       = aws_iam_role.exposures.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "exposures" {
  filename         = "${path.module}/.zip/${module.labels.id}_exposures.zip"
  function_name    = "${module.labels.id}-exposures"
  source_code_hash = data.archive_file.exposures.output_base64sha256
  role             = aws_iam_role.exposures.arn
  runtime          = "nodejs10.x"
  handler          = "exposures.handler"
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

resource "aws_cloudwatch_event_rule" "exposures_schedule" {
  schedule_expression = var.exposure_schedule
}

resource "aws_cloudwatch_event_target" "exposures_schedule" {
  rule      = aws_cloudwatch_event_rule.exposures_schedule.name
  target_id = "exposures"
  arn       = aws_lambda_function.exposures.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_exposures" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exposures.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.exposures_schedule.arn
}
