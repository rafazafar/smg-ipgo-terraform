resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-db-instance"
  allocated_storage    = 20
  max_allocated_storage = 100  # Enables autoscaling up to 100GB
  storage_type         = "gp3"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t4g.medium"
  db_name             = var.database_name
  username            = var.db_username
  password            = var.db_password
  
  # Backup configuration
  backup_retention_period = 7  # Keep backups for 7 days
  backup_window          = "03:00-04:00"  # UTC time
  maintenance_window     = "Mon:04:00-Mon:05:00"  # UTC time
  
  
  # Performance and monitoring
  monitoring_interval = 60  # Enhanced monitoring every 60 seconds
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled = true
  performance_insights_retention_period = 7  # Days to retain performance insights data
  
  # Network and security
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  multi_az              = false  # Set to true if you want high availability
  
  # Storage configuration
  storage_encrypted     = true
  
  # Deletion protection
  deletion_protection  = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.environment}-db-final-snapshot"

  tags = {
    Name        = "${var.environment}-db-instance"
    Environment = var.environment
  }
}

# IAM role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
