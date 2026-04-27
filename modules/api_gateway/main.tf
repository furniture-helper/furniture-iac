variable "project" {
  description = "The name of the project for tagging resources"
  type        = string
}

variable "search_api_lambda_invoke_arn" {
  description = "The ARN of the Lambda function to invoke"
  type        = string
}

variable "search_api_lambda_function_name" {
  description = "The name of the Lambda function to invoke"
  type        = string
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "search-api-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.search_api_lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "search_products_route" {
  # checkov:skip=CKV_AWS_309: "No auth is required for this route"
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /products/search"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "get_products_route" {
  # checkov:skip=CKV_AWS_309: "No auth is required for this route"
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /products"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "NONE"
}
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true

    throttling_burst_limit = 10
    throttling_rate_limit  = 1
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.search_api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.search_api_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "search_api_endpoint" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}

output "search_api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "search_api_stage_name" {
  value = aws_apigatewayv2_stage.default_stage.name
}
