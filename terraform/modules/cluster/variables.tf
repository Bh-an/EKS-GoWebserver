variable "cluster_name" {
  description = "name of the cluster"
}

variable "public_subnet_ids" {
  description = "ids of public subnets"
}

variable "private_subnet_ids" {
  description = "ids for private subnets"
}

variable "eks_cluster_role_arn" {
  description = "arn of the cluster role"
}

variable "node_role_arn" {
  description = "arn of the nodegroup role"
}

variable "instance_types" {
  type        = list  
  description = "list of instance type allowed"
}

variable "nodegroup_name" {
  description = "name of the nodegroup"
}

variable "capacity_type" {
  description = "capacity type for the nodes"
}

variable "nodegroup_desired_size" {
  description = "ASG desired size"
}

variable "nodegroup_max_size" {
  description = "ASG max size"
}

variable "nodegroup_min_size" {
  description = "ASG min size"
}