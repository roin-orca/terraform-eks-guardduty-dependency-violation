provider "aws" {
  region = var.region
  profile = var.profile
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "null_resource" "vpc_endpoint_cleanup" {
  triggers = {
    profile = var.profile
    vpc_id = module.vpc.vpc_id
  }
  provisioner "local-exec" {
    command = "./scripts/delete_dangling_endpoint.sh ${self.triggers.vpc_id} ${self.triggers.profile}"
    when = destroy
    working_dir = path.module
  }
}

resource "null_resource" "vpc_sg_cleanup" {
  triggers = {
    profile = var.profile
    vpc_id = module.vpc.vpc_id
  }
  provisioner "local-exec" {
    command = "./scripts/delete_dangling_sg.sh ${self.triggers.vpc_id} ${self.triggers.profile}"
    when = destroy
    working_dir = path.module
  }
}

module "eks" {
  depends_on = [null_resource.vpc_sg_cleanup]

  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}