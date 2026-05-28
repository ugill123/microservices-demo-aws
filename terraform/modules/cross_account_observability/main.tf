# =============================================================================
# Observability-CloudWatch-Read role
# Created in env accounts (dev/prod) to be assumed by the observability
# EC2 instance in the shared account.
# =============================================================================
resource "aws_iam_role" "observability_read" {
  name = "Observability-CloudWatch-Read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.observability_server_role_arn
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "Observability-CloudWatch-Read"
  }
}

resource "aws_iam_role_policy" "observability_read" {
  name = "cloudwatch-read"
  role = aws_iam_role.observability_read.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}
