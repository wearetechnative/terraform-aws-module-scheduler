resource "aws_apigatewayv2_api" "my_api" {
  name          = "webpageapi"
  protocol_type = "HTTP"
  cors_configuration {
        allow_credentials = false
        allow_headers = ["*",]
        allow_methods = ["*",]
        allow_origins = ["*",]
        expose_headers = ["*",]
        max_age = 0
        }
}

resource "aws_apigatewayv2_integration" "int" {
    api_id             = aws_apigatewayv2_api.my_api.id
    integration_type   = "AWS_PROXY"
    integration_uri    = module.ec2_lambda.lambda_function_arn
    integration_method = "POST"
    payload_format_version = "2.0"

}

resource "aws_apigatewayv2_route" "my_route" {
    count = length(var.webpage_api_routes)
    api_id    = aws_apigatewayv2_api.my_api.id
    route_key = var.webpage_api_routes[count.index]
    target    = "integrations/${aws_apigatewayv2_integration.int.id}"
}


resource "aws_apigatewayv2_stage" "my_api_stg" {
  api_id = aws_apigatewayv2_api.my_api.id
  name   = "$default"
  auto_deploy = true
}


resource "aws_lambda_permission" "allow_API" {
  statement_id  = "AllowExecutionFromApigateway"
  action        = "lambda:InvokeFunction"
  function_name = module.ec2_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db"
}

resource "aws_lambda_permission" "allow_API_1" {
  statement_id  = "AllowExecutionFromApigateway_1"
  action        = "lambda:InvokeFunction"
  function_name = module.ec2_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/list_periods"
}

resource "aws_lambda_permission" "allow_API_2" {
  statement_id  = "AllowExecutionFromApigateway_2"
  action        = "lambda:InvokeFunction"
  function_name = module.ec2_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/add_period"
}

resource "aws_lambda_permission" "allow_API_3" {
  statement_id  = "AllowExecutionFromApigateway_3"
  action        = "lambda:InvokeFunction"
  function_name = module.ec2_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*/db/delete_period"
}