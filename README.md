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
| instance_type | EC2 instance type | t4g.medium |
| db_name | RDS database name | appdb |
| db_instance_class | RDS instance class | db.t4g.medium |
| domain_name | Domain name for Route53 and SES configuration | - |
| admin_email | Admin email for notifications and certifications | - |

### SES Configuration

The SES module sets up:
- Domain identity verification
- DKIM configuration
- SMTP user with appropriate IAM permissions
- Integration with Route53 for automatic DNS record creation

The SMTP credentials will be available in the Terraform outputs for use in your applications.

## Module Structure

- `modules/vpc`: VPC and networking configuration
- `modules/ec2`: EC2 instance and security group configuration
- `modules/rds`: RDS database configuration
- `modules/s3`: S3 bucket configuration
- `modules/ses`: SES email service configuration for sending emails
- `modules/route53`: DNS configuration and SES domain verification

## Security Considerations

- Database credentials should be managed securely and never committed to version control
- EC2 instances are placed in public subnets with appropriate security groups
- RDS instances are placed in private subnets for enhanced security
- All sensitive variables are marked as sensitive in Terraform

## Application Deployment

After the infrastructure is set up, you'll need to deploy both the Next.js and Spring Boot applications.

### Next.js Application Deployment

1. Build your Next.js app locally:
```bash
npm run build
```

2. Copy the application to the server (excluding node_modules and .next):
```bash
rsync -avz --exclude 'node_modules' --exclude '.next' ./ ec2-user@<server-ip>:/opt/nextjs/
```

3. SSH into the server and build:
```bash
ssh ec2-user@<server-ip>
cd /opt/nextjs
npm install
npm run build
```

4. Start the service:
```bash
sudo systemctl start nextjs
```

### Spring Boot Application Deployment

1. Build your Spring Boot application locally:
```bash
./mvnw clean package
```

2. Copy the JAR file to the server:
```bash
scp target/your-app.jar ec2-user@<server-ip>:/opt/springboot/app.jar
```

3. Start the service:
```bash
sudo systemctl start springboot
```

### Monitoring Services

Check service status:
```bash
# For Next.js
sudo systemctl status nextjs
sudo journalctl -u nextjs -f

# For Spring Boot
sudo systemctl status springboot
sudo journalctl -u springboot -f
```

### SSL Certificates

SSL setup should be done after DNS propagation is complete:

1. Ensure your domain's DNS is pointing to the EC2 instance
2. Wait for DNS propagation (usually 15-30 minutes, can take up to 48 hours)
3. Verify DNS propagation:
   ```bash
   dig your-domain.com
   ```

4. Run Certbot:
   ```bash
   sudo certbot --nginx -d your-domain.com --agree-tos -m your-email@domain.com --redirect
   ```

Certbot will automatically add a renewal cron job. To manually force renewal:
```bash
sudo certbot renew
```

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