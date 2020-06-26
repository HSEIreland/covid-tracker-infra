# #########################################
# Module variables
# #########################################
variable "name" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "description" {
  default = ""
}

variable "open_egress" {
  default = true
}

variable "tags" {
  default = {}
}

# #########################################
# Local variables to enforce naming conventions
# #########################################
locals {
  tags = {
    Name        = lower(var.name)
    Environment = lower(var.environment)
  }
}

# #########################################
# Default Security group with ONLY egress allowed
# #########################################
resource "aws_security_group" "default" {
  name        = var.name
  vpc_id      = var.vpc_id
  description = var.description != "" ? var.description : lower("${var.name} security group")
  tags        = merge(local.tags, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  count             = var.open_egress ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

# #########################################
# Reusable outputs
# #########################################
output "id" {
  value = aws_security_group.default.id
}

output "name" {
  value = aws_security_group.default.name
}
