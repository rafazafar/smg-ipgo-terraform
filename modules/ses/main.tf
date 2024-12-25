resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_iam_user" "ses_smtp_user" {
  name = "ses-smtp-user"
  path = "/system/"
}

resource "aws_iam_access_key" "ses_smtp_user" {
  user = aws_iam_user.ses_smtp_user.name
}

resource "aws_iam_user_policy" "ses_smtp_policy" {
  name = "ses-smtp-policy"
  user = aws_iam_user.ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output SMTP credentials
output "smtp_username" {
  value = aws_iam_access_key.ses_smtp_user.id
}

output "smtp_password" {
  value     = aws_iam_access_key.ses_smtp_user.ses_smtp_password_v4
  sensitive = true
}
