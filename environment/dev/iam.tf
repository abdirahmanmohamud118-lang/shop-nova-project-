###########################################
# web server IAM
###########################################

resource "aws_iam_role" "web_server" {
  name = "${var.project_name}-web-server-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "web_server" {
  name = "${var.project_name}-web-server-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SecretsManagerAccess"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.rds_secret.arn
      },
      {
        Sid      = "SQSSendAccess"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = module.sqs.queue_arn
      },
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "web_server" {
  role       = aws_iam_role.web_server.name
  policy_arn = aws_iam_policy.web_server.arn
}

resource "aws_iam_instance_profile" "web_server" {
  name = "${var.project_name}-web-server-profile-${var.environment}"
  role = aws_iam_role.web_server.name
}

###########################################
# order processor IAM
###########################################

resource "aws_iam_role" "order_processor" {
  name = "${var.project_name}-order-processor-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "order_processor" {
  name = "${var.project_name}-order-processor-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SecretsManagerAccess"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.rds_secret.arn
      },
      {
        Sid    = "SQSConsumeAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = module.sqs.queue_arn
      },
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "order_processor" {
  role       = aws_iam_role.order_processor.name
  policy_arn = aws_iam_policy.order_processor.arn
}

resource "aws_iam_instance_profile" "order_processor" {
  name = "${var.project_name}-order-processor-profile-${var.environment}"
  role = aws_iam_role.order_processor.name
}