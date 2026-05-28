#!/bin/bash
set -euxo pipefail

# =============================================================================
# Observability Server Bootstrap Script
# Runs on first boot — installs Docker, Docker Compose, and SSM agent
# =============================================================================

# --- Update system ---
dnf update -y

# --- Install Docker ---
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# --- Install Docker Compose v2 (as Docker plugin) ---
DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# --- Install useful tools ---
dnf install -y htop git jq

# --- SSM agent (already installed on AL2023, ensure it's running) ---
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# --- Format and mount EBS data volume ---
while [ ! -e /dev/nvme1n1 ] && [ ! -e /dev/sdf ]; do
  echo "Waiting for data volume to attach..."
  sleep 5
done

DEVICE=""
if [ -e /dev/nvme1n1 ]; then
  DEVICE="/dev/nvme1n1"
elif [ -e /dev/sdf ]; then
  DEVICE="/dev/sdf"
fi

if ! file -s $DEVICE | grep -q filesystem; then
  mkfs -t ext4 $DEVICE
fi

mkdir -p /data
mount $DEVICE /data
echo "$DEVICE /data ext4 defaults,nofail 0 2" >> /etc/fstab

# Create directories for Grafana + Prometheus persistence
mkdir -p /data/grafana /data/prometheus
chown -R 472:472 /data/grafana
chown -R 65534:65534 /data/prometheus

echo "Bootstrap complete. Docker, Compose, and SSM ready."
