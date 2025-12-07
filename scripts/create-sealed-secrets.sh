#!/bin/bash

# =============================================================================
# CREATE SEALED SECRETS SCRIPT
# =============================================================================
# This script helps you create sealed secrets for the kitchen-sink deployment.
#
# Prerequisites:
# - kubeseal CLI installed locally
# - Access to the Kubernetes cluster (kubectl configured)
# - Sealed Secrets controller installed in the cluster
#
# Usage:
#   ./create-sealed-secrets.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=============================================="
echo "Sealed Secrets Generator for kitchen-sink"
echo -e "==============================================${NC}"

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
    echo -e "${RED}Error: kubeseal is not installed${NC}"
    echo "Install it with:"
    echo "  brew install kubeseal (macOS)"
    echo "  or download from: https://github.com/bitnami-labs/sealed-secrets/releases"
    exit 1
fi

# Resolve paths so the script can be run from any working directory
SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
OUTPUT_DIR="${PROJECT_ROOT}/k8s/sealed-secrets"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Create temp directory for raw secrets
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo ""
echo -e "${YELLOW}Enter the values for api-main secrets:${NC}"
echo ""

# Prompt for secret values
read -p "DATABASE_URL (PostgreSQL connection string): " DATABASE_URL
read -p "JWT_SECRET (min 32 chars): " JWT_SECRET
read -p "REFRESH_TOKEN_SECRET (min 32 chars): " REFRESH_TOKEN_SECRET
read -p "SESSION_SECRET (min 32 chars): " SESSION_SECRET

# Validate inputs
if [[ ${#JWT_SECRET} -lt 32 ]]; then
    echo -e "${RED}Error: JWT_SECRET must be at least 32 characters${NC}"
    exit 1
fi

if [[ ${#REFRESH_TOKEN_SECRET} -lt 32 ]]; then
    echo -e "${RED}Error: REFRESH_TOKEN_SECRET must be at least 32 characters${NC}"
    exit 1
fi

if [[ ${#SESSION_SECRET} -lt 32 ]]; then
    echo -e "${RED}Error: SESSION_SECRET must be at least 32 characters${NC}"
    exit 1
fi

# Create raw secret YAML
cat > "${TEMP_DIR}/secret-raw.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: api-main-secrets
  namespace: kitchen-sink
type: Opaque
stringData:
  DATABASE_URL: "${DATABASE_URL}"
  JWT_SECRET: "${JWT_SECRET}"
  REFRESH_TOKEN_SECRET: "${REFRESH_TOKEN_SECRET}"
  SESSION_SECRET: "${SESSION_SECRET}"
EOF

echo ""
echo -e "${GREEN}Creating sealed secret...${NC}"

# Seal the secret
kubeseal --format yaml < "${TEMP_DIR}/secret-raw.yaml" > "${OUTPUT_DIR}/api-main-sealed-secret.yaml"

echo ""
echo -e "${GREEN}✅ Sealed secret created successfully!${NC}"
echo ""
echo "File created: ${OUTPUT_DIR}/api-main-sealed-secret.yaml"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the sealed secret file"
echo "2. Commit it to Git"
echo "3. ArgoCD will automatically sync and deploy it"
echo ""
echo -e "${RED}⚠️  The raw secret has been securely deleted${NC}"
