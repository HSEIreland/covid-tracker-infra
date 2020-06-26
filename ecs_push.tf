# #########################################
# ECS General Resources
# #########################################
data "aws_iam_policy_document" "push_ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "push_ecs_task_policy" {
  statement {
    actions = ["ssm:GetParameter", "secretsmanager:GetSecretValue"]
    resources = concat([
      aws_ssm_parameter.log_level.arn,
      aws_ssm_parameter.push_port.arn,
      aws_ssm_parameter.push_host.arn,
      aws_ssm_parameter.cors_origin.arn,
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_reader_host.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_database.arn,
      aws_ssm_parameter.db_ssl.arn,
      aws_ssm_parameter.default_country_code.arn,
      aws_ssm_parameter.push_enable_sns_for_sms.arn,
      aws_ssm_parameter.sms_template.arn,
      aws_ssm_parameter.sms_sender.arn,
      aws_ssm_parameter.sms_region.arn,
      data.aws_secretsmanager_secret_version.rds.arn,
      data.aws_secretsmanager_secret_version.jwt.arn
      ],
      data.aws_secretsmanager_secret_version.twilio.*.arn
    )
  }

  # This is optional
  # PENDING: Restrict the scope here, Nigel's comment "I added this to allow the Push API to send SMS via SNS. There is no topic involved as it sends to arbitrary phone numbers. We can limit the action though. I think Publish seems like a good start. We may also need the Set* actions as we call the setSMSAttributes method to try and set sender etc. https://docs.amazonaws.cn/en_us/IAM/latest/UserGuide/list_amazonsns.html"
  dynamic statement {
    for_each = var.push_enable_sns_for_sms ? { "1" : 1 } : {}
    content {
      actions   = ["sns:*"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role" "push_ecs_task_execution" {
  name               = "${module.labels.id}-push-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.push_ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "push_ecs_task_execution" {
  role       = aws_iam_role.push_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "push_ecs_task_role" {
  name               = "${module.labels.id}-push-task-role"
  assume_role_policy = data.aws_iam_policy_document.push_ecs_assume_role_policy.json
}

resource "aws_iam_policy" "push_ecs_task_policy" {
  name   = "${module.labels.id}-ecs-push-task-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.push_ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "push_ecs_task_policy" {
  role       = aws_iam_role.push_ecs_task_role.name
  policy_arn = aws_iam_policy.push_ecs_task_policy.arn
}

# #########################################
# Push Service
# #########################################
data "template_file" "push_service_container_definitions" {
  template = file("templates/push_service_task_definition.tpl")

  vars = {
    config_var_prefix = local.config_var_prefix
    image_uri         = "${aws_ecr_repository.push.repository_url}:latest"
    listening_port    = var.push_listening_port
    logs_service_name = aws_cloudwatch_log_group.push.name
    log_group_region  = var.aws_region
    node_env          = "production"
    aws_region        = var.aws_region
  }
}

resource "aws_ecs_task_definition" "push" {
  family                   = "${module.labels.id}-push"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.push_services_task_cpu
  memory                   = var.push_services_task_memory
  execution_role_arn       = aws_iam_role.push_ecs_task_execution.arn
  task_role_arn            = aws_iam_role.push_ecs_task_role.arn
  container_definitions    = data.template_file.push_service_container_definitions.rendered

  tags = module.labels.tags
}

resource "aws_ecs_service" "push" {
  name            = "${module.labels.id}-push"
  cluster         = aws_ecs_cluster.services.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.push.arn
  desired_count   = var.push_service_desired_count

  network_configuration {
    security_groups = ["${module.push_sg.id}"]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.push.id
    container_name   = "push"
    container_port   = var.push_listening_port
  }

  depends_on = [
    aws_lb_listener.push_https
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

module "push_autoscale" {
  source                      = "./modules/ecs-autoscale-service"
  ecs_cluster_resource_name   = aws_ecs_cluster.services.name
  service_resource_name       = aws_ecs_service.push.name
  ecs_autoscale_max_instances = var.push_ecs_autoscale_max_instances
  ecs_autoscale_min_instances = var.push_ecs_autoscale_min_instances
  ecs_as_cpu_high_threshold   = var.push_cpu_high_threshold
  ecs_as_cpu_low_threshold    = var.push_cpu_low_threshold
  ecs_as_mem_high_threshold   = var.push_mem_high_threshold
  ecs_as_mem_low_threshold    = var.push_mem_low_threshold
  tags                        = module.labels.tags
}

# #########################################
# API log group
# #########################################
resource "aws_cloudwatch_log_group" "push" {
  name              = "${module.labels.id}-push"
  retention_in_days = var.logs_retention_days
  tags              = module.labels.tags

  lifecycle {
    create_before_destroy = true
  }
}

# #########################################
# Security group - Allow all access from LB
# #########################################
module "push_sg" {
  source      = "./modules/security-group"
  open_egress = true
  name        = "${module.labels.id}-push"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = module.labels.tags
}

resource "aws_security_group_rule" "push_ingress_http" {
  description              = "Allows push service to accept connections from ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.alb_push_sg.id
  security_group_id        = module.push_sg.id
}
