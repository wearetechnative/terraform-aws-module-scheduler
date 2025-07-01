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