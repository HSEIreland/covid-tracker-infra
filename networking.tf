# #########################################
# AWS VPC module
#   - check https://github.com/terraform-aws-modules/terraform-aws-vpc
# #########################################
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.31.0"

  name = module.labels.id
  cidr = var.vpc_cidr

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2]
  ]

  public_subnets  = var.public_subnets_cidr
  private_subnets = var.private_subnets_cidr
  intra_subnets   = var.intra_subnets_cidr

  assign_ipv6_address_on_creation = false
  enable_ipv6                     = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name = "${module.labels.id}-public"
  }
  public_route_table_tags = {
    Name = "${module.labels.id}-public"
  }
  private_subnet_tags = {
    Name = "${module.labels.id}-private"
  }
  private_route_table_tags = {
    Name = "${module.labels.id}-private"
  }
  intra_subnet_tags = {
    Name = "${module.labels.id}-intra"
  }
  intra_route_table_tags = {
    Name = "${module.labels.id}-intra"
  }

  enable_s3_endpoint = true

  enable_ssm_endpoint              = true
  ssm_endpoint_private_dns_enabled = true
  ssm_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_sns_endpoint              = true
  sns_endpoint_private_dns_enabled = true
  sns_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_secretsmanager_endpoint              = true
  secretsmanager_endpoint_private_dns_enabled = true
  secretsmanager_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_logs_endpoint              = true
  logs_endpoint_private_dns_enabled = true
  logs_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_monitoring_endpoint              = true
  monitoring_endpoint_private_dns_enabled = true
  monitoring_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  nat_gateway_tags = {
    Name = module.labels.id
  }

  tags = module.labels.tags
}


resource "aws_security_group" "vpce" {
  name   = "${module.labels.id}-endpoints"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = module.labels.tags
}