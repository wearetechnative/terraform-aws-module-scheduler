variable "schedules" {
    type = list(object({
    name = string,
    period = list(string)
}))
}

variable "periods"{
    type = list(object({
    name = string,
    days = list(string),
    begintime = string,
    endtime = string,
    timezone = string
  }))
}

variable "lambda_role_name"{
    type = string
}
variable "sqs_arn"{
    type = string
    
}
variable "kms_key_arn"{
    type = string
}
variable "aws_account_id" {
  description = "ID of the AWS account."
  type        = string  
}

variable "infra_environment" {
  description = "Name of the infrastructure environment."
  type        = string  
}

variable "project" {
  description = "Name of the project."
  type        = string
}

variable "git_url" {
  description = "Git repository ID or URL for tagging and tracking."
  type        = string
}  

variable "webpage_api_routes"{
    description = "routes of the Api_gateway"
    type = list
}

variable "lambda_scheduler_role_name"{
    type = string
}

variable "bucket_name"{
  type = string
}

variable "dynamodb_table_name"{
    type = string
}

variable "webpage_lambda_role_name"{
    type = string
}