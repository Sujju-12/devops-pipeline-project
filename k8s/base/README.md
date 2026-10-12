# Employee API Kubernetes checks

These manifests use the existing `devops` namespace and `employee-api` labels. No Helm chart is used.

## Apply the project manifests

From the repository root:

```bash
kubectl apply -f k8s/base/namespace.yml
kubectl apply -f k8s/base/configmap.yml
kubectl apply -f k8s/base/deployment.yml
kubectl apply -f k8s/base/service.yml
kubectl apply -f k8s/base/hpa.yml
kubectl apply -f k8s/base/pdb.yml
kubectl apply -f k8s/base/serviceaccount.yml
kubectl apply -f k8s/base/rbac-readonly.yml
```

Apply the NetworkPolicy only after the ingress controller is installed and its namespace is confirmed. The example expects `ingress-nginx`; if your controller uses another namespace, update the selector first. The policy can block direct NodePort traffic from outside the allowed namespaces. NetworkPolicy enforcement depends on the cluster CNI.

## Ingress access

The root `ingress.yaml` routes `devops.local/` to the `employee-api-service` Service on port 80. Install an ingress controller first. For Minikube with the NGINX add-on:

```bash
minikube addons enable ingress
kubectl apply -f ingress.yaml
kubectl apply -f k8s/base/networkpolicy.yml
kubectl get ingress devops-ingress -n devops
```

If the Ingress manifest is applied to the `devops` namespace, add this host entry on the machine where the browser or curl command runs, using the IP reported by `minikube ip`:

```text
<minikube-ip> devops.local
```

Then test the API endpoint:

```bash
curl -i http://devops.local/api/employees
```

If host mapping is inconvenient, test with `curl -H 'Host: devops.local' http://$(minikube ip)/api/employees` where the Minikube IP is reachable from your host. Ingress behavior differs by Minikube driver and operating system.

## Prove HPA scaling

HPA requires the Kubernetes Metrics API. On Minikube, enable Metrics Server and wait for metrics:

```bash
minikube addons enable metrics-server
kubectl top pods -n devops
kubectl get hpa employee-api-hpa -n devops
```

Port-forward the existing Service in one terminal:

```bash
kubectl port-forward -n devops svc/employee-api-service 8081:80
```

In another terminal, run `bash scripts/load-test.sh` (requires `hey`). Watch the HPA and pods:

```bash
kubectl get hpa employee-api-hpa -n devops -w
kubectl get pods -n devops -l app=employee-api -w
```

Autoscaling is only demonstrated if the load drives CPU or memory utilization above the configured target long enough for the HPA to react. A short test may not scale this lightweight API; record the observed values rather than assuming replicas changed.

## PDB and node drain

The PDB keeps at least one employee API pod available during voluntary disruptions. Check it before trying a drain:

```bash
kubectl get pdb employee-api-pdb -n devops
kubectl get pods -n devops -l app=employee-api -o wide
```

On a multi-node test cluster, cordon and drain a node, then observe the PDB and replacement pod. Do not drain the only node in a single-node Minikube lab unless you are prepared for downtime or a blocked drain.

## RBAC checks

The `devops-observer` ServiceAccount has read-only access to selected namespaced resources:

```bash
kubectl auth can-i list pods -n devops --as=system:serviceaccount:devops:devops-observer
kubectl auth can-i delete pods -n devops --as=system:serviceaccount:devops:devops-observer
```

The first command should return `yes`; the second should return `no`. The application ServiceAccount does not mount an API token.

## NetworkPolicy checks

The policy allows traffic to employee API pods from the `devops` and `ingress-nginx` namespaces on port 8080. It is intentionally narrow and requires a CNI that enforces NetworkPolicy. Verify both the intended Ingress route and any monitoring path after applying it. If your ingress controller uses another namespace, change the selector before testing.
