locals {
  private_subnet_count = var.create_private_subnets && var.max_subnet_count == 0 && length(flatten(var.azs_list_names)) == 0 ? length(flatten(data.aws_availability_zones.azs.names)) : var.create_private_subnets && length(flatten(var.azs_list_names)) > 0 ? length(flatten(var.azs_list_names)) : var.create_private_subnets && var.max_subnet_count != 0 ? var.max_subnet_count : var.create_private_subnets && var.include_all_azs ? length(flatten(data.aws_availability_zones.azs.names)) : 0
}
module "private_label" {
  source = "github.com/obytes/terraform-aws-tag.git?ref=v1.0.1"
  attributes = ["prv"]
  random_string = module.label.random_string
  context = module.label.context
}

resource "aws_subnet" "private" {
  count = local.private_subnet_count
  cidr_block = cidrsubnet(
  var.cidr_block,
  ceil(log(length(flatten(var.include_all_azs ? data.aws_availability_zones.azs.names : var.azs_list_names)) * 2, 2)),
  count.index)
  availability_zone = element(local.availability_zones, count.index )
  vpc_id = join("", aws_vpc._.*.id)
  tags = merge(module.private_label.tags, map("VPC", join("", aws_vpc._.*.id),
  "Availability Zone", length(var.azs_list_names) > 0 ? element(var.azs_list_names,count.index) : element(data.aws_availability_zones.azs.names,count.index),
  "Name", join(module.private_label.delimiter, [module.private_label.id,  local.az_map_list_short[local.availability_zones[count.index]]])
  ))
}

# There are as many route_table as local.nat_gateway_count
resource "aws_route_table" "private" {
  count = local.enabled && local.private_subnet_count > 0 ? local.nat_gateway_count : 0
  vpc_id = aws_vpc._[count.index].id

  tags = merge(module.private_label.tags, map("Name", join(module.private_label.delimiter, [module.private_label.id, "route", count.index])),
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

resource "aws_route_table_association" "private" {
  count = local.enabled && local.private_subnet_count > 0 ? local.private_subnet_count : 0
  route_table_id = element(aws_route_table.private.*.id, var.single_nat_gateway ? 0 : count.index )
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}