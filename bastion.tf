# #########################################
# Bastion
# Lots of the values are hard coded as this is for troubleshooting - i.e. connect to RDS to troubleshoot
# #########################################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "aws_autoscaling_group" "bastion" {
  count               = local.bastion_enabled_count
  desired_capacity    = 0
  max_size            = 1
  min_size            = 0
  name                = format("%s-bastion", module.labels.id)
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.bastion[0].id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  dynamic tag {
    for_each = module.labels.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "bastion" {
  count                  = local.bastion_enabled_count
  autoscaling_group_name = aws_autoscaling_group.bastion[0].name
  desired_capacity       = 0
  min_size               = -1
  max_size               = -1
  recurrence             = "01 21 * * *"
  scheduled_action_name  = "Scale-down-nightly"
}

resource "aws_launch_template" "bastion" {
  count                  = local.bastion_enabled_count
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.small"
  name_prefix            = format("%s-bastion-", module.labels.id)
  vpc_security_group_ids = aws_security_group.bastion.*.id
  user_data              = base64encode("#!/bin/bash\nyum update -y\namazon-linux-extras install -y postgresql11")

  iam_instance_profile {
    arn = aws_iam_instance_profile.bastion[0].arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  count  = local.bastion_enabled_count
  name   = format("%s-bastion", module.labels.id)
  tags   = module.labels.tags
  vpc_id = module.vpc.vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "bastion" {
  count = local.bastion_enabled_count
  name  = format("%s-bastion", module.labels.id)
  role  = aws_iam_role.bastion[0].id
}

resource "aws_iam_role" "bastion" {
  count = local.bastion_enabled_count
  name  = format("%s-bastion", module.labels.id)
  tags  = module.labels.tags

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Sid = "AllowEC2InstancesAssume"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "bastion_amazon_ssm_managed_Instance_core" {
  count      = local.bastion_enabled_count
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion[0].name
}
