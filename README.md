# Terraform AWS [Scheduler] ![](https://img.shields.io/github/workflow/status/TechNative-B-V/terraform-aws-module-name/tflint.yaml?style=plastic)

<!-- SHIELDS -->

This module allows you to start and stop instances on a defined schedule. The schedules are stored in a DynamoDB table along with their time periods.

# Key Concepts

### Schedule
A named schedule that defines when instances tagged with that schedule should run. The schedule name is used as the value for the InstanceScheduler tag on any instance you want to manage via this module.

### Period
Each schedule has one or more periods. A period defines a set of rules about which days, what timezone, what start time, and what end time the schedule applies.

## Period Attributes

Each period includes the following:

##  Attribute Description
    weekdays -  One or more days of the week when the period is active.You can use multiple days.(e.g. mon, tue, fri)
                Valid abbreviations: mon, tue,  wed, thu, fri, sat, sun.
    timezone -  The timezone for interpreting begintime and endtime.UTC is the default timezone.                       
    begintime-  The time of day when instances should start (in 24-hour format, e.g. 09:00).
    endtime  -  The time of day when instances should stop (in 24-hour format, e.g. 17:00).

### Rules & Examples

Each schedule must have at least one period.

You can have multiple periods within a schedule (for instance, one for weekdays 9-17, another for weekends).

Times are in 24-hour format.

Days must use consistent abbreviations (e.g. mon, tue, etc.).

[![](we-are-technative.png)](https://www.technative.nl)

## How does it work

### First use after you clone this repository or when .pre-commit-config.yaml is updated

Run `pre-commit install` to install any guardrails implemented using pre-commit.

See [pre-commit installation](https://pre-commit.com/#install) on how to install pre-commit.

...

## Usage

To use this module ...


```hcl
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "scheduler"{
    source = "git@github.com:wearetechnative/terraform-aws-lambda.git"
    providers = {
      aws           = aws
      aws.us_east_1 = aws.us_east_1
    }
    bucket_name = "instancescheduler-bucket-example"
    route53_zone_name = "example.com"
    frontend_fqdn = "scheduler.example.com"
    dynamodb_table_name = "instance_scheduler"
    kms_key_arn = *******
    lambda_role_name = "scheduler_role"
    periods = [
      {
         "name": "7am-to-8pm",
         "days": ["mon", "tue", "wed", "thu", "fri"],
         "begintime": "7:00",
         "endtime": "20:00",
         "timezone": "Europe/Amsterdam"
      },
      {
         "name": "8am-to-7pm",
         "days": ["mon", "tue", "wed", "thu", "fri"],
         "begintime": "8:00",
         "endtime": "19:00",
         "timezone": "Europe/Amsterdam"
      }
    ]
    schedules = [
      {
         "name": "mon-fri-7am-to-8pm",
         "period": ["7am-to-8pm"]
      },
      {
         "name": "mon-fri-8am-to-7pm",
         "period": ["8am-to-7pm"]
      }
    ]
    sqs_arn = ********
}
```

The `periods` and `schedules` inputs are optional. When both are omitted,
deploy the module and create a period through the frontend first, followed by
a schedule that uses that period.

By default, the module creates the public hosted zone configured by
`route53_zone_name`. To use an existing public Route 53 hosted zone instead,
provide its ID and omit `route53_zone_name`:

```hcl
module "scheduler" {
  # ...
  route53_zone_id = "Z0123456789EXAMPLE"
  frontend_fqdn   = "scheduler.example.com"
}
```

<!-- BEGIN_TF_DOCS -->
## Ignore Scheduler functionality

You can use this feature to keep an instance running beyond its scheduled stop time. To enable it, simply add a tag to the instance called `Ignore_scheduler` with a value that indicates the time until which the instance should remain running, including the timezone `(for example: 22:00 Europe/Amsterdam)`. After that time, the tag will be automatically removed and the instance will resume its normal schedule.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dynamodb_instance_scheduler"></a> [dynamodb\_instance\_scheduler](#module\_dynamodb\_instance\_scheduler) | github.com/wearetechnative/terraform-aws-module-dynamodb.git | n/a |
| <a name="module_ec2_lambda"></a> [ec2\_lambda](#module\_ec2\_lambda) | github.com/wearetechnative/terraform-aws-lambda.git | n/a |
| <a name="module_iam_role_lambda_instance_scheduler"></a> [iam\_role\_lambda\_instance\_scheduler](#module\_iam\_role\_lambda\_instance\_scheduler) | github.com/wearetechnative/terraform-aws-iam-role.git | n/a |
| <a name="module_iam_role_webpage_scheduler"></a> [iam\_role\_webpage\_scheduler](#module\_iam\_role\_webpage\_scheduler) | github.com/wearetechnative/terraform-aws-iam-role.git | n/a |
| <a name="module_lambda_start_stop_instances"></a> [lambda\_start\_stop\_instances](#module\_lambda\_start\_stop\_instances) | github.com/wearetechnative/terraform-aws-lambda.git | n/a |
| <a name="module_sqs_dlq"></a> [sqs\_dlq](#module\_sqs\_dlq) | ../01_sqs_dlq | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.my_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_integration.int](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.my_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.my_api_stg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_event_rule.rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_dynamodb_table_item.period](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_dynamodb_table_item.schedules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_kms_grant.a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_grant) | resource |
| [aws_lambda_permission.allow_API](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_API_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_API_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_API_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.webpage_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.object2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.object3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_website_configuration.website_conf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_iam_policy_document.instance_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.launch_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | n/a | `string` | n/a | yes |
| <a name="input_lambda_role_name"></a> [lambda\_role\_name](#input\_lambda\_role\_name) | name for lambda role which will be created by this module | `string` | n/a | yes |
| <a name="input_periods"></a> [periods](#input\_periods) | n/a | <pre>list(object({<br/>    name = string,<br/>    days = list(string),<br/>    begintime = string,<br/>    endtime = string,<br/>    timezone = string<br/>  }))</pre> | n/a | yes |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | n/a | <pre>list(object({<br/>    name = string,<br/>    period = list(string)<br/>}))</pre> | n/a | yes |
| <a name="input_sqs_arn"></a> [sqs\_arn](#input\_sqs\_arn) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
