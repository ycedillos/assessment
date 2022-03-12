# --------------------------------------------------------------------
# Virtual Private Cloud (VPC) network resources
# --------------------------------------------------------------------

###
# Virtual Private Cloud (VPC)
###
resource "aws_vpc" "websites" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws
  tags = merge(
    {
      "Name" = "websites"
    },
  )
}

###
# Internet Gateway
###
resource "aws_internet_gateway" "this" {
  count    = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id   = aws_vpc.websites.id
  provider = aws
  tags = merge(
    {
      "Name" = "websites"
    },
  )
}


###
# Public Subnets
###
resource "aws_subnet" "public_subnets" {
  provider                = aws
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.websites.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index % length(var.azs))
  map_public_ip_on_launch = true
  tags = merge(
    {
      "Name" = "websites"
    },
  )
}

###
# Private Subnets
###
resource "aws_subnet" "private_subnets" {
  provider                = aws
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.websites.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index % length(var.azs))
  map_public_ip_on_launch = false
  tags = merge(
    {
      "Name" = "websites"
    },
  )
}

###
# Database Subnets (private)
###
resource "aws_subnet" "private_db_subnets" {
  provider                = aws
  count                   = length(var.db_subnet_cidrs)
  vpc_id                  = aws_vpc.websites.id
  cidr_block              = element(var.db_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index % length(var.azs))
  map_public_ip_on_launch = false
  tags = merge(
    {
      "Name" = "websites"
    },
  )
}

###
# Route table for public subnets
###
resource "aws_route_table" "public" {
  provider = aws
  count    = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id   = aws_vpc.websites.id
  tags = merge(
    {
      "Name" = "rt-public"
    },
  )
}

###
# Route table(s) for private subnets
# ----------------------------------
# This is rather variable:
#       a) Create RT only if we have private and/or db subnets defined 
#       b) If var.single_nat_gw is 'true', we make 1 RT for all non-public subnets
#       c) If var.single_nat_gw is 'false', we make 1 RT per defined AZ in ${var.azs}
resource "aws_route_table" "private" {
  provider = aws
  count    = length(var.private_subnet_cidrs) > 0 || length(var.db_subnet_cidrs) > 0 ? local.nat_gw_count : 0
  vpc_id   = aws_vpc.websites.id
  tags = merge(
    {
      "Name" = "rt-private_subnets-${count.index + 1}"
    }
  )
}

###
# Associate route table with public subnets
# -----------------------------------------
###
resource "aws_route_table_association" "public" {
  provider       = aws
  count          = length(var.public_subnet_cidrs) > 0 ? length(var.public_subnet_cidrs) : 0
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

###
# Associate private route table(s) with private subnets
###
resource "aws_route_table_association" "private" {
  provider       = aws
  count          = length(var.private_subnet_cidrs) > 0 ? length(var.private_subnet_cidrs) : 0
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

###
# Associate private route table(s) with database subnets
###
resource "aws_route_table_association" "db_subnets" {
  provider       = aws
  count          = length(var.db_subnet_cidrs) > 0 ? length(var.db_subnet_cidrs) : 0
  subnet_id      = element(aws_subnet.private_db_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

###
# VPC Main Route Table association
# --------------------------------
###
resource "aws_main_route_table_association" "private" {
  provider       = aws
  count          = length(var.private_subnet_cidrs) > 0 ? 1 : 0
  vpc_id         = aws_vpc.websites.id
  route_table_id = element(aws_route_table.private.*.id, 0)
}

###
# If public subnets exist, but no private subnets exist, then force the public route table to be 
# the main route table for the VPC
###
resource "aws_main_route_table_association" "public" {
  provider       = aws
  count          = length(var.public_subnet_cidrs) > 0 && length(var.private_subnet_cidrs) == 0 ? 1 : 0
  vpc_id         = aws_vpc.websites.id
  route_table_id = aws_route_table.public[0].id
}

###
resource "aws_main_route_table_association" "db_private" {
  provider       = aws
  count          = length(var.db_subnet_cidrs) > 0 && length(var.private_subnet_cidrs) == 0 && length(var.public_subnet_cidrs) == 0 ? 1 : 0
  vpc_id         = aws_vpc.websites.id
  route_table_id = aws_route_table.private[0].id
}

###
# Route(s) to the internet from the Public Route Table if enable_igw is true
###
resource "aws_route" "igw_default_route" {
  provider               = aws
  count                  = var.enable_igw && length(var.public_subnet_cidrs) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}
