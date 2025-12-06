#!/bin/bash

# =============================================================================
# BUILD AND PUSH IMAGES SCRIPT
# =============================================================================
# This script builds Docker images for all services and pushes them to Harbor.
#
# Prerequisites:
# - Docker installed and running
# - Access to Harbor registry
#
# Usage:
#   ./build-and-push.sh [service] [tag]
#   ./build-and-push.sh              # Build all services with 'latest' tag
#   ./build-and-push.sh api-main v1  # Build specific service with specific tag
# =============================================================================

set -e

# Configuration
HARBOR_REGISTRY="harbor.hamziss.com"
HARBOR_PROJECT="production"
TAG="${2:-latest}"
DOMAIN="hamziss.com"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}=============================================="
echo "Build and Push Docker Images to Harbor"
echo -e "==============================================${NC}"
echo ""
echo "Registry: ${HARBOR_REGISTRY}"
echo "Project: ${HARBOR_PROJECT}"
echo "Tag: ${TAG}"
echo ""

# Function to build and push a service
build_and_push() {
    local service=$1
    local context=$2
    local build_args=$3

    echo -e "${YELLOW}Building ${service}...${NC}"
    
    local image="${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${service}:${TAG}"
    
    docker build ${build_args} -t "${image}" "${PROJECT_ROOT}/${context}"
    
    echo -e "${YELLOW}Pushing ${service}...${NC}"
    docker push "${image}"
    
    echo -e "${GREEN}✅ ${service} pushed successfully!${NC}"
    echo ""
}

# Build and push based on argument
case "${1:-all}" in
    api-main)
        build_and_push "api-main" "api-main" ""
        ;;
    api-second)
        build_and_push "api-second" "api-second" ""
        ;;
    front)
        # Build with API URLs as build arguments
        build_and_push "front" "front" \
            "--build-arg VITE_API_MAIN_URL=https://api.${DOMAIN} --build-arg VITE_API_SECOND_URL=https://api2.${DOMAIN}"
        ;;
    all)
        build_and_push "api-main" "api-main" ""
        build_and_push "api-second" "api-second" ""
        build_and_push "front" "front" \
            "--build-arg VITE_API_MAIN_URL=https://api.${DOMAIN} --build-arg VITE_API_SECOND_URL=https://api2.${DOMAIN}"
        ;;
    *)
        echo "Usage: $0 [api-main|api-second|front|all] [tag]"
        exit 1
        ;;
esac

echo -e "${GREEN}=============================================="
echo "All builds complete!"
echo -e "==============================================${NC}"
