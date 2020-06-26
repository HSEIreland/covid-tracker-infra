# #########################################
# Backend config
# #########################################
terraform {
  required_version = ">= 0.12.26"
  backend "s3" {}
}

# #########################################
# AWS provider
# #########################################
provider "aws" {
  version = "2.56.0"
  region  = var.aws_region
  profile = var.profile
}

provider "aws" {
  version = "2.56.0"
  alias   = "us"
  region  = "us-east-1"
  profile = var.profile
}

provider "aws" {
  version = "2.56.0"
  alias   = "root"
  region  = var.aws_region
  profile = var.root_profile
}

provider "aws" {
  version = "2.56.0"
  alias   = "root-us"
  region  = "us-east-1"
  profile = var.root_profile
}

# #########################################
# Other provider
# #########################################
provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.0"
}

provider "archive" {
  version = "~> 1.3.0"
}

# #########################################
# Data
# #########################################
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
