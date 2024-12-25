variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = null  # Can be retrieved from AWS Secrets Manager
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = null  # Can be retrieved from AWS Secrets Manager
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.tg4.medium"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "domain_name" {
  description = "Domain name for Route 53"
  type        = string
}
