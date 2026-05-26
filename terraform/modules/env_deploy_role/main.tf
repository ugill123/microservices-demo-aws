# =============================================================================
# IAM Role assumed by GitHub Actions from the shared account
# =============================================================================
resource "aws_iam_role" "github_actions_deploy" {
  name = "GitHubActions-Deploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.shared_account_id}:role/${var.shared_role_name}"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "GitHubActions-Deploy-Role"
  }
}

# =============================================================================
# Policy: ECS deploy permissions in this environment account
# =============================================================================
resource "aws_iam_role_policy" "ecs_deploy" {
  name = "ecs-deploy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}
