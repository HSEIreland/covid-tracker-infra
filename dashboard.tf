data "template_file" "dashboard" {
  template = file("templates/dashboard.json")

  vars = {
    account_id            = data.aws_caller_identity.current.account_id
    region                = var.aws_region
    environment           = var.environment
    gateway_name          = "${module.labels.id}-gw"
    ecs_cluster_name      = module.labels.id
    ecs_push_service_name = aws_ecs_service.push.name
    ecs_api_service_name  = aws_ecs_service.api.name
    rds_db_cluster_name   = module.rds_cluster_aurora_postgres.cluster_identifier
    lambda_token_fn_name  = "${module.labels.id}-token"
    lambda_cso_fn_name    = "${module.labels.id}-cso"
    lambda_stats_fn_name  = "${module.labels.id}-stats"
    api_lb_arn_suffix     = aws_lb.api.arn_suffix
    push_lb_arn_suffix    = aws_lb.push.arn_suffix
    api_log_group         = "${module.labels.id}-api"
  }
}

resource "aws_cloudwatch_dashboard" "monitoring_alarms_dashboard" {
  dashboard_name = module.labels.id
  dashboard_body = data.template_file.dashboard.rendered
}