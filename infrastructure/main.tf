terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "char-counter-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda function
resource "aws_lambda_function" "char_counter" {
  filename         = "../lambda-deployment-package.zip"
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "bootstrap"
  runtime         = "provided.al2"
  timeout         = 30
  memory_size     = 128

  source_code_hash = filebase64sha256("../lambda-deployment-package.zip")
}

# API Gateway
resource "aws_api_gateway_rest_api" "char_counter_api" {
  name = "char-counter-api"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "char_counter_resource" {
  rest_api_id = aws_api_gateway_rest_api.char_counter_api.id
  parent_id   = aws_api_gateway_rest_api.char_counter_api.root_resource_id
  path_part   = "count"
}

resource "aws_api_gateway_method" "char_counter_method" {
  rest_api_id   = aws_api_gateway_rest_api.char_counter_api.id
  resource_id   = aws_api_gateway_resource.char_counter_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "char_counter_integration" {
  rest_api_id = aws_api_gateway_rest_api.char_counter_api.id
  resource_id = aws_api_gateway_resource.char_counter_resource.id
  http_method = aws_api_gateway_method.char_counter_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.char_counter.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.char_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.char_counter_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "char_counter_deployment" {
  depends_on = [
    aws_api_gateway_integration.char_counter_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.char_counter_api.id
  stage_name  = "prod"
}

# Variables
variable "aws_region" {
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "function_name" {
  description = "Lambda function name"
  default     = "char-counter-lambda"
}

# Outputs
output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.char_counter_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.char_counter_deployment.stage_name}/count"
}

output "lambda_function_name" {
  value = aws_lambda_function.char_counter.function_name
}