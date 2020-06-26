# #########################################
# Operators - group with restricted privileges
# See https://alestic.com/2015/10/aws-iam-readonly-too-permissive/
# #########################################
data "aws_iam_policy_document" "operators" {
  # PENDING: So I have at least one statement - will be able to add here when I know more
  statement {
    actions = [
      "cloudformation:GetTemplate"
    ]
    effect    = "Deny"
    resources = ["*"]
  }

  # Conditional
  # PENDING: This works from the CLI without autoscaling:UpdateAutoScalingGroup but we need autoscaling:UpdateAutoScalingGroup to work in the console
  # autoscaling:UpdateAutoScalingGroup is too permissive
  dynamic statement {
    for_each = toset(aws_autoscaling_group.bastion.*.arn)
    content {
      actions = [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup"
      ]
      resources = [statement.key]
    }
  }

  # Conditional
  dynamic statement {
    for_each = toset(aws_autoscaling_group.bastion.*.name)
    content {
      actions = [
        "ssm:StartSession"
      ]
      resources = ["arn:aws:ec2:*:*:instance/*"]
      condition {
        test     = "StringEquals"
        values   = [statement.key]
        variable = "ssm:resourceTag/aws:autoscaling:groupName"
      }
    }
  }
}

resource "aws_iam_group" "operators" {
  name = "${module.labels.id}-operators"
  path = "/"
}

resource "aws_iam_group_policy" "operators" {
  group  = aws_iam_group.operators.id
  name   = "${module.labels.id}-operators"
  policy = data.aws_iam_policy_document.operators.json
}

resource "aws_iam_group_policy_attachment" "operators" {
  group      = aws_iam_group.operators.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
