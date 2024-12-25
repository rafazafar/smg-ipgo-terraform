# Required AWS Permissions

This document outlines the AWS IAM permissions required to deploy the infrastructure using Terraform.

## Core Services and Required Permissions

### VPC and Networking
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpc",
                "ec2:DeleteVpc",
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:CreateInternetGateway",
                "ec2:DeleteInternetGateway",
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:CreateNatGateway",
                "ec2:DeleteNatGateway",
                "ec2:AllocateAddress",
                "ec2:ReleaseAddress"
            ],
            "Resource": "*"
        }
    ]
}
```

### EC2
```json
{
    "Effect": "Allow",
    "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:CreateTags",
        "iam:PassRole"
    ],
    "Resource": "*"
}
```

### RDS
```json
{
    "Effect": "Allow",
    "Action": [
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:ModifyDBInstance",
        "rds:DescribeDBInstances"
    ],
    "Resource": "*"
}
```

### Route 53
```json
{
    "Effect": "Allow",
    "Action": [
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones"
    ],
    "Resource": "*"
}
```

### S3
```json
{
    "Effect": "Allow",
    "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutObject",
        "s3:DeleteObject"
    ],
    "Resource": "*"
}
```

### SES
```json
{
    "Effect": "Allow",
    "Action": [
        "ses:CreateEmailIdentity",
        "ses:DeleteEmailIdentity",
        "ses:GetEmailIdentity",
        "ses:VerifyEmailIdentity"
    ],
    "Resource": "*"
}
```

## Setup Instructions

1. Create a new IAM Policy:
   - Go to AWS IAM Console
   - Create a new policy
   - Copy and combine the above JSON permissions
   - Name it appropriately (e.g., `ipgo-terraform-deployment-policy`)

2. Create an IAM User:
   - Create a new IAM user for Terraform deployments
   - Attach the created policy to this user
   - Enable programmatic access to generate access keys

3. Configure AWS Credentials:
   ```bash
   aws configure
   ```
   Enter the access key ID and secret access key when prompted.

## Best Practices

1. Follow the principle of least privilege
2. Use separate credentials for different environments (dev/staging/prod)
3. Consider using AWS Organizations and SCPs for production environments
4. Regularly rotate access keys
5. Enable MFA for the IAM user

## Notes

- The above permissions use `"Resource": "*"` for simplicity. In production, you should restrict resources to specific ARNs
- Some services might require additional permissions depending on your specific configuration
- Always review and adjust permissions based on your security requirements
