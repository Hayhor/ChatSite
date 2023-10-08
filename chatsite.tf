provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

locals {
   lambda_zip_file = filebase64("C:/Users/Fawaz/Desktop/MyChatSite/MyChatSite-cbb9a24f-c259-44dd-94e7-135d31d90034.zip")
  source_code_hash = "ABC13B35EC5FE71C61293F7F7786C6A4060E5C96050148C9D140E3F0E8AF2BC1"
}

resource "aws_lambda_function" "MyChatSite" {
  function_name = "ChatWebsite"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_exec.arn
 filename = "C:/Users/Fawaz/Desktop/MyChatSite/MyChatSite-cbb9a24f-c259-44dd-94e7-135d31d90034.zip"
  source_code_hash = local.source_code_hash
  runtime = "nodejs18.x"
}

resource "aws_iam_role" "lambda_exec" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "chat_api" {
  name        = "ChatAPI"
  description = "API for the chat application"
}

resource "aws_api_gateway_resource" "message" {
  rest_api_id = aws_api_gateway_rest_api.chat_api.id
  parent_id   = aws_api_gateway_rest_api.chat_api.root_resource_id
  path_part   = "message"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.chat_api.id
  resource_id   = aws_api_gateway_resource.message.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.chat_api.id
  resource_id             = aws_api_gateway_resource.message.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.MyChatSite.invoke_arn
}

resource "aws_api_gateway_deployment" "chat_api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.chat_api.id
  stage_name = "prod"
}
