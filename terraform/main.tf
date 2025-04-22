provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, <5.0"
    }
  }

  backend "s3" {
    bucket       = ""
    key          = ""
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  availaibility_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

# All modules are called from here, they should be added/removed in thsi file

module "networking" {
  source               = "./modules/networking"
  region               = var.region
  environment          = var.environment
  platform             = var.platform
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = local.availaibility_zones
  cluster_name         = var.cluster_name
}

module "iam" {
  depends_on = [module.networking]

  source      = "./modules/iam"
  environment = var.environment
  platform    = var.platform
}

module "cluster" {
  depends_on = [module.iam]

  source                 = "./modules/cluster"
  cluster_name           = var.cluster_name
  nodegroup_name         = var.nodegroup_name
  public_subnet_ids      = module.networking.public_subnet_ids
  private_subnet_ids     = module.networking.private_subnet_ids
  eks_cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.node_role_arn
  instance_types         = var.instance_types
  capacity_type          = var.capacity_type
  nodegroup_desired_size = var.nodegroup_desired_size
  nodegroup_max_size     = var.nodegroup_max_size
  nodegroup_min_size     = var.nodegroup_min_size
}

module "oidc" {
  depends_on = [module.cluster]

  source      = "./modules/oidc"
  environment = var.environment
  eks_cluster = module.cluster.eks_cluster
}