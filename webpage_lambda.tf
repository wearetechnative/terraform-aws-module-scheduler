

module "webpage_lambda" {
  source = "github.com/wearetechnative/terraform-aws-lambda.git"
  name              = "webpage_hosting_s3"
  role_arn          = module.iam_role_webpage_scheduler.role_arn
  role_arn_provided = true
  kms_key_arn       = var.kms_key_arn

  handler     = "lambda.handler"
  memory_size = 512
  timeout     = 600
  runtime     = "python3.12"

  source_type               = "local"
  source_directory_location = "${path.module}/webpage_lambda"
  source_file_name          = null
  sqs_dlq_arn = var.sqs_arn
  environment_variables = {
    TABLENAME = var.dynamodb_table_name  
  }
}

#creates a iam role for lambda that has access to describe and start/stop ec2 instances
module "iam_role_webpage_scheduler" {
  source    = "github.com/wearetechnative/terraform-aws-iam-role.git"
  role_name = "webpage-${var.lambda_role_name}"
  role_path = "/"

  customer_managed_policies = {
    "launch_ec2" : jsondecode(data.aws_iam_policy_document.launch_ec2.json)
  }

  trust_relationship = {
    "lambda" : { "identifier" : "lambda.amazonaws.com", "identifier_type" : "Service", "enforce_mfa" : false, "enforce_userprincipal" : false, "external_id" : null, "prevent_account_confuseddeputy" : false }
  }
}

#IAM policy document that has EC2 accesss
data "aws_iam_policy_document" "launch_ec2" {
  statement {
    sid = "EC2Access"
    actions = [
      "ec2:*",
      "kms:*",
      "dynamodb:*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_grant" "webpage_scheduler_role" {
  name              = "grant-webpage_scheduler_role"
  key_id            = var.kms_key_arn
  grantee_principal = module.iam_role_webpage_scheduler.role_arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

