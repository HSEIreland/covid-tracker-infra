data "archive_file" "authorizer" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_authorizer.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "authorizer_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "authorizer_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "authorizer_policy" {
  name   = "${module.labels.id}-lambda-authorizer-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.authorizer_policy.json
}

resource "aws_iam_role" "authorizer" {
  name               = "${module.labels.id}-lambda-authorizer"
  assume_role_policy = data.aws_iam_policy_document.authorizer_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "authorizer_policy" {
  role       = aws_iam_role.authorizer.name
  policy_arn = aws_iam_policy.authorizer_policy.arn
}

resource "aws_lambda_function" "authorizer" {
  filename         = "${path.module}/.zip/${module.labels.id}_authorizer.zip"
  function_name    = "${module.labels.id}-authorizer"
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  role             = aws_iam_role.authorizer.arn
  runtime          = "nodejs10.x"
  handler          = "authorizer.handler"
  memory_size      = 128
  timeout          = 15
  tags             = module.labels.tags

  environment {
    variables = {
      CONFIG_VAR_PREFIX = local.config_var_prefix,
      NODE_ENV          = "production"
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash
    ]
  }
}
