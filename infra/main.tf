# S3 bucket to hold lambda zip
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.s3_bucket_for_lambda
  force_destroy = true
}

# DynamoDB table
resource "aws_dynamodb_table" "items" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Lambda function (code uploaded to S3 by Jenkins)
resource "aws_lambda_function" "app" {
  function_name = var.lambda_function_name
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = "lambda_package.zip"   # Jenkins will upload this key
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }
}

# create CloudWatch log group for the function
resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.app.function_name}"
  retention_in_days = 14
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name = "serverless-crud-api"
}

# Root resource id
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  path        = "/"
}

# Create /items resource
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# Create /items/{id} resource
resource "aws_api_gateway_resource" "item_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
}

# Methods and integrations for /items
resource "aws_api_gateway_method" "items_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "items_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "item_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "item_put" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "item_delete" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Integration (Lambda proxy)
locals {
  lambda_invoke_arn = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.app.arn}/invocations"
}

resource "aws_api_gateway_integration" "items_get_integ" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.items_get.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = local.lambda_invoke_arn
}

# reuse for other methods:
resource "aws_api_gateway_integration" "items_post_integ" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = aws_api_gateway_method.items_post.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = local.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "item_get_integ" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_id.id
  http_method = aws_api_gateway_method.item_get.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = local.lambda_invoke_arn
}
resource "aws_api_gateway_integration" "item_put_integ" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_id.id
  http_method = aws_api_gateway_method.item_put.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = local.lambda_invoke_arn
}
resource "aws_api_gateway_integration" "item_delete_integ" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.item_id.id
  http_method = aws_api_gateway_method.item_delete.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = local.lambda_invoke_arn
}

# permission allowing API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn could be tightened:
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deploy and stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.items_get_integ,
    aws_api_gateway_integration.items_post_integ,
    aws_api_gateway_integration.item_get_integ,
    aws_api_gateway_integration.item_put_integ,
    aws_api_gateway_integration.item_delete_integ
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeploy = timestamp()
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.api_stage_name
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}
