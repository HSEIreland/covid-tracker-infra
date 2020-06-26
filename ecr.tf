# #########################################
# General ECR Policies
# #########################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "login" {
  statement {
    sid     = "ECRGetAuthorizationToken"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "write" {
  statement {
    sid    = "ECRGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]

    resources = [
      aws_ecr_repository.api.arn,
      aws_ecr_repository.push.arn
    ]
  }
}

data "aws_iam_policy_document" "read" {
  statement {
    sid    = "ECRGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]

    resources = [
      aws_ecr_repository.api.arn,
      aws_ecr_repository.push.arn
    ]
  }
}

resource "aws_iam_policy" "login" {
  name        = "${module.labels.id}${module.labels.delimiter}${var.aws_region}${module.labels.delimiter}login"
  description = "Allow IAM Users to call ecr:GetAuthorizationToken"
  policy      = data.aws_iam_policy_document.login.json
}

resource "aws_iam_policy" "read" {
  name        = "${module.labels.id}${module.labels.delimiter}${var.aws_region}${module.labels.delimiter}read"
  description = "Allow IAM Users to pull from ECR"
  policy      = data.aws_iam_policy_document.read.json
}

resource "aws_iam_policy" "write" {
  name        = "${module.labels.id}${module.labels.delimiter}${var.aws_region}${module.labels.delimiter}write"
  description = "Allow IAM Users to push into ECR"
  policy      = data.aws_iam_policy_document.write.json
}

resource "aws_iam_role" "default" {
  name               = "${module.labels.id}${module.labels.delimiter}${var.aws_region}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.login.arn
}

resource "aws_iam_instance_profile" "default" {
  name = "${module.labels.id}${module.labels.delimiter}${var.aws_region}"
  role = aws_iam_role.default.name
}

locals {
  image_rotation_policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Rotate images when reach ${var.default_ecr_max_image_count} images stored",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${var.default_ecr_max_image_count}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_ecr_repository" "api" {
  name = "${var.namespace}/api"

  tags = module.labels.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api_policy" {
  repository = aws_ecr_repository.api.name

  policy = local.image_rotation_policy
}

resource "aws_ecr_repository" "push" {
  name = "${var.namespace}/push"

  tags = module.labels.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "push_policy" {
  repository = aws_ecr_repository.push.name

  policy = local.image_rotation_policy
}

resource "aws_ecr_repository" "migrations" {
  name = "${var.namespace}/migrations"

  tags = module.labels.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "migrations_policy" {
  repository = aws_ecr_repository.migrations.name

  policy = local.image_rotation_policy
}

