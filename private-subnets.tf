locals {
  private_subnet_count = var.create_private_subnets && var.max_subnet_count == 0 && length(flatten(var.azs_list_names)) == 0 ? length(flatten(data.aws_availability_zones.azs.names)) : var.create_private_subnets && length(flatten(var.azs_list_names)) > 0 ? length(flatten(var.azs_list_names)) : var.create_private_subnets && var.max_subnet_count != 0 ? var.max_subnet_count : var.create_private_subnets && var.include_all_azs ? length(flatten(data.aws_availability_zones.azs.names)) : 0
  subnet_mask_bits = 22
}

resource "aws_subnet" "private" {
  count = local.private_subnet_count
  cidr_block = cidrsubnet(
    var.cidr_block,
    ceil(log(length(flatten(var.include_all_azs ? data.aws_availability_zones.azs.names : var.azs_list_names)) * 2, 2)),
  count.index)
  availability_zone = element(local.availability_zones, count.index)
  vpc_id            = join("", aws_vpc._.*.id)
  tags = merge(var.additional_tags, var.additional_private_subnet_tags, tomap({ "VPC" = join("", aws_vpc._.*.id),
    "Availability Zone" = length(var.azs_list_names) > 0 ? element(var.azs_list_names, count.index) : element(data.aws_availability_zones.azs.names, count.index),
    "Name" = join(local.delimiter, [local.name, local.az_map_list_short[local.availability_zones[count.index]]]) }
  ))
}

# There are as many route_table as local.nat_gateway_count
resource "aws_route_table" "private" {
  count  = local.enabled && local.private_subnet_count > 0 ? local.nat_gateway_count : 0
  vpc_id = aws_vpc._[count.index].id

  tags = merge(var.additional_tags, tomap({ "Name" = join(local.delimiter, [local.name, "prv-route", count.index]) }),
    var.additional_private_route_tags
  )

}

resource "aws_route" "private_nat_gateway" {
  count = local.enabled && var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway._.*.id, count.index)

  timeouts {
    create = var.route_create_timeout
    delete = var.route_delete_timeout
  }
}

resource "aws_route" "transit_gw_route_private" {
  count = local.enabled && var.enable_nat_gateway && var.tgw_route_table_id != null ? length(var.transit_routes) : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = element(var.transit_routes, count.index)
  transit_gateway_id     = var.tgw_route_table_id

  timeouts {
    create = var.route_create_timeout
    delete = var.route_delete_timeout
  }
}

resource "aws_route_table_association" "private" {
  count          = local.enabled && local.private_subnet_count > 0 ? local.private_subnet_count : 0
  route_table_id = element(aws_route_table.private.*.id, var.single_nat_gateway ? 0 : count.index)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}
