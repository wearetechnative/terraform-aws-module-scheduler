#creates a lambda function which will start and stop instances according to their tags
# module "aws_kms" {
#   source = "github.com/wearetechnative/terraform-aws-kms.git"
#   name = "new-kms-key"
#   role_access = ["instance_scheduler_lambda_role"]

# }




resource "aws_kms_grant" "a" {
  name              = "my-grant"
  key_id            = "arn:aws:kms:eu-central-1:158565517012:key/74d438bd-bc80-4598-8df7-08f6d4fa6803"
  grantee_principal = module.iam_role_lambda_instance_scheduler.role_arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}


module "lambda_start_stop_instances" {
  source = "github.com/wearetechnative/terraform-aws-lambda.git"
  name              = "TechNative_Instance_Scheduler"
  role_arn          = module.iam_role_lambda_instance_scheduler.role_arn
  role_arn_provided = true
  kms_key_arn       = var.kms_key_arn
  handler     = "ec2_scheduler.handler"
  memory_size = 512
  timeout     = 600
  runtime     = "python3.12"

  source_type               = "local"
  source_directory_location = "${path.module}/lambda"
  source_file_name          = null
  sqs_dlq_arn = var.sqs_arn
} 
#creates a iam role for lambda that has access to describe and start/stop ec2 instances
module "iam_role_lambda_instance_scheduler" {
  source    = "github.com/wearetechnative/terraform-aws-iam-role.git"
  role_name = var.lambda_role_name
  role_path = "/"

  customer_managed_policies = {
    "instance_scheduler" : jsondecode(data.aws_iam_policy_document.instance_scheduler.json)
  }

  trust_relationship = {
    "lambda" : { "identifier" : "lambda.amazonaws.com", "identifier_type" : "Service", "enforce_mfa" : false, "enforce_userprincipal" : false, "external_id" : null, "prevent_account_confuseddeputy" : false }
  }
}

#IAM policy document that has EC2 accesss
data "aws_iam_policy_document" "instance_scheduler" {
  statement {
    sid = "EC2Access"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeTags",
      "ec2:DescribeInstanceStatus",
      "dynamodb:*",
      "kms:*",
      "sqs:SendMessage"
    ]
    resources = ["*"]
  }
}

#creates a eventbridge that triggers tinstance he lambda every 5 minutes
resource "aws_cloudwatch_event_rule" "rule" {
  name                = "Instance_Scheduler"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.rule.name
  target_id = "SendToLambdaInstanceScheduler"
  arn       = module.lambda_start_stop_instances.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge"{
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = module.lambda_start_stop_instances.lambda_function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.rule.arn
}
