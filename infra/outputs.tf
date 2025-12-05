output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}"
  description = "Base URL for API"
}
