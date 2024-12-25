resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ec2-sg"
    Environment = var.environment
  }
}

resource "aws_iam_role" "ec2_s3_access" {
  name = "${var.environment}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.environment}-s3-access-policy"
  role = aws_iam_role.ec2_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_s3_access.name
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux_2_arm.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name        = "${var.environment}-app-server-root-volume"
      Environment = var.environment
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install nginx
              yum install -y nginx
              
              # Install Java 17
              yum install -y java-17-amazon-corretto
              
              # Create directories for applications
              mkdir -p /var/www/react-app
              mkdir -p /opt/springboot
              
              # Configure Nginx for React and Spring Boot
              cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONF'
              server {
                  listen 80;
                  server_name _;
                  
                  # React application
                  location / {
                      root /var/www/react-app;
                      try_files $uri $uri/ /index.html;
                  }
                  
                  # Spring Boot API
                  location /api/ {
                      proxy_pass http://localhost:8080/;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_cache_bypass $http_upgrade;
                  }
              }
              NGINX_CONF
              
              # Start and enable nginx
              systemctl start nginx
              systemctl enable nginx
              
              # Create a systemd service for Spring Boot
              cat > /etc/systemd/system/springboot.service <<'SPRING_SERVICE'
              [Unit]
              Description=Spring Boot Application
              After=network.target
              
              [Service]
              Type=simple
              User=root
              ExecStart=/usr/bin/java -jar /opt/springboot/app.jar
              SuccessExitStatus=143
              
              [Install]
              WantedBy=multi-user.target
              SPRING_SERVICE
              
              # Reload systemd and enable the service
              systemctl daemon-reload
              systemctl enable springboot
              EOF

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
  }
}

data "aws_ami" "amazon_linux_2_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]  # Amazon Linux 2023 ARM64
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
