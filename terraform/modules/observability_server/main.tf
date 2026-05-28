# =============================================================================
# Observability VPC (dedicated mini-VPC in shared account)
# =============================================================================
resource "aws_vpc" "obs" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-observability-vpc"
  }
}

resource "aws_internet_gateway" "obs" {
  vpc_id = aws_vpc.obs.id

  tags = {
    Name = "${var.project_name}-observability-igw"
  }
}

resource "aws_subnet" "obs_public" {
  vpc_id                  = aws_vpc.obs.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-observability-public"
    Tier = "public"
  }
}

resource "aws_route_table" "obs_public" {
  vpc_id = aws_vpc.obs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.obs.id
  }

  tags = {
    Name = "${var.project_name}-observability-public-rt"
  }
}

resource "aws_route_table_association" "obs_public" {
  subnet_id      = aws_subnet.obs_public.id
  route_table_id = aws_route_table.obs_public.id
}

# =============================================================================
# Security Group
# =============================================================================
resource "aws_security_group" "obs" {
  name_prefix = "${var.project_name}-observability-"
  description = "Security group for observability server (Prometheus + Grafana)"
  vpc_id      = aws_vpc.obs.id

  tags = {
    Name = "${var.project_name}-observability-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "obs_ingress_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ip_cidr]
  description       = "Grafana UI"
  security_group_id = aws_security_group.obs.id
}

resource "aws_security_group_rule" "obs_ingress_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ip_cidr]
  description       = "Prometheus UI"
  security_group_id = aws_security_group.obs.id
}

resource "aws_security_group_rule" "obs_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound (Docker Hub, AWS APIs, etc.)"
  security_group_id = aws_security_group.obs.id
}


# =============================================================================
# IAM Role for EC2 (SSM + CloudWatch read + cross-account assume)
# =============================================================================
resource "aws_iam_role" "obs" {
  name = "${var.project_name}-observability-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-observability-server-role"
  }
}

# Attach AWS-managed policy for SSM Session Manager access
resource "aws_iam_role_policy_attachment" "obs_ssm" {
  role       = aws_iam_role.obs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch read permissions (for cloudwatch_exporter scraping local account)
resource "aws_iam_role_policy" "obs_cloudwatch_read" {
  name = "cloudwatch-read"
  role = aws_iam_role.obs.id

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

# Cross-account assume role (so cloudwatch_exporter can scrape dev/prod metrics)
resource "aws_iam_role_policy" "obs_assume_cross_account" {
  count = length(var.monitored_account_ids) > 0 ? 1 : 0
  name  = "assume-cross-account-cloudwatch"
  role  = aws_iam_role.obs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Resource = [
        for acct in var.monitored_account_ids :
        "arn:aws:iam::${acct}:role/Observability-CloudWatch-Read"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "obs" {
  name = "${var.project_name}-observability-server"
  role = aws_iam_role.obs.name
}

# =============================================================================
# EC2 Instance
# =============================================================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "obs" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.obs_public.id
  vpc_security_group_ids = [aws_security_group.obs.id]
  iam_instance_profile = aws_iam_instance_profile.obs.name

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-observability-server"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# =============================================================================
# EBS Data Volume (for Grafana persistence)
# =============================================================================
resource "aws_ebs_volume" "obs_data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-observability-data"
  }
}

resource "aws_volume_attachment" "obs_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.obs_data.id
  instance_id = aws_instance.obs.id
}

# =============================================================================
# Elastic IP
# =============================================================================
resource "aws_eip" "obs" {
  instance = aws_instance.obs.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-observability-eip"
  }

  depends_on = [aws_internet_gateway.obs]
}
