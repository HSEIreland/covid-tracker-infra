data "archive_file" "token" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_token.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "token_policy" {
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

data "aws_iam_policy_document" "token_assume_role" {
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

resource "aws_iam_policy" "token_policy" {
  name   = "${module.labels.id}-lambda-token-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.token_policy.json
}

resource "aws_iam_role" "token" {
  name               = "${module.labels.id}-lambda-token"
  assume_role_policy = data.aws_iam_policy_document.token_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "token_policy" {
  role       = aws_iam_role.token.name
  policy_arn = aws_iam_policy.token_policy.arn
}

resource "aws_iam_role_policy_attachment" "token_logs" {
  role       = aws_iam_role.token.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "token" {
  filename         = "${path.module}/.zip/${module.labels.id}_token.zip"
  function_name    = "${module.labels.id}-token"
  source_code_hash = data.archive_file.token.output_base64sha256
  role             = aws_iam_role.token.arn
  runtime          = "nodejs10.x"
  handler          = "token.handler"
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
