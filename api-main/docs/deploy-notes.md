# Deployment Notes: Dual APIs + Vue Frontend

## What was added
- `k8s/deployment-api2.yaml` / `k8s/service-api2.yaml` / `k8s/app-secrets-api2.yaml`: second API with its own image/secret and `PEER_API_URL` pointing to `myapi-service`.
- `k8s/ingress.yaml`: single ingress routing frontend (`/`), original API (`/api`), second API (`/api2`).
- `k8s/frontend.yaml`: placeholder Deployment+Service for the Vue SPA.

## How to deploy
1. Build & push images
   - Original API: `docker build -t <registry>/production/api:<tag> .` then push.
   - Second API: same Dockerfile; tag as `<registry>/production/api2:<tag>` and push.
   - Frontend: build Vue, containerize (e.g., nginx), tag `your-registry/frontend:<tag>`, push.
2. Apply secrets (replace placeholders with base64 values)
   - `kubectl apply -f k8s/app-secrets.yaml`
   - `kubectl apply -f k8s/app-secrets-api2.yaml`
3. Deploy workloads and services
   - `kubectl apply -f k8s/deployment.yaml`
   - `kubectl apply -f k8s/service.yaml`
   - `kubectl apply -f k8s/deployment-api2.yaml`
   - `kubectl apply -f k8s/service-api2.yaml`
   - `kubectl apply -f k8s/frontend.yaml`
4. Ingress
   - Edit `k8s/ingress.yaml` host to your domain and, if needed, remove or adjust the rewrite annotation to fit your ingress controller.
   - `kubectl apply -f k8s/ingress.yaml`
5. Verify
   - `kubectl get pods,svc,ingress`
   - Hit `/health/ready` on both APIs via in-cluster service names: `http://myapi-service/health/ready`, `http://myapi2-service/health/ready`.
   - From the browser, test `/api` and `/api2` routes through the ingress domain.

## Communication between services
- Inside the cluster, call services via DNS names: `http://myapi-service` and `http://myapi2-service` (port 80).
- `PEER_API_URL` in `deployment-api2.yaml` is set to `myapi-service`; add a symmetric env var in `deployment.yaml` if the first API needs to call the second.

## Scaling notes
- Both deployments start with `replicas: 2` and probes aligned with the original API.
- Add an HPA if desired (example):
  ```yaml
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: myapi-hpa
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: myapi-deployment
    minReplicas: 2
    maxReplicas: 5
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 70
  ```
  Duplicate for `myapi2-deployment` as needed.

## Frontend API calls
- In Vue, call relative paths `/api` and `/api2` so the ingress handles routing; no hardcoded host required.
- If you must use absolute URLs, inject them at build time via environment variables and align with ingress host.
