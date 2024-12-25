variable "domain_name" {
  description = "The domain name for the Route53 zone"
  type        = string
}

variable "environment" {
  description = "Environment tag value"
  type        = string
}

variable "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  type        = string
}
