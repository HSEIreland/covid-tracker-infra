# #########################################
# ECS General Resources
# #########################################
data "aws_iam_policy_document" "api_ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_ecs_task_execution" {
  name               = "${module.labels.id}-api-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.api_ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "api_ecs_task_execution" {
  role       = aws_iam_role.api_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "api_ecs_task_role" {
  name               = "${module.labels.id}-api-task-role"
  assume_role_policy = data.aws_iam_policy_document.api_ecs_assume_role_policy.json
}

data "aws_iam_policy_document" "api_ecs_task_policy" {
  statement {
    actions = ["ssm:GetParameter", "secretsmanager:GetSecretValue"]
    resources = [
      aws_ssm_parameter.log_level.arn,
      aws_ssm_parameter.api_port.arn,
      aws_ssm_parameter.api_host.arn,
      aws_ssm_parameter.cors_origin.arn,
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_reader_host.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_database.arn,
      aws_ssm_parameter.db_ssl.arn,
      aws_ssm_parameter.security_exposure_limit.arn,
      aws_ssm_parameter.security_refresh_token_expiry.arn,
      aws_ssm_parameter.security_code_lifetime_mins.arn,
      aws_ssm_parameter.security_token_lifetime_mins.arn,
      aws_ssm_parameter.metrics_config.arn,
      aws_ssm_parameter.security_verify_rate_limit_secs.arn,
      aws_ssm_parameter.callback_url.arn,
      aws_ssm_parameter.upload_token_lifetime_mins.arn,
      aws_ssm_parameter.s3_assets_bucket.arn,
      aws_ssm_parameter.enable_callback.arn,
      aws_ssm_parameter.enable_check_in.arn,
      aws_ssm_parameter.enable_metrics.arn,
      aws_ssm_parameter.default_region.arn,
      data.aws_secretsmanager_secret_version.rds.arn,
      data.aws_secretsmanager_secret_version.encrypt.arn,
      data.aws_secretsmanager_secret_version.jwt.arn,
      data.aws_secretsmanager_secret_version.device-check.arn
    ]
  }

  statement {
    actions = ["sqs:*"]
    resources = [
      aws_sqs_queue.callback.arn
    ]
  }
}

resource "aws_iam_policy" "api_ecs_task_policy" {
  name   = "${module.labels.id}-ecs-api-task-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.api_ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "api_ecs_task_policy" {
  role       = aws_iam_role.api_ecs_task_role.name
  policy_arn = aws_iam_policy.api_ecs_task_policy.arn
}

# #########################################
# API Service
# #########################################
data "template_file" "api_service_container_definitions" {
  template = file("templates/api_service_task_definition.tpl")

  vars = {
    api_image_uri        = "${aws_ecr_repository.api.repository_url}:latest"
    config_var_prefix    = local.config_var_prefix
    migrations_image_uri = "${aws_ecr_repository.migrations.repository_url}:latest"
    listening_port       = var.api_listening_port
    logs_service_name    = aws_cloudwatch_log_group.api.name
    log_group_region     = var.aws_region
    node_env             = "production"
    aws_region           = var.aws_region
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${module.labels.id}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_services_task_cpu
  memory                   = var.api_services_task_memory
  execution_role_arn       = aws_iam_role.api_ecs_task_execution.arn
  task_role_arn            = aws_iam_role.api_ecs_task_role.arn
  container_definitions    = data.template_file.api_service_container_definitions.rendered

  tags = module.labels.tags
}

resource "aws_ecs_service" "api" {
  name            = "${module.labels.id}-api"
  cluster         = aws_ecs_cluster.services.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_service_desired_count

  network_configuration {
    security_groups = ["${module.api_sg.id}"]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.id
    container_name   = "api"
    container_port   = var.api_listening_port
  }

  depends_on = [
    aws_lb_listener.api_http
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

module "api_autoscale" {
  source                      = "./modules/ecs-autoscale-service"
  ecs_cluster_resource_name   = aws_ecs_cluster.services.name
  service_resource_name       = aws_ecs_service.api.name
  ecs_autoscale_max_instances = var.api_ecs_autoscale_max_instances
  ecs_autoscale_min_instances = var.api_ecs_autoscale_min_instances
  ecs_as_cpu_high_threshold   = var.api_cpu_high_threshold
  ecs_as_cpu_low_threshold    = var.api_cpu_low_threshold
  ecs_as_mem_high_threshold   = var.api_mem_high_threshold
  ecs_as_mem_low_threshold    = var.api_mem_low_threshold
  tags                        = module.labels.tags
}

# #########################################
# API log group
# #########################################
resource "aws_cloudwatch_log_group" "api" {
  name              = "${module.labels.id}-api"
  retention_in_days = var.logs_retention_days
  tags              = module.labels.tags

  lifecycle {
    create_before_destroy = true
  }
}

# #########################################
# Security group - Allow all access from LB
# #########################################
module "api_sg" {
  source      = "./modules/security-group"
  open_egress = true
  name        = "${module.labels.id}-api"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = module.labels.tags
}

resource "aws_security_group_rule" "api_ingress_http" {
  description              = "Allows backend services to accept connections from ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.alb_api_sg.id
  security_group_id        = module.api_sg.id
}
