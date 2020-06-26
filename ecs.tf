# #########################################
# ECS Cluster
# #########################################
resource "aws_ecs_cluster" "services" {
  name = module.labels.id
}