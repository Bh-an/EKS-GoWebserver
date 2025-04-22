variable "region" {
  description = "AWS cloud region"
  default     = "ap-south-1"
}

variable "platform" {
  description = "Associated Platform"
  default     = "k8s"
}

variable "environment" {
  description = "Resource Environment"
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "CIDR block for Public Subnet"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "CIDR block for Private Subnet"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "cluster_name" {
  description = "Name of the cluster"
  default     = "default_cluster"
}

variable "instance_types" {
  type        = list(any)
  description = "List of instance type allowed"
  default     = ["t3.small"]
}

variable "nodegroup_name" {
  description = "Name of the Nodegroup"
  default     = "default_nodegroup"
}

variable "capacity_type" {
  description = "Capacity type for the nodes"
  default     = "ON_DEMAND"
}

variable "nodegroup_desired_size" {
  description = "ASG desired size"
  default     = 1
}

variable "nodegroup_max_size" {
  description = "ASG max size"
  default     = 4
}

variable "nodegroup_min_size" {
  description = "ASG min size"
  default     = 0
}

