data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az    = sort(data.aws_availability_zones.available.names)
  cidrs = cidrsubnets(var.vpc_cidr, 9, 9, 9, 3, 3, 3, 5, 5, 5)
  types = ["transit_gateway", "private", "public"]

  # SAMPLE OUTPUT OF: types_and_az_and_cidrs

  # data            = {
  #     data-eu-west-2a = {
  #         az   = "eu-west-2a"
  #         cidr = "10.1.130.0/23"
  #           }
  #     data-eu-west-2b = {
  #         az   = "eu-west-2b"
  #         cidr = "10.1.132.0/23"
  #           }
  #     data-eu-west-2c = {
  #         az   = "eu-west-2c"
  #         cidr = "10.1.134.0/23"
  #           }
  #       }
  # private         = {
  #     private-eu-west-2a = {
  #         az   = "eu-west-2a"
  #         cidr = "10.1.136.0/23"
  #           }
  #     private-eu-west-2b = {
  #         az   = "eu-west-2b"
  #         cidr = "10.1.138.0/23"
  #           }
  #     private-eu-west-2c = {
  #         az   = "eu-west-2c"
  #         cidr = "10.1.140.0/23"
  #           }
  #       }
  types_and_azs_and_cidrs = {
    for index, type in local.types :
    type => {
      for cidr_index, cidr in slice(local.cidrs, index * 3, index * 3 + 3) :
      "${type}-${local.az[cidr_index]}" => {
        cidr = cidr
        az   = local.az[cidr_index]
      }
    }
  }

  # NACLs
  nacl_rules = [
    { egress = false, action = "allow", protocol = -1, from_port = 0, to_port = 0, rule_num = 910, cidr = "0.0.0.0/0" },
    { egress = true, action = "allow", protocol = -1, from_port = 0, to_port = 0, rule_num = 910, cidr = "0.0.0.0/0" }
  ]

  # NACL rules with keys
  nacl_rules_expanded = {
    for rule in local.nacl_rules : join("-", values(rule)) => rule
  }
}

resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr

  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_classiclink             = false
  enable_classiclink_dns_support = false

  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.tags_prefix
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name = "${var.tags_prefix}-vpc-flow-logs"
}

# resource "aws_flow_log" "cloudwatch" {
#   iam_role_arn             = var.vpc_flow_log_iam_role
#   log_destination          = aws_cloudwatch_log_group.default.arn
#   traffic_type             = "ALL"
#   log_destination_type     = "cloud-watch-logs"
#   max_aggregation_interval = "60"
#   vpc_id                   = aws_vpc.default.id

#   tags = {
#     Name = "${var.tags_prefix}-vpc-flow-logs"
#   }
# }

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.tags_prefix}-internet-gateway"
  }
}

resource "aws_subnet" "public" {
  for_each = tomap(local.types_and_azs_and_cidrs.public)

  vpc_id = aws_vpc.default.id

  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

# Public NACLs
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.default.id
  subnet_ids = [
    for subnet in aws_subnet.public : subnet.id
  ]

  tags = {
    Name = "${var.tags_prefix}-public"
  }
}

# Public NACLs rules
resource "aws_network_acl_rule" "public" {
  for_each = local.nacl_rules_expanded

  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_num
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "public_local_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 210
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "public_local_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 210
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.tags_prefix}-public"
  }
}

# Public route table assocation with public subnets
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Public route
resource "aws_route" "public_internet_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  for_each = tomap(local.types_and_azs_and_cidrs.private)

  vpc_id = aws_vpc.default.id

  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.default.id
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  tags = {
    Name = "${var.tags_prefix}-private"
  }
}

resource "aws_network_acl_rule" "private" {
  for_each = local.nacl_rules_expanded

  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_num
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "private_local_ingress" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 210
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_local_egress" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 210
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

# Private route table assocation with private subnets
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_subnet" "transit_gateway" {
  for_each = tomap(local.types_and_azs_and_cidrs.transit_gateway)

  vpc_id = aws_vpc.default.id

  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

# Transit Gateway NACLs
resource "aws_network_acl" "transit_gateway" {
  vpc_id = aws_vpc.default.id
  subnet_ids = [
    for subnet in aws_subnet.transit_gateway : subnet.id
  ]

  tags = {
    Name = "${var.tags_prefix}-transit_gateway"
  }
}

# Transit Gateway NACLs rules
resource "aws_network_acl_rule" "transit_gateway" {
  for_each = local.nacl_rules_expanded

  network_acl_id = aws_network_acl.transit_gateway.id
  rule_number    = each.value.rule_num
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "transit_gateway_local_ingress" {
  network_acl_id = aws_network_acl.transit_gateway.id
  rule_number    = 210
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "transit_gateway_local_egress" {
  network_acl_id = aws_network_acl.transit_gateway.id
  rule_number    = 210
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Transit Gateway route table
resource "aws_route_table" "transit_gateway" {
  for_each = aws_subnet.transit_gateway

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

# Transit Gateway route table assocation with transit_gateway subnets
resource "aws_route_table_association" "transit_gateway" {
  for_each = aws_subnet.transit_gateway

  subnet_id      = each.value.id
  route_table_id = aws_route_table.transit_gateway[each.key].id
}

##
# NAT Gateway
##
resource "aws_eip" "public" {
  for_each = (var.gateway == "nat") ? aws_subnet.public : {}

  vpc = true

  tags = {
    Name = "${var.tags_prefix}-${each.key}_nat"
  }
}

resource "aws_nat_gateway" "public" {
  for_each = (var.gateway == "nat") ? aws_subnet.public : {}

  allocation_id = aws_eip.public[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "${var.tags_prefix}-${each.key}"
  }
}

# Private NAT routes
resource "aws_route" "private_nat" {
  for_each = (var.gateway == "nat") ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[replace(each.key, "private", "public")].id
}

# Transit Gateway NAT routes
resource "aws_route" "transit_gateway_nat" {
  for_each = (var.gateway == "nat") ? aws_route_table.transit_gateway : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[replace(each.key, "transit_gateway", "public")].id
}
