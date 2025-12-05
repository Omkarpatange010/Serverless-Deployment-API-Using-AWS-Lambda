variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "lambda_function_name" {
  type    = string
  default = "serverless-crud-lambda"
}

variable "s3_bucket_for_lambda" {
  type    = string
  default = "serverlessapi12" # CHANGE to globally unique name
}

variable "dynamodb_table_name" {
  type    = string
  default = "items-table"
}

variable "api_stage_name" {
  type    = string
  default = "dev"
}
