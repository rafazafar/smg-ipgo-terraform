# SES SMTP Credentials
output "ses_smtp_username" {
  description = "SMTP username for SES"
  value       = module.ses.smtp_username
}

output "ses_smtp_password" {
  description = "SMTP password for SES"
  value       = module.ses.smtp_password
  sensitive   = true
}
