resource "aws_apigatewayv2_api" "my_api" {
  name          = "webpageapi"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = ["*"]
    max_age           = 3600
  }
}

resource "aws_apigatewayv2_integration" "int" {
  api_id                 = aws_apigatewayv2_api.my_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.webpage_lambda.lambda_function_arn
  integration_method     = "POST"
  payload_format_version = "2.0"

}

resource "aws_apigatewayv2_route" "my_route" {
  for_each  = toset(local.webpage_api_routes)
  api_id    = aws_apigatewayv2_api.my_api.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.int.id}"
}

moved {
  from = aws_apigatewayv2_route.my_route[0]
  to   = aws_apigatewayv2_route.my_route["ANY /db"]
}

moved {
  from = aws_apigatewayv2_route.my_route[1]
  to   = aws_apigatewayv2_route.my_route["ANY /db/list_periods"]
}

moved {
  from = aws_apigatewayv2_route.my_route[2]
  to   = aws_apigatewayv2_route.my_route["ANY /db/add_period"]
}

moved {
  from = aws_apigatewayv2_route.my_route[3]
  to   = aws_apigatewayv2_route.my_route["ANY /db/delete_period"]
}


resource "aws_apigatewayv2_stage" "my_api_stg" {
  api_id      = aws_apigatewayv2_api.my_api.id
  name        = "$default"
  auto_deploy = true
}


resource "aws_lambda_permission" "allow_API" {
  statement_id  = "AllowExecutionFromApigateway"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db"
}

resource "aws_lambda_permission" "allow_API_1" {
  statement_id  = "AllowExecutionFromApigateway_1"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/list_periods"
}

resource "aws_lambda_permission" "allow_API_2" {
  statement_id  = "AllowExecutionFromApigateway_2"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/add_period"
}

resource "aws_lambda_permission" "allow_API_3" {
  statement_id  = "AllowExecutionFromApigateway_3"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/delete_period"
}

resource "aws_lambda_permission" "allow_API_periods" {
  statement_id  = "AllowExecutionFromApigatewayPeriods"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/periods"
}

resource "aws_lambda_permission" "allow_API_create_period" {
  statement_id  = "AllowExecutionFromApigatewayCreatePeriod"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/create_period"
}

resource "aws_lambda_permission" "allow_API_update_period" {
  statement_id  = "AllowExecutionFromApigatewayUpdatePeriod"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/update_period"
}

resource "aws_lambda_permission" "allow_API_assign_period" {
  statement_id  = "AllowExecutionFromApigatewayAssignPeriod"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/assign_period"
}

resource "aws_lambda_permission" "allow_API_create_schedule" {
  statement_id  = "AllowExecutionFromApigatewayCreateSchedule"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/create_schedule"
}

resource "aws_lambda_permission" "allow_API_delete_period_definition" {
  statement_id  = "AllowExecutionFromApigatewayDeletePeriodDefinition"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/delete_period_definition"
}

resource "aws_lambda_permission" "allow_API_instances" {
  statement_id  = "AllowExecutionFromApigatewayInstances"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/instances"
}

resource "aws_lambda_permission" "allow_API_instance_schedule" {
  statement_id  = "AllowExecutionFromApigatewayInstanceSchedule"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/instances/schedule"
}

resource "aws_lambda_permission" "allow_API_instance_ignore" {
  statement_id  = "AllowExecutionFromApigatewayInstanceIgnore"
  action        = "lambda:InvokeFunction"
  function_name = module.webpage_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/instances/ignore"
}
