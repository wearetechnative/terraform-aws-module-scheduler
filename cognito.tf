module "scheduler_website" {

  source = "TechNative-B-V/static-website-cognito-auth/aws"

  name                            = "scheduler"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
  domain                          = "scheduler.technative.cloud"
  route53_zone_name               = "scheduler.technative.cloud"

  deploy_user_name                = "scheduler_user"

  cognito_path_refresh_auth       = "/refreshauth"
  cognito_path_logout             = "/logout"
  cognito_path_parse_auth         = "/parseauth"
  cognito_refresh_token_validity  = 3650
  cognito_domain_prefix           = "login"

  providers = {
    aws.us-east-1: aws.us-east-1
  }
}

output "docs_example_website_deploy_key_id" {
  value = module.docs_example_website.iam_access_key_id
}

output "docs_example_website_deploy_key_secret" {
  value = module.docs_example_website.iam_access_key_secret
  sensitive = true
}
