# -------------------------------------------------------------
# Network variables
# -------------------------------------------------------------

variable "region" {
  description = "The AWS region we wish to provision in, by default"
  type        = string
  default     = "us-west-1"
}

variable "vpc_cidr" {
  description = "The CIDR range for the VPC"
  type        = string
}

variable "azs" {
  description = "A list of Availability Zones to use in a specific Region"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of the CIDR ranges to use for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "A list of the CIDR ranges to use for private subnets"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "A list of the CIDR ranges for database subnets"
  type        = list(string)
}

variable "enable_igw" {
  description = "True if you want an igw added to your public route table"
  type        = bool
  default     = true
}

# -------------------------------------------------------------
# Security variables
# -------------------------------------------------------------
variable "icmp_diagnostics_enable" {
  description = "Enable full icmp for diagnostic purposes"
  type        = bool
  default     = false
}

variable "enable_nacls" {
  description = "Enable creation of restricted-by-default network acls."
  type        = bool
  default     = true
}

variable "allow_inbound_traffic_default_public_subnet" {
  description = "A list of maps of inbound traffic allowed by default for public subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))

  default = [
    {
      # ephemeral tcp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "udp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 80
      to_port   = 80
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 443
      to_port   = 443
      source    = "0.0.0.0/0"
    }
  ]
}

variable "allow_inbound_traffic_public_subnet" {
  description = "The inbound traffic the customer needs to allow for public subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))
  default = []
}

variable "allow_inbound_traffic_default_private_subnet" {
  description = "A list of maps of inbound traffic allowed by default for private subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))

  default = [
    {
      # ephemeral tcp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "udp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
  ]
}

variable "allow_inbound_traffic_private_subnet" {
  description = "The ingress traffic the customer needs to allow for private subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))
  default = []
}

//////////// RDS ///////////

variable "cluster_instances_identifier_prefix" {
  description = <<-EOT
        The cluster instance identifier prefix.
    EOT
  type        = string
  default     = null
}

variable "cluster_identifier_prefix" {
  description = <<-EOT
        Creates a unique cluster identifier beginning with the specified prefix. Conflicts with `cluster_identifier`.
    EOT
  type        = string
  default     = null
}

variable "database_name" {
  description = <<-EOT
        Name for an automatically created database on cluster creation.
    EOT
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = <<-EOT
        If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true.
    EOT
  type        = string
  default     = false
}

variable "master_password" {
  description = <<-EOT
        Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file.
        If not set a default password will be generated.
    EOT
  type        = string
  default     = "Pkxis231ewpsas"
  sensitive   = true
}

variable "master_username" {
  description = <<-EOT
        Username for the master DB user. Please refer to the RDS Naming Constraints. This argument does not support in-place updates and cannot be changed during a restore from snapshot.
    EOT
  type        = string
  default     = "yc_admin"
}

variable "availability_zones" {
  description = <<-EOT
        A list of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created.
        If ommited, all AZs in the region will be used.
    EOT
  type        = list(string)
}

variable "backup_retention_period" {
  description = <<-EOT
        The days to retain backups for.
    EOT
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = <<-EOT
        The daily time range during which automated backups are created if
        automated backups are enabled using the BackupRetentionPeriod parameter.
        Time in UTC e.g. 04:00-09:00 
    EOT
  type        = string
  default     = "04:00-09:00"
}

variable "preferred_maintenance_window" {
  description = <<-EOT
        The weekly time range during which system maintenance can occur, in (UTC) e.g. wed:04:00-wed:04:30
    EOT
  type        = string
  default     = "wed:03:00-wed:03:30"
}

variable "vpc_security_group_ids" {
  description = <<-EOT
        List of VPC security groups to associate with the Cluster.
    EOT
  type        = list(string)
  default     = null
}

variable "storage_encrypted" {
  description = <<-EOT
        Specifies whether the DB cluster is encrypted.
    EOT
  type        = string
  default     = "true"
}

variable "apply_immediately" {
  description = <<-EOT
        Specifies whether any cluster modifications are applied immediately, or during the next maintenance window.
    EOT
  type        = string
  default     = "true"
}

variable "iam_roles" {
  description = <<-EOT
         A List of ARNs for the IAM roles to associate to the RDS Cluster.
    EOT
  type        = list(string)
  default     = null
}

variable "engine" {
  description = <<-EOT
        The name of the database engine to be used for this DB cluster.
    EOT
  type        = string
}

variable "engine_mode" {
  description = <<-EOT
        The database engine mode. Valid values: `global`, `multimaster`, `parallelquery`, `provisioned`, `serverless`.
    EOT
  type        = string
  default     = "provisioned"
}

variable "engine_version" {
  description = <<-EOT
        The database engine version. Updating this argument results in an outage.
        See the Aurora MySQL and Aurora Postgres documentation for your configured
        engine to determine this value. 
        For example with Aurora MySQL 2, a potential value for this argument is 5.7.mysql_aurora.2.03.2
    EOT
  type        = string
}

variable "allowed_security_groups" {
  description = <<-EOT
        List of security group IDs that may access the database.
    EOT
  type        = list(string)
  default     = null
}

variable "allowed_cidr_blocks" {
  description = <<-EOT
        List of CIDR blocks that may access the database.
    EOT
  type        = list(string)
  default     = null
}

variable "db_instance_count" {
  description = <<-EOT
        Number of database instances to create.
    EOT
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = <<-EOT
        The instance class to use.
    EOT
  type        = string
  default     = "db.t3.medium"
}

variable "db_parameters" {
  description = <<-EOT
        Map of database parameters to set.
    EOT
  type        = map(string)
  default     = {}
}

variable "final_snapshot_identifier" {
  description = <<-EOT
        The final_snapshot_identifier.
    EOT
  type        = string
  default     = null
}

variable "subnet_group_name" {
  description = <<-EOT
        The name of subnet_group.
    EOT
  type        = string
  default     = null
}

variable "subnet_group_name_prefix" {
  description = <<-EOT
        The name_prefix of subnet_group.
    EOT
  type        = string
  default     = "db-subnet-group-"
}

variable "subnet_group_tags" {
  description = <<-EOT
        The tags for subnet_group.
    EOT
  type        = map(string)
  default     = null
}

variable "security_group_name" {
  description = <<-EOT
        The name of security_group.
    EOT
  type        = string
  default     = null
}

variable "security_group_name_prefix" {
  description = <<-EOT
        The name_prefix of security_group.
    EOT
  type        = string
  default     = "db-security-group-"
}

variable "security_group_description" {
  description = <<-EOT
        The description of security_group.
    EOT
  type        = string
  default     = "RDS Security Group"
}

variable "security_group_tags" {
  description = <<-EOT
        The tags for security_group.
    EOT
  type        = map(string)
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = <<-EOT
    Indicates that minor engine upgrades will be applied 
    automatically to the DB instance during the maintenance window.
  EOT
  type        = bool
  default     = false
}

variable "admin_public_ip" {
  type        = string
  description = "List of public IP"
}

variable "image_id" {
  type        = string
  description = "Custom Image id generated with Packer"
}

