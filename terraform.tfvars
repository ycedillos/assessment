region               = "us-west-1"
vpc_cidr             = "10.0.0.0/16"
azs                  = ["us-west-1a", "us-west-1b"]
public_subnet_cidrs  = ["10.0.0.0/23", "10.0.2.0/23"]
private_subnet_cidrs = ["10.0.10.0/23", "10.0.12.0/23"]
db_subnet_cidrs      = ["10.0.20.0/24", "10.0.21.0/24"]

allow_inbound_traffic_public_subnet = [
  {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    source    = "0.0.0.0/0"
  },
  {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    source    = "0.0.0.0/0"
  },
  {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    source    = "0.0.0.0/0"
  },
]
map_to_public_ip = true

/////// RDS /////
database_name                       = "ecommercedb"
cluster_instances_identifier_prefix = "yc-db-instance"
cluster_identifier_prefix           = "yc-db-cluster"
availability_zones                  = ["us-west-1a", "us-west-1b"]
engine                              = "aurora-mysql"
engine_version                      = "5.7.mysql_aurora.2.07.5"

admin_public_ip = "0.0.0.0/0"
image_id        = "ami-change-it"

