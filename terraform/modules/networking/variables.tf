variable "region" {
  description = "AWS cloud region"
}

variable "platform" {
  description = "Associated Platform"
}

variable "environment" {
  description = "Resource Environment"
}

variable "cluster_name" {
  description = "name of the cluster"
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
}

variable "public_subnet_cidr" {
  type        = list
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "CIDR block for Private Subnet"
}

variable "availability_zones" {
  type        = list
  description = "AZ in which all the resources will be deployed"
}


