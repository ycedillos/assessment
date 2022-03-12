###
# Helpers 
###
locals {
  master_password                     = var.master_password
  vpc_security_group_ids              = var.vpc_security_group_ids == null ? [aws_security_group.ecoomerce_db.id] : concat(var.vpc_security_group_ids, [aws_security_group.ecoomerce_db.id])
  final_snapshot_identifier           = var.final_snapshot_identifier == null ? "db-final-snapshot-${random_id.this.hex}" : var.final_snapshot_identifier
  iam_roles                           = var.iam_roles
  cluster_instances_identifier_prefix = var.cluster_instances_identifier_prefix == null ? aws_rds_cluster.this.cluster_identifier : var.cluster_instances_identifier_prefix
}

resource "random_id" "this" {
  byte_length = 8
}

###

###
# Setup Security Groups for database instances
###
resource "aws_db_subnet_group" "database_subnet" {
  name        = var.subnet_group_name
  name_prefix = var.subnet_group_name_prefix
  subnet_ids  = aws_subnet.private_db_subnets.*.id
  tags        = var.subnet_group_tags
}

resource "aws_security_group" "ecoomerce_db" {
  name        = var.security_group_name
  name_prefix = var.security_group_name_prefix
  description = var.security_group_description
  tags        = var.security_group_tags
  vpc_id      = aws_vpc.websites.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    self            = true
    security_groups = var.allowed_security_groups
    cidr_blocks     = [var.public_subnet_cidrs[0], var.public_subnet_cidrs[1]]
  }

  egress {
    from_port = "3306"
    to_port   = "3306"
    protocol  = "tcp"
    self      = true # For RDS Proxy
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "rds-cluster-${random_id.this.hex}"
  family = "aurora-mysql5.7"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

###
# Setup RDS with Multi AZ
# https://aws.amazon.com/rds/features/multi-az/#:~:text=In%20an%20Amazon%20RDS%20Multi,standby%20instance%20without%20manual%20intervention.
###
resource "aws_rds_cluster" "this" {
  cluster_identifier                  = var.cluster_identifier_prefix
  database_name                       = var.database_name
  deletion_protection                 = var.deletion_protection
  master_password                     = local.master_password
  master_username                     = var.master_username
  availability_zones                  = var.azs
  backup_retention_period             = var.backup_retention_period
  preferred_backup_window             = var.preferred_backup_window
  preferred_maintenance_window        = var.preferred_maintenance_window
  vpc_security_group_ids              = local.vpc_security_group_ids
  storage_encrypted                   = var.storage_encrypted
  apply_immediately                   = var.apply_immediately
  db_subnet_group_name                = aws_db_subnet_group.database_subnet.name
  iam_roles                           = local.iam_roles
  iam_database_authentication_enabled = true
  engine                              = var.engine
  engine_mode                         = var.engine_mode
  engine_version                      = var.engine_version
  final_snapshot_identifier           = local.final_snapshot_identifier
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.this.name
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  for_each                   = toset(var.availability_zones)
  engine                     = var.engine
  engine_version             = var.engine_version
  availability_zone          = each.value
  identifier                 = "${local.cluster_instances_identifier_prefix}-${index(var.availability_zones, each.value)}"
  cluster_identifier         = aws_rds_cluster.this.cluster_identifier
  instance_class             = var.db_instance_class
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
}
