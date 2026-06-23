variable "schedules" {
  description = "Schedules to create during deployment. Omit to manage schedules entirely through the frontend."
  type = list(object({
    name   = string,
    period = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for schedule in var.schedules : length(schedule.period) > 0])
    error_message = "Every predefined schedule must contain at least one period."
  }
}

variable "periods" {
  description = "Periods to create during deployment. Omit to manage periods entirely through the frontend."
  type = list(object({
    name      = string,
    days      = list(string),
    begintime = string,
    endtime   = string,
    timezone  = string
  }))
  default = []
}

variable "sqs_arn" {
  type = string

}
variable "kms_key_arn" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "lambda_role_name" {
  type        = string
  description = "name for lambda role which will be created by this module"

}

variable "route53_zone_name" {
  description = "Public Route 53 hosted zone to create when route53_zone_id is not provided, for example example.com"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.route53_zone_name == null ? true : length(trimspace(var.route53_zone_name)) > 0
    error_message = "route53_zone_name must be null or a non-empty domain name."
  }
}

variable "route53_zone_id" {
  description = "ID of an existing public Route 53 hosted zone to reuse. When set, the module does not create a hosted zone."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.route53_zone_id == null ? true : length(trimspace(var.route53_zone_id)) > 0
    error_message = "route53_zone_id must be null or a non-empty hosted zone ID."
  }
}

variable "frontend_fqdn" {
  description = "Fully qualified domain name for the scheduler frontend, for example scheduler.example.com"
  type        = string

  validation {
    condition     = length(trimspace(var.frontend_fqdn)) > 0 && !startswith(var.frontend_fqdn, "http")
    error_message = "frontend_fqdn must be a hostname without http:// or https://."
  }
}
