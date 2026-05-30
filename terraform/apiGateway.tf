resource "aws_apigatewayv2_api" "customers_api" {
  name = "customers-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api_backend" {
  api_id = aws_apigatewayv2_api.customers_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.python_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id = aws_apigatewayv2_api.customers_api.id
  route_key = "GET /customers/{customerId}"
  target = "integrations/${aws_apigatewayv2_integration.api_backend.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.customers_api.id
  name   = "$default"
  auto_deploy = true
}