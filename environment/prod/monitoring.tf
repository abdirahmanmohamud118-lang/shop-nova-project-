resource "aws_cloudwatch_log_group" "web_server_logs" {
  name              = "/aws/ec2/${var.project_name}-user-data-${var.environment}"
  retention_in_days = 7 

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-application-${var.environment}"
  retention_in_days = 14 
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "order_processor_user_data_logs" {
  name              = "/aws/ec2/${var.project_name}-order-processor-user-data-${var.environment}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "order_processor_app_logs" {
  name              = "/aws/ec2/${var.project_name}-order-processor-app-${var.environment}"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}