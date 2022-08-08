locals {
  networking = {
    dev = "10.230.128.0/19"
  }
}

module "vpc" {
  for_each = local.networking
  source   = "../modules/aws-vpc-hub"

  # CIDRs
  vpc_cidr = each.value

  # private gateway type
  #   nat = Nat Gateway
  #   transit = Transit Gateway
  #   none = no gateway for internal traffic
  gateway = "nat"

  # VPC Flow Logs
  #vpc_flow_log_iam_role = data.aws_iam_role.vpc-flow-log.arn

  # Tags
  tags_prefix = each.key
}

# SSM Security Groups
resource "aws_security_group" "endpoints" {
  for_each = local.networking

  name        = "${each.key}-int-endpoint"
  description = "Control interface traffic"
  vpc_id      = module.vpc[each.key].vpc_id

  tags = {
    Name = "${each.key}-int-endpoint"
  }
}

resource "aws_security_group_rule" "endpoints_ingress_1" {
  for_each = local.networking

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.endpoints[each.key].id
}

module "vpc_endpoints" {
  for_each = local.networking
  source   = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc[each.key].vpc_id
  security_group_ids = [aws_security_group.endpoints[each.key].id]

  # One endpoint per AZ is enough, regardless the subnet. Therefore
  # there is no need to add the public subnets explicitly. In fact
  # had we do that, then would receive the "DuplicateSubnetsInSameZone"
  # error.
  endpoints = {
    # ec2 = {
    #   service             = "ec2"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    # ec2messages = {
    #   service             = "ec2messages"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    # ecr_api = {
    #   service             = "ecr.api"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    # ecr_dkr = {
    #   service             = "ecr.dkr"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    # kms = {
    #   service             = "kms"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    s3_gw = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = [for value in module.vpc[each.key].private_route_tables : value]
      tags            = { Name = "s3-gw-vpc-endpoint" }
    },
    # ssm = {
    #   service             = "ssm"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # },
    # ssmmessages = {
    #   service             = "ssmmessages"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc[each.key].private_subnet_ids
    # }
  }

}

# #TESTING VARIABLES ---------------

# output "vpc_cidrs" {
#   value = {
#     for key, value in local.networking :
#     key => value
#   }
# }

# output "non_live_data_private_route_tables" {

#   value = module.vpc["non_live_data"].private_route_tables
# }

# output "public_route_tables" {
#   value = {
#     for key, value in local.networking :
#     key => module.vpc[key].public_route_tables.tags["Name"]
#   }
# }

# output "live_data_private_route_tables" {

#   value = module.vpc["live_data"].private_route_tables
# }

# output "public_igw_route" {
#   value = {
#     for key, value in local.networking :
#     key => module.vpc[key].public_igw_route.destination_cidr_block
#   }
# }

# output "non_tgw_subnet_ids" {

#   value = length(module.vpc["non_live_data"].non_tgw_subnet_ids)
# }

# output "tgw_subnet_ids" {

#   value = length(module.vpc["non_live_data"].tgw_subnet_ids)
# }

# output "vpc" {
#   value = module.vpc
# }

# output "vpc_endpoints" {
#   value = module.vpc_endpoints
# }
