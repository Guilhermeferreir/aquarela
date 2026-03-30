region = "us-east-1"

use_existing_vpc = true
existing_vpc_id  = "vpc-03e89d05d2057a190"

existing_public_subnet_name_tags = [
  "vpc-desafio-devops-public-us-east-1a",
  "vpc-desafio-devops-public-us-east-1b",
]

existing_private_subnet_name_tags = [
  "vpc-desafio-devops-private-us-east-1a",
  "vpc-desafio-devops-private-us-east-1b",
]

existing_control_plane_subnet_name_tags = [
  "vpc-desafio-devops-private-us-east-1a",
  "vpc-desafio-devops-private-us-east-1b",
]

use_existing_desafio_aquarela_user  = true
existing_desafio_aquarela_user_name = "desafio_aquarela"

public_access_cidrs = [
  "0.0.0.0/0",
]

node_group_instance_types = [
  "t3.medium",
]

node_group_desired_size = 4
node_group_min_size     = 2
node_group_max_size     = 6

tags = {
  Owner = "Guilhermeferreir"
}