locals {
  public_subnet_count = 3
}

resource "aws_subnet" "public" {
  count = local.public_subnet_count
  cidr_block = cidrsubnet(
    var.cidr_block,
    12,  // subnet mask size for 4096 IP addresses
    count.index)
  availability_zone = element(local.availability_zones, count.index)
  vpc_id            = join("", aws_vpc._.*.id)
  tags = merge(var.additional_tags, var.additional_public_subnet_tags, tomap({ "VPC" = join("", aws_vpc._.*.id),
    "Availability Zone" = length(var.azs_list_names) > 0 ? element(var.azs_list_names, count.index) : element(data.aws_availability_zones.azs.names, count.index),
    "Name" = join(local.delimiter, [local.name, local.az_map_list_short[local.availability_zones[count.index]]]) }
  ))
}

resource "aws_route_table" "public" {
  count  = local.enabled && local.public_subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc._[count.index].id

  tags = merge(var.additional_tags, tomap({ "Name" = join(local.delimiter, [local.name, "pub-route", count.index]) }),
    var.additional_public_route_tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count = local.enabled && local.internet_gateway_count > 0 && local.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway._[0].id

  timeouts {
    create = var.route_create_timeout
    delete = var.route_delete_timeout
  }
}

resource "aws_route" "transit_gw_route_public" {
  count = local.enabled && var.enable_nat_gateway && var.tgw_route_table_id != null ? length(var.transit_routes) : 0

  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = element(var.transit_routes, count.index)
  transit_gateway_id     = var.tgw_route_table_id

  timeouts {
    create = var.route_create_timeout
    delete = var.route_delete_timeout
  }
}

resource "aws_route_table_association" "public" {
  count          = local.enabled && local.public_subnet_count > 0 ? local.public_subnet_count : 0
  route_table_id = aws_route_table.public[0].id
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}
