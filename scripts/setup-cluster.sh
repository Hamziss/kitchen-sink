#!/bin/bash

# =============================================================================
# KUBERNETES CLUSTER SETUP SCRIPT (k3s + Harbor)
# =============================================================================
# Simplified setup for 3-node k3s cluster with self-hosted Harbor registry
#
# Node Layout:
# - Node 1: k3s server (control plane) + Harbor registry
# - Node 2: k3s agent (worker)
# - Node 3: k3s agent (worker)
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION - UPDATE THESE VALUES BEFORE RUNNING
# =============================================================================
NODE1_IP="167.71.56.194"              # Replace with Node 1 public IP
NODE2_IP="134.209.237.137"              # Replace with Node 2 public IP  
NODE3_IP="104.248.132.164"              # Replace with Node 3 public IP
DOMAIN="hamziss.com"                  # Your domain
HARBOR_DOMAIN="harbor.${DOMAIN}"      # Harbor subdomain
EMAIL="hamzachebbah9999@gmail.com"    # For Let's Encrypt

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# STEP 1: INSTALL K3S SERVER (Run on Node 1 only)
# =============================================================================
step1_install_k3s_server() {
    echo -e "${BLUE}[Step 1/7] Installing k3s server...${NC}"

    curl -sfL https://get.k3s.io | sh -s - server \
        --node-ip=${NODE1_IP} \
        --advertise-address=${NODE1_IP} \
        --tls-san=${NODE1_IP} \
        --tls-san=${DOMAIN} \
        --tls-san=${HARBOR_DOMAIN} \
        --disable=traefik \
        --write-kubeconfig-mode=644

    sleep 10

    # Setup kubectl
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    export KUBECONFIG=~/.kube/config

    # Get token for workers
    echo -e "${GREEN}[Step 1/7] k3s server installed!${NC}"
    echo ""
    echo -e "${YELLOW}=== SAVE THIS FOR WORKER NODES ===${NC}"
    echo "K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)"
    echo ""
    echo "Command for Node 2 & 3:"
    echo "curl -sfL https://get.k3s.io | K3S_URL=https://${NODE1_IP}:6443 K3S_TOKEN=<token> sh -"
}

# =============================================================================
# STEP 2: INSTALL HELM (Run on Node 1)
# =============================================================================
step2_install_helm() {
    echo -e "${BLUE}[Step 2/7] Installing Helm...${NC}"
    
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    echo -e "${GREEN}[Step 2/7] Helm installed!${NC}"
}

# =============================================================================
# STEP 3: INSTALL NGINX INGRESS (Run on Node 1)
# =============================================================================
step3_install_ingress() {
    echo -e "${BLUE}[Step 3/7] Installing NGINX Ingress...${NC}"
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.hostPort.enabled=true \
        --set controller.hostPort.ports.http=80 \
        --set controller.hostPort.ports.https=443 \
        --set controller.service.type=ClusterIP \
        --set controller.ingressClassResource.default=true

    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx

    echo -e "${GREEN}[Step 3/7] NGINX Ingress installed!${NC}"
}

# =============================================================================
# STEP 4: INSTALL CERT-MANAGER (Run on Node 1)
# =============================================================================
step4_install_cert_manager() {
    echo -e "${BLUE}[Step 4/7] Installing cert-manager...${NC}"
    
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set crds.enabled=true \
        --set prometheus.enabled=false

    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

    # Create Let's Encrypt ClusterIssuer
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

    echo -e "${GREEN}[Step 4/7] cert-manager installed!${NC}"
}

# =============================================================================
# STEP 5: INSTALL HARBOR (Run on Node 1)
# =============================================================================
step5_install_harbor() {
    echo -e "${BLUE}[Step 5/7] Installing Harbor registry...${NC}"

    helm repo add harbor https://helm.goharbor.io
    helm repo update

    kubectl create namespace harbor || true

    helm install harbor harbor/harbor \
        --namespace harbor \
        --set expose.type=ingress \
        --set expose.ingress.hosts.core=${HARBOR_DOMAIN} \
        --set expose.ingress.className=nginx \
        --set expose.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --set expose.tls.enabled=true \
        --set expose.tls.certSource=secret \
        --set expose.tls.secret.secretName=harbor-tls \
        --set externalURL=https://${HARBOR_DOMAIN} \
        --set harborAdminPassword=Harbor12345 \
        --set persistence.enabled=true \
        --set persistence.persistentVolumeClaim.registry.size=10Gi \
        --set persistence.persistentVolumeClaim.database.size=5Gi \
        --set persistence.persistentVolumeClaim.redis.size=1Gi \
        --set trivy.enabled=false \
        --set notary.enabled=false

    echo -e "${GREEN}[Step 5/7] Harbor installed!${NC}"
    echo ""
    echo -e "${YELLOW}Harbor Access:${NC}"
    echo "  URL: https://${HARBOR_DOMAIN}"
    echo "  User: admin"
    echo "  Pass: Harbor12345 (CHANGE THIS!)"
}

# =============================================================================
# STEP 6: INSTALL METRICS SERVER (Run on Node 1)
# =============================================================================
step6_install_metrics_server() {
    echo -e "${BLUE}[Step 6/7] Installing Metrics Server...${NC}"
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
      {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}
    ]' || true

    echo -e "${GREEN}[Step 6/7] Metrics Server installed!${NC}"
}

# =============================================================================
# STEP 7: INSTALL SEALED SECRETS (Run on Node 1)
# =============================================================================
step7_install_sealed_secrets() {
    echo -e "${BLUE}[Step 7/7] Installing Sealed Secrets...${NC}"
    
    helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
    helm repo update

    helm install sealed-secrets sealed-secrets/sealed-secrets \
        --namespace kube-system \
        --set fullnameOverride=sealed-secrets-controller

    echo -e "${GREEN}[Step 7/7] Sealed Secrets installed!${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT - Backup sealing key:${NC}"
    echo "kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ~/sealed-secrets-backup.yaml"
}

# =============================================================================
# CONFIGURE REGISTRY ON WORKERS (Run on Node 2 & 3)
# =============================================================================
configure_worker_registry() {
    echo -e "${BLUE}Configuring Harbor registry access...${NC}"

    sudo mkdir -p /etc/rancher/k3s/

    cat <<EOF | sudo tee /etc/rancher/k3s/registries.yaml
mirrors:
  "${HARBOR_DOMAIN}":
    endpoint:
      - "https://${HARBOR_DOMAIN}"
EOF

    if systemctl is-active --quiet k3s-agent; then
        sudo systemctl restart k3s-agent
    fi

    echo -e "${GREEN}Registry configured!${NC}"
}

# =============================================================================
# DEPLOY APPLICATION (Run on Node 1)
# =============================================================================
deploy_app() {
    echo -e "${BLUE}Deploying application...${NC}"

    # Apply all manifests
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmaps/
    kubectl apply -f k8s/sealed-secrets/ 2>/dev/null || echo "No sealed secrets yet"
    kubectl apply -f k8s/deployments/
    kubectl apply -f k8s/services/
    kubectl apply -f k8s/hpa/
    kubectl apply -f k8s/ingress/

    echo -e "${GREEN}Application deployed!${NC}"
    echo "Monitor: kubectl get pods -n kitchen-sink -w"
}

# =============================================================================
# INSTALL ALL ON NODE 1
# =============================================================================
install_all_node1() {
    step1_install_k3s_server
    step2_install_helm
    step3_install_ingress
    step4_install_cert_manager
    step5_install_harbor
    step6_install_metrics_server
    step7_install_sealed_secrets

    echo ""
    echo -e "${GREEN}=============================================="
    echo "All components installed on Node 1!"
    echo -e "==============================================${NC}"
}

# =============================================================================
# MENU
# =============================================================================
echo ""
echo -e "${YELLOW}Available commands:${NC}"
echo "  install_all_node1        - Install everything on Node 1"
echo "  step1_install_k3s_server - k3s server only"
echo "  step2_install_helm       - Helm only"
echo "  step3_install_ingress    - NGINX Ingress only"
echo "  step4_install_cert_manager - cert-manager only"
echo "  step5_install_harbor     - Harbor only"
echo "  step6_install_metrics_server - Metrics Server only"
echo "  step7_install_sealed_secrets - Sealed Secrets only"
echo "  configure_worker_registry - Run on Node 2 & 3"
echo "  deploy_app               - Deploy the application"
echo ""
echo "Usage: source setup-cluster.sh && <command>"
