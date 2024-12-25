terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC and Network Configuration
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

# EC2 Instance Configuration
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  environment         = var.environment
  instance_type       = "t4g.medium"
  key_name            = var.key_name
  s3_bucket_name      = var.s3_bucket_name
  domain_name         = var.domain_name
  admin_email         = var.admin_email
}

# RDS Configuration
module "rds" {
  source = "./modules/rds"
  
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  environment           = var.environment
  database_name         = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  instance_class        = var.db_instance_class
  ec2_security_group_id = module.ec2.security_group_id
}

# S3 Configuration
module "s3" {
  source = "./modules/s3"
  
  bucket_name         = var.s3_bucket_name
  environment         = var.environment
}

# Route 53 Configuration
module "route53" {
  source = "./modules/route53"
  
  domain_name         = var.domain_name
  environment         = var.environment
  ec2_public_ip       = module.ec2.public_ip
}

# SES Configuration
module "ses" {
  source = "./modules/ses"
  
  domain_name = var.domain_name
}
