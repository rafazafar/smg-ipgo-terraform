output "security_group_id" {
  description = "The ID of the EC2 instance security group"
  value       = aws_security_group.ec2.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}
