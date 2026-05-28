output "role_arn" {
  description = "ARN of the cross-account observability read role"
  value       = aws_iam_role.observability_read.arn
}
