#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy.sh <environment> <action>
# Examples:
#   ./deploy.sh dev plan
#   ./deploy.sh dev apply
#   ./deploy.sh dev destroy

ENVIRONMENT=${1:-}
ACTION=${2:-plan}

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: ./deploy.sh <environment> <action>"
  echo "  environment: shared | dev | staging | prod"
  echo "  action:      plan | apply | destroy (default: plan)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"
SHARED_BACKEND="${SCRIPT_DIR}/../environments/shared/backend.hcl"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "Error: Environment directory not found: ${ENV_DIR}"
  exit 1
fi

echo "============================================"
echo " Environment: ${ENVIRONMENT}"
echo " Action:      ${ACTION}"
echo " Directory:   ${ENV_DIR}"
echo "============================================"

cd "$ENV_DIR"

# Initialize with backend config
if [[ "$ENVIRONMENT" == "shared" ]]; then
  echo "Initializing shared (local state)..."
  terraform init
else
  echo "Initializing with remote S3 backend..."
  terraform init -backend-config=backend.hcl
fi

# Execute the action
case "$ACTION" in
  plan)
    terraform plan -var-file=terraform.tfvars
    ;;
  apply)
    terraform apply -var-file=terraform.tfvars -auto-approve
    ;;
  destroy)
    terraform destroy -var-file=terraform.tfvars -auto-approve
    ;;
  *)
    echo "Error: Invalid action '${ACTION}'. Use: plan | apply | destroy"
    exit 1
    ;;
esac

echo "============================================"
echo " Done: ${ENVIRONMENT} ${ACTION}"
echo "============================================"
