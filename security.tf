# --------------------------------------------------------------------
# Security settings (NACL rules)
# --------------------------------------------------------------------

## Network ACL for public subnets
resource "aws_network_acl" "public_subnets" {
  count      = var.enable_nacls ? 1 : 0
  provider   = aws
  vpc_id     = aws_vpc.websites.id
  subnet_ids = aws_subnet.public_subnets.*.id
  tags = merge(
    {
      "Name" = "acl_public_subnets"
    },
  )
}

## public subnets ACL rule: allow traffic between subnets in the VPC
resource "aws_network_acl_rule" "allow_private_inbound_vpc_traffic_public_subnet" {
  count          = var.enable_nacls ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.public_subnets[0].id
  rule_number    = 50
  egress         = false
  protocol       = -1
  from_port      = 0
  to_port        = 0
  cidr_block     = var.vpc_cidr
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "allow_private_inbound_ssh_traffic_public_subnet" {
  count          = var.enable_nacls ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.public_subnets[0].id
  rule_number    = 256
  egress         = false
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  cidr_block     = var.admin_public_ip
  rule_action    = "allow"
}

## public subnets ACL rule: allow default and custom inbound traffic
resource "aws_network_acl_rule" "allow_inbound_traffic_public_subnet" {
  count          = var.enable_nacls ? length(local.inbound_traffic_public_subnet) : 0
  provider       = aws
  network_acl_id = aws_network_acl.public_subnets[0].id
  rule_number    = 100 + count.index * 10
  egress         = false
  protocol       = local.inbound_traffic_public_subnet[count.index]["protocol"]
  from_port      = local.inbound_traffic_public_subnet[count.index]["from_port"]
  to_port        = local.inbound_traffic_public_subnet[count.index]["to_port"]
  cidr_block     = local.inbound_traffic_public_subnet[count.index]["source"]
  rule_action    = "allow"
}

## public subnets ACL rule: allow outbound traffic
resource "aws_network_acl_rule" "allow_outbound_traffic_public_subnet" {
  count          = var.enable_nacls ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.public_subnets[0].id
  rule_number    = 50
  egress         = true
  protocol       = -1
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

## Network ACL for private subnets
resource "aws_network_acl" "private_subnets" {
  count      = var.enable_nacls ? 1 : 0
  provider   = aws
  vpc_id     = aws_vpc.websites.id
  subnet_ids = local.all_private_subnet_ids
  tags = merge(
    {
      "Name" = "acl_private_subnets"
    },
  )
}

## private subnets ACL rule: allow traffic between subnets in the VPC
resource "aws_network_acl_rule" "allow_private_inbound_vpc_traffic_private_subnet" {
  count          = var.enable_nacls ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.private_subnets[0].id
  rule_number    = 50
  egress         = false
  protocol       = -1
  from_port      = 0
  to_port        = 0
  cidr_block     = var.vpc_cidr
  rule_action    = "allow"
}

## private subnets ACL rule: allow default and custom inbound traffic
resource "aws_network_acl_rule" "allow_inbound_traffic_private_subnet" {
  count          = var.enable_nacls ? length(local.inbound_traffic_private_subnet) : 0
  provider       = aws
  network_acl_id = aws_network_acl.private_subnets[0].id
  rule_number    = 100 + count.index * 10
  egress         = false
  protocol       = local.inbound_traffic_private_subnet[count.index]["protocol"]
  from_port      = local.inbound_traffic_private_subnet[count.index]["from_port"]
  to_port        = local.inbound_traffic_private_subnet[count.index]["to_port"]
  cidr_block     = local.inbound_traffic_private_subnet[count.index]["source"]
  rule_action    = "allow"
}

## private subnets ACL rule: allow outbound traffic
resource "aws_network_acl_rule" "allow_outbound_traffic_private_subnet" {
  count          = var.enable_nacls ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.private_subnets[0].id
  rule_number    = 50
  egress         = true
  protocol       = -1
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

## Optionally enable all of icmp for diagnostics
resource "aws_network_acl_rule" "allow_inbound_icmp_private_subnet" {
  count          = var.enable_nacls && var.icmp_diagnostics_enable ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.private_subnets[0].id
  rule_number    = 255
  egress         = false
  protocol       = "icmp"
  icmp_type      = -1
  icmp_code      = -1
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "allow_inbound_icmp_public_subnet" {
  count          = var.enable_nacls && var.icmp_diagnostics_enable ? 1 : 0
  provider       = aws
  network_acl_id = aws_network_acl.public_subnets[0].id
  rule_number    = 255
  egress         = false
  protocol       = "icmp"
  icmp_type      = -1
  icmp_code      = -1
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

#############
## Web Server
resource "aws_security_group" "web_http_sg" {
  name = "web-http-sg"

  vpc_id = aws_vpc.websites.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0

    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_https_sg" {
  name   = "web-https-sg"
  vpc_id = aws_vpc.websites.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_ssh_sg" {
  name = "web-ssh-sg"

  vpc_id = aws_vpc.websites.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_public_ip]
  }
}
