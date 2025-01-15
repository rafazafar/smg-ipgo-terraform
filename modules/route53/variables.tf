variable "domain_name" {
  description = "The domain name for the Route53 zone"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  type        = string
  validation {
    condition     = length(var.ec2_public_ip) > 0
    error_message = "EC2 public IP cannot be empty"
  }
}

variable "ses_verification_token" {
  description = "The verification token for SES domain verification"
  type        = string
}

variable "ses_dkim_tokens" {
  description = "The DKIM tokens for SES DKIM verification"
  type        = list(string)
}
