module "dynamodb_instance_scheduler" {
  source = "github.com/wearetechnative/terraform-aws-module-dynamodb.git"
  name = var.dynamodb_table_name
  partition_key = "type"
  partition_key_type = "S"
  range_key = "name"
  range_key_type = "S"
  kms_key_arn = var.kms_key_arn
 
  
}
resource "aws_dynamodb_table_item" "schedules" {
  for_each = {for schedule in var.schedules:
              schedule.name=>schedule}
  table_name = module.dynamodb_instance_scheduler.table_name
  hash_key = "type"
  range_key = "name"
  item = jsonencode({
    "type": {
    "S": "schedule"
  },
    "name":{
      "S": each.value.name
    },
   "periods": {
    "SS": [for p in each.value.period: p]
    
  } 
  }) 
}
resource "aws_dynamodb_table_item" "period" {
  for_each = {for period in var.periods:
                  period.name=>period     
              }
  table_name = module.dynamodb_instance_scheduler.table_name
  hash_key = "type"
  range_key = "name"
  item = jsonencode({
    "type": {
    "S": "period"
  },
    "name":{
      "S": each.value.name
    },
  "days": {
     "SS": [for d in each.value.days: d]
   },
  "begintime": {
     "S": each.value.begintime
    },
  "endtime": {
     "S": each.value.endtime
  }  
  "timezone":{
     "S": each.value.timezone
  }

  }) 
}