# Kitchen Sink - Kubernetes Deployment Guide

## What You Have

- **3 DigitalOcean VPS servers** (Ubuntu 22.04 recommended)
- **1 domain**: `hamziss.com`
- **3 services to deploy**: `api-main`, `api-second`, `front`

## What You'll Set Up

| Component      | Purpose                                        | Where     |
| -------------- | ---------------------------------------------- | --------- |
| k3s            | Lightweight Kubernetes                         | All nodes |
| Harbor         | Container registry (stores your Docker images) | Node 1    |
| NGINX Ingress  | Routes traffic to services                     | Node 1    |
| cert-manager   | Auto-generates SSL certificates                | Node 1    |
| Sealed Secrets | Securely stores passwords/tokens               | Node 1    |
| Metrics Server | Enables auto-scaling (HPA)                     | Node 1    |

---

## Step-by-Step Instructions

### STEP 0: Prepare Your Servers

**On your local machine:**

1. Get the IP addresses of your 3 VPS servers from DigitalOcean
2. SSH into each server to make sure you can access them:
   ```bash
   ssh root@<NODE1_IP>
   ssh root@<NODE2_IP>
   ssh root@<NODE3_IP>
   ```

---

### STEP 1: Configure DNS (Do this first!)

Go to your domain registrar (where you bought `hamziss.com`) and add these **A records**:

| Name                   | Type | Value        |
| ---------------------- | ---- | ------------ |
| `@` (or `hamziss.com`) | A    | `<NODE1_IP>` |
| `api`                  | A    | `<NODE1_IP>` |
| `api2`                 | A    | `<NODE1_IP>` |
| `harbor`               | A    | `<NODE1_IP>` |

Wait 5-10 minutes for DNS to propagate.

---

### STEP 2: Setup Node 1 (Control Plane + Harbor)

**SSH into Node 1:**

```bash
ssh root@<NODE1_IP>
```

**Download and edit the setup script:**

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Hamziss/api-tmp/develop/scripts/setup-cluster.sh
chmod +x setup-cluster.sh

# Edit configuration - IMPORTANT!
nano setup-cluster.sh
```

**Change these lines at the top:**

```bash
NODE1_IP="YOUR_NODE1_IP"    # ← Put your actual Node 1 IP
NODE2_IP="YOUR_NODE2_IP"    # ← Put your actual Node 2 IP
NODE3_IP="YOUR_NODE3_IP"    # ← Put your actual Node 3 IP
```

Save and exit (`Ctrl+X`, then `Y`, then `Enter`)

**Run the installation:**

```bash
source setup-cluster.sh && install_all_node1
```

This takes about 5-10 minutes. It will:

1. Install k3s (Kubernetes)
2. Install Helm (package manager)
3. Install NGINX Ingress (traffic routing)
4. Install cert-manager (SSL certificates)
5. Install Harbor (Docker registry)
6. Install Metrics Server (for auto-scaling)
7. Install Sealed Secrets (secure secrets)

**⚠️ IMPORTANT: Save the K3S_TOKEN shown at the end! You need it for Node 2 & 3.**

---

### STEP 3: Join Node 2 to the Cluster

**SSH into Node 2:**

```bash
ssh root@<NODE2_IP>
```

**Join the cluster (replace <TOKEN> with the token from Step 2):**

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<NODE1_IP>:6443 K3S_TOKEN=<TOKEN> sh -
```

**Configure Harbor registry access:**

```bash
# Download script
curl -O https://raw.githubusercontent.com/Hamziss/api-tmp/develop/scripts/setup-cluster.sh
chmod +x setup-cluster.sh

# Edit IPs (same as Step 2)
nano setup-cluster.sh

# Configure registry
source setup-cluster.sh && configure_worker_registry
```

---

### STEP 4: Join Node 3 to the Cluster

**SSH into Node 3:**

```bash
ssh root@<NODE3_IP>
```

**Same steps as Node 2:**

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<NODE1_IP>:6443 K3S_TOKEN=<TOKEN> sh -

curl -O https://raw.githubusercontent.com/Hamziss/api-tmp/develop/scripts/setup-cluster.sh
chmod +x setup-cluster.sh
nano setup-cluster.sh  # Edit IPs
source setup-cluster.sh && configure_worker_registry
```

---

### STEP 5: Verify Cluster (on Node 1)

**SSH into Node 1:**

```bash
ssh root@<NODE1_IP>
```

**Check all nodes are ready:**

```bash
kubectl get nodes
```

You should see 3 nodes with `Ready` status:

```
NAME    STATUS   ROLES                  AGE   VERSION
node1   Ready    control-plane,master   10m   v1.29.x
node2   Ready    <none>                 5m    v1.29.x
node3   Ready    <none>                 2m    v1.29.x
```

---

### STEP 6: Setup Harbor Project

1. Open browser: `https://harbor.hamziss.com`
2. Login:
   - Username: `admin`
   - Password: `Harbor12345`
3. **CHANGE THE PASSWORD** (top right → Admin → Change Password)
4. Create a project:
   - Click "New Project"
   - Name: `production`
   - Access Level: `Public` ✓
   - Click "OK"

---

### STEP 7: Build and Push Docker Images (on your local machine)

**Login to Harbor:**

```bash
docker login harbor.hamziss.com
# Username: admin
# Password: <your new password>
```

**Build and push images:**

```bash
cd kitchen-sink

# Build and push all services
./scripts/build-and-push.sh all v1.0.0
```

---

### STEP 8: Create Sealed Secrets (on Node 1)

**SSH into Node 1:**

```bash
ssh root@<NODE1_IP>
```

**Create the secrets:**

```bash
# Clone your repo
git clone https://github.com/Hamziss/api-tmp.git
cd api-tmp

# Create raw secret file
cat > secret-raw.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: api-main-secrets
  namespace: kitchen-sink
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@your-db-host:5432/dbname"
  JWT_SECRET: "your-jwt-secret-at-least-32-characters-long"
  REFRESH_TOKEN_SECRET: "your-refresh-secret-at-least-32-chars"
  SESSION_SECRET: "your-session-secret-at-least-32-chars"
EOF

# Seal it
kubeseal --format yaml < secret-raw.yaml > k8s/sealed-secrets/api-main-sealed-secret.yaml

# Delete raw secret (IMPORTANT!)
rm secret-raw.yaml
```

---

### STEP 9: Deploy Application (on Node 1)

```bash
# Deploy everything
source scripts/setup-cluster.sh && deploy_app

# Watch pods starting
kubectl get pods -n kitchen-sink -w
```

Wait until all pods show `Running` and `1/1` or `2/2`.

---

### STEP 10: Verify Everything Works

**Check services:**

```bash
kubectl get pods -n kitchen-sink
kubectl get ingress -n kitchen-sink
kubectl get hpa -n kitchen-sink
```

**Test your URLs:**

- Frontend: https://hamziss.com
- API Main: https://api.hamziss.com/health
- API Second: https://api2.hamziss.com/health
- Harbor: https://harbor.hamziss.com

---

## Useful Commands

```bash
# View all pods
kubectl get pods -n kitchen-sink

# View pod logs
kubectl logs -f deployment/api-main -n kitchen-sink

# View HPA (auto-scaling) status
kubectl get hpa -n kitchen-sink

# Restart a deployment
kubectl rollout restart deployment/api-main -n kitchen-sink

# Update to new image version
kubectl set image deployment/api-main api-main=harbor.hamziss.com/production/api-main:v2.0.0 -n kitchen-sink
```

---

## Troubleshooting

### Pods stuck in "Pending"

```bash
kubectl describe pod <pod-name> -n kitchen-sink
```

Usually means not enough resources or image pull issues.

### Can't pull images from Harbor

```bash
# On each node, check registry config
cat /etc/rancher/k3s/registries.yaml
sudo systemctl restart k3s  # or k3s-agent on workers
```

### SSL certificate not working

```bash
kubectl describe certificate kitchen-sink-tls -n kitchen-sink
kubectl logs -n cert-manager deployment/cert-manager
```

Make sure DNS is correctly pointing to Node 1.

### HPA not scaling

```bash
kubectl top pods -n kitchen-sink
kubectl describe hpa api-main-hpa -n kitchen-sink
```

---

## File Structure

```
k8s/
├── namespace.yaml          # Creates "kitchen-sink" namespace
├── configmaps/            # Environment variables (non-secret)
├── sealed-secrets/        # Encrypted secrets (safe to commit)
├── deployments/           # Pod definitions
├── services/              # Internal networking
├── hpa/                   # Auto-scaling rules
└── ingress/               # External traffic routing
```
