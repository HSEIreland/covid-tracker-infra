resource "aws_iam_user" "ci_user" {
  name = "${module.labels.id}-ci"
  tags = module.labels.tags
}

resource "aws_iam_access_key" "ci_user" {
  user = aws_iam_user.ci_user.name
}

resource "aws_iam_user_policy_attachment" "ci_user_ecr" {
  user       = aws_iam_user.ci_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

data "aws_iam_policy_document" "ci_user" {
  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "iam:PassRole",
      "ecs:DescribeServices",
      "lambda:*"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_user_policy" "ci_user" {
  name   = "${module.labels.id}-ci-user"
  user   = aws_iam_user.ci_user.name
  policy = data.aws_iam_policy_document.ci_user.json
}
