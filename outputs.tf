output "bucket_url" {
  description = "Authenticated CloudFront URL for the scheduler frontend"
  value       = local.application_url
}

output "cloudfront_url" {
  description = "Generated CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.webpage.domain_name}"
}

output "frontend_url" {
  description = "Authenticated custom URL for the scheduler frontend"
  value       = local.application_url
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID used to create scheduler users"
  value       = aws_cognito_user_pool.scheduler.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito app client ID used by the scheduler frontend"
  value       = aws_cognito_user_pool_client.scheduler.id
}

output "cognito_login_domain" {
  description = "Cognito managed-login domain"
  value       = "https://${aws_cognito_user_pool_domain.scheduler.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "route53_zone_id" {
  description = "ID of the created public Route 53 hosted zone"
  value       = aws_route53_zone.scheduler.zone_id
}

output "route53_name_servers" {
  description = "Authoritative name servers; configure these at the domain registrar"
  value       = aws_route53_zone.scheduler.name_servers
}

output "frontend_fqdn" {
  description = "Fully qualified domain name of the scheduler frontend"
  value       = local.frontend_fqdn
}

output "frontend_certificate_arn" {
  description = "ACM certificate used by CloudFront"
  value       = aws_acm_certificate.scheduler.arn
}
