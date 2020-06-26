# #########################################
# RDS Cluster
# https://github.com/cloudposse/terraform-aws-rds-cluster
# #########################################
module "rds_cluster_aurora_postgres" {
  source              = "cloudposse/rds-cluster/aws"
  version             = "0.21.0"
  engine              = "aurora-postgresql"
  cluster_family      = var.rds_cluster_family
  cluster_size        = var.rds_cluster_size
  namespace           = var.namespace
  stage               = var.environment
  name                = "rds"
  admin_user          = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["username"]
  admin_password      = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["password"]
  db_name             = var.rds_db_name
  db_port             = "5432"
  instance_type       = var.rds_instance_type
  vpc_id              = module.vpc.vpc_id
  subnets             = concat(module.vpc.intra_subnets, module.vpc.private_subnets)
  storage_encrypted   = true
  skip_final_snapshot = var.environment == "dev" ? true : false
  backup_window       = "04:00-06:00"
  allowed_cidr_blocks = [var.vpc_cidr]
  retention_period    = var.rds_backup_retention
  deletion_protection = true

  # Put here the snapshot id to recreate the cluster using an existing dataset
  # snapshot_identifier = "SNAPSHOT ID HERE"

  tags = module.labels.tags
}
