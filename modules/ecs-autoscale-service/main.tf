# #########################################
# Variables
# #########################################
variable "enabled" {
  default = true
}

variable "service_resource_name" {
  default = ""
}

variable "ecs_cluster_resource_name" {
  default = ""
}

variable "ecs_autoscale_max_instances" {
  default = 12
}

variable "ecs_autoscale_min_instances" {
  default = 1
}

variable "ecs_as_cpu_high_threshold" {
  default = 60
}

variable "ecs_as_cpu_low_threshold" {
  default = 20
}

variable "ecs_as_mem_high_threshold" {
  default = 60
}

variable "ecs_as_mem_low_threshold" {
  default = 10
}

variable "tags" {
  default = {}
}

# #########################################
# Autoscale target
# #########################################
resource "aws_appautoscaling_target" "services_scale_target" {
  count              = var.enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_resource_name}/${var.service_resource_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

# #########################################
# Scale up and down policies
# #########################################
resource "aws_appautoscaling_policy" "scale_up" {
  count              = var.enabled ? 1 : 0
  name               = "${var.service_resource_name}-scale-up"
  service_namespace  = aws_appautoscaling_target.services_scale_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.services_scale_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.services_scale_target[0].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  count              = var.enabled ? 1 : 0
  name               = "${var.service_resource_name}-scale-down"
  service_namespace  = aws_appautoscaling_target.services_scale_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.services_scale_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.services_scale_target[0].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# #########################################
# CPU based alarms
# #########################################
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${var.service_resource_name}-cpu-utilization-high-${var.ecs_as_cpu_high_threshold}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_high_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_resource_name
    ServiceName = var.service_resource_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up[0].arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${var.service_resource_name}-cpu-utilization-low-${var.ecs_as_cpu_low_threshold}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_low_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_resource_name
    ServiceName = var.service_resource_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down[0].arn]

  tags = var.tags
}

# #########################################
# Memory based alarms
# #########################################
resource "aws_cloudwatch_metric_alarm" "memory_usage_high" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${var.service_resource_name}-memory-utilization-high-${var.ecs_as_mem_high_threshold}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_as_mem_high_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_resource_name
    ServiceName = var.service_resource_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up[0].arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_usage_low" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${var.service_resource_name}-memory-utilization-low-${var.ecs_as_mem_low_threshold}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.ecs_as_mem_low_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_resource_name
    ServiceName = var.service_resource_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down[0].arn]

  tags = var.tags
}
