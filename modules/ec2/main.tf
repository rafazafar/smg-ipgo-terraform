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

# Add SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
              
              # Install nginx and certbot
              yum install -y nginx
              yum install -y python3-pip
              pip3 install certbot certbot-nginx
              
              # Install Node.js 22.x
              curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
              yum install -y nodejs
              
              # Install PM2 globally
              npm install -g pm2
              
              # Install Java 17
              yum install -y java-17-amazon-corretto
              
              # Create directories for applications
              mkdir -p /opt/nextjs
              mkdir -p /opt/springboot
              chmod 755 /opt/nextjs
              chmod 755 /opt/springboot
              
              # Configure Nginx for Next.js and Spring Boot with SSL
              cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONF'
              server {
                  listen 80;
                  server_name ${var.domain_name};
                  
                  location / {
                      return 301 https://$host$request_uri;
                  }
              }

              server {
                  listen 443 ssl;
                  server_name ${var.domain_name};
                  
                  # SSL configuration will be added by certbot
                  
                  # Next.js application
                  location / {
                      proxy_pass http://localhost:3000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_cache_bypass $http_upgrade;
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
              
              # Request SSL certificate
              certbot --nginx -d ${var.domain_name} --non-interactive --agree-tos -m ${var.admin_email} --redirect
              
              # Add cronjob for automatic renewal
              echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null
              
              # Create a systemd service for Next.js
              cat > /etc/systemd/system/nextjs.service <<'NEXTJS_SERVICE'
              [Unit]
              Description=Next.js Application
              After=network.target
              
              [Service]
              Type=simple
              User=root
              WorkingDirectory=/opt/nextjs
              Environment=NODE_ENV=production
              ExecStart=/usr/bin/pm2 start npm --name "nextjs" -- start
              ExecStop=/usr/bin/pm2 stop nextjs
              Restart=always
              
              [Install]
              WantedBy=multi-user.target
              NEXTJS_SERVICE
              
              # Create a systemd service for Spring Boot
              cat > /etc/systemd/system/springboot.service <<'SPRING_SERVICE'
              [Unit]
              Description=Spring Boot Application
              After=network.target
              
              [Service]
              Type=simple
              User=root
              WorkingDirectory=/opt/springboot
              ExecStart=/usr/bin/java -jar /opt/springboot/app.jar
              SuccessExitStatus=143
              Restart=always
              
              [Install]
              WantedBy=multi-user.target
              SPRING_SERVICE
              
              # Create deployment instructions for Spring Boot
              cat > /opt/springboot/DEPLOY_INSTRUCTIONS.txt <<'INSTRUCTIONS'
              To deploy the Spring Boot application:
              1. Build your JAR file locally
              2. Copy it to this server:
                 scp target/your-app.jar ec2-user@<server-ip>:/opt/springboot/app.jar
              3. Start the service:
                 sudo systemctl start springboot
              
              The service is enabled to auto-start but needs the JAR file first.
              INSTRUCTIONS

              # Create deployment instructions for Next.js
              cat > /opt/nextjs/DEPLOY_INSTRUCTIONS.txt <<'INSTRUCTIONS'
              To deploy the Next.js application:
              1. Build your Next.js app locally:
                 npm run build
              
              2. Copy the entire app directory to the server:
                 rsync -avz --exclude 'node_modules' --exclude '.next' ./ ec2-user@<server-ip>:/opt/nextjs/
              
              3. On the server, install dependencies and build:
                 cd /opt/nextjs
                 npm install
                 npm run build
              
              4. Start the service:
                 sudo systemctl start nextjs
              
              Note: The service is enabled to auto-start but needs the application code first.
              INSTRUCTIONS
              
              # Reload systemd and enable services (but don't start them yet)
              systemctl daemon-reload
              systemctl enable nextjs
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
