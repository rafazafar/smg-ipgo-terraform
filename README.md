# SMG IPGO Infrastructure as Code

This repository contains Terraform configurations for deploying and managing the IPGO infrastructure on AWS.

## Architecture Overview

The infrastructure consists of the following main components:

- VPC with public and private subnets across multiple availability zones
- EC2 instances in public subnets
- RDS database in private subnets
- S3 bucket for storage
- Associated security groups and networking components

## Prerequisites

- Terraform >= 1.2.0
- AWS CLI configured with appropriate credentials
- SSH key pair for EC2 instance access

## Quick Start

1. Clone this repository:
```bash
git clone <repository-url>
cd smg-ipgo-terraform
```

2. Initialize Terraform:
```bash
terraform init
```

3. Copy the example variables file and update it with your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` with your specific values. At minimum, you need to set:
- `aws_region` - AWS region for deployment
- `key_name` - Your SSH key pair name in AWS
- `db_username` - Desired database username
- `db_password` - Secure database password
- `s3_bucket_name` - Globally unique S3 bucket name
- `domain_name` - Your Route 53 domain name

4. Review the planned changes:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

## Configuration Variables

### Required Variables

| Variable | Description |
|----------|-------------|
| aws_region | AWS region for deployment (e.g., ap-northeast-1) |
| key_name | SSH key pair name |
| db_username | Database username |
| db_password | Database password |
| s3_bucket_name | Globally unique S3 bucket name |
| domain_name | Route 53 domain name |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| environment | Environment name | production |
| vpc_cidr | CIDR block for VPC | 10.0.0.0/16 |
| availability_zones | List of AZs | ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"] |
| instance_type | EC2 instance type | t4g.micro |
| db_name | RDS database name | appdb |
| db_instance_class | RDS instance class | db.t4g.medium |

## Module Structure

- `modules/vpc`: VPC and networking configuration
- `modules/ec2`: EC2 instance and security group configuration
- `modules/rds`: RDS database configuration
- `modules/s3`: S3 bucket configuration

## Security Considerations

- Database credentials should be managed securely and never committed to version control
- EC2 instances are placed in public subnets with appropriate security groups
- RDS instances are placed in private subnets for enhanced security
- All sensitive variables are marked as sensitive in Terraform

## Maintenance

To update the infrastructure:

1. Make necessary changes to the Terraform files
2. Run `terraform plan` to review changes
3. Apply changes with `terraform apply`

To destroy the infrastructure:
```bash
terraform destroy
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request