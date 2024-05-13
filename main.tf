provider "aws" {
  region  = var.region
  profile = var.profile
}

module "eks" {
  source = "./modules"

  region       = var.region
  profile      = var.profile
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}