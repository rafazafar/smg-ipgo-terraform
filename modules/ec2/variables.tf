variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be created"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to grant access to"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the EC2 instance will be created"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
