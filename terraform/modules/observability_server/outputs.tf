output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.obs.id
}

output "public_ip" {
  description = "Elastic IP attached to the instance"
  value       = aws_eip.obs.public_ip
}

output "grafana_url" {
  description = "Grafana UI URL"
  value       = "http://${aws_eip.obs.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${aws_eip.obs.public_ip}:9090"
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the instance"
  value       = aws_iam_role.obs.arn
}

output "vpc_id" {
  description = "Observability VPC ID"
  value       = aws_vpc.obs.id
}

output "ssm_session_command" {
  description = "Command to connect via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.obs.id} --region us-east-1"
}
