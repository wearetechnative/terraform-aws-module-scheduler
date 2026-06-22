data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  route53_zone_name = trimsuffix(lower(trimspace(var.route53_zone_name)), ".")
  frontend_fqdn     = trimsuffix(lower(trimspace(var.frontend_fqdn)), ".")
  cognito_domain_prefix = substr(
    "${replace(lower(var.bucket_name), ".", "-")}-${data.aws_caller_identity.current.account_id}",
    0,
    63
  )
  application_url = "https://${local.frontend_fqdn}"
  callback_url    = "${local.application_url}/index.html"
}

resource "aws_route53_zone" "scheduler" {
  name = local.route53_zone_name
}

resource "aws_acm_certificate" "scheduler" {
  provider          = aws.us_east_1
  domain_name       = local.frontend_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.scheduler.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = aws_route53_zone.scheduler.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "scheduler" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.scheduler.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_cognito_user_pool" "scheduler" {
  name                     = "${var.bucket_name}-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_domain" "scheduler" {
  domain       = local.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.scheduler.id
}

resource "aws_cognito_user_pool_client" "scheduler" {
  name         = "${var.bucket_name}-web"
  user_pool_id = aws_cognito_user_pool.scheduler.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = [local.callback_url]
  logout_urls                          = [local.callback_url]
  prevent_user_existence_errors        = "ENABLED"

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cloudfront_origin_access_control" "webpage" {
  name                              = "${var.bucket_name}-oac"
  description                       = "Private access to the instance scheduler website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "webpage" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  comment             = "Authenticated instance scheduler frontend"
  aliases             = [local.frontend_fqdn]

  origin {
    domain_name              = aws_s3_bucket.webpage_bucket.bucket_regional_domain_name
    origin_id                = "scheduler-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.webpage.id
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.my_api.api_endpoint, "https://", "")
    origin_id   = "scheduler-api-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "scheduler-s3-origin"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/db*"
    target_origin_id       = "scheduler-api-origin"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "https-only"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api.id
  }

  ordered_cache_behavior {
    path_pattern           = "/instances*"
    target_origin_id       = "scheduler-api-origin"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "https-only"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api.id
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.scheduler.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "${var.bucket_name}-api-request"
  comment = "Forward authenticated scheduler API requests"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"

    headers {
      items = [
        "Authorization",
        "Content-Type",
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_route53_record" "frontend_ipv4" {
  zone_id = aws_route53_zone.scheduler.zone_id
  name    = local.frontend_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.webpage.domain_name
    zone_id                = aws_cloudfront_distribution.webpage.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_ipv6" {
  zone_id = aws_route53_zone.scheduler.zone_id
  name    = local.frontend_fqdn
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.webpage.domain_name
    zone_id                = aws_cloudfront_distribution.webpage.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.my_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.scheduler.id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.scheduler.id}"
  }
}
