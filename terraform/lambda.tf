resource "aws_lambda_function" "python_lambda" {
  function_name = "python-lambda"

  filename         = "../lambda/lambda.zip"
  source_code_hash = filebase64sha256("../lambda/lambda.zip")

  role    = aws_iam_role.lambda_role.arn
  handler = "lambdaCode.lambda_handler"
  runtime = "python3.12"
  architectures = [ "arm64" ]

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
        TABLE_NAME = aws_dynamodb_table.customer_orders_table.name
    }
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.customers_api.execution_arn}/*/*"
}