output "domain_verification_record" {
  description = "The TXT record to add to DNS for domain verification"
  value = {
    name  = "_amazonses.${aws_ses_domain_identity.main.domain}"
    type  = "TXT"
    value = aws_ses_domain_identity.main.verification_token
  }
}

output "dkim_records" {
  description = "The CNAME records to add to DNS for DKIM verification"
  value = [
    for token in aws_ses_domain_dkim.main.dkim_tokens : {
      name  = "${token}._domainkey.${aws_ses_domain_identity.main.domain}"
      type  = "CNAME"
      value = "${token}.dkim.amazonses.com"
    }
  ]
}

output "smtp_username" {
  value = aws_iam_access_key.ses_smtp_user.id
}

output "smtp_password" {
  value     = aws_iam_access_key.ses_smtp_user.ses_smtp_password_v4
  sensitive = true
}

output "verification_token" {
  description = "The verification token for SES domain verification"
  value       = aws_ses_domain_identity.main.verification_token
}

output "dkim_tokens" {
  description = "The DKIM tokens for SES DKIM verification"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}
