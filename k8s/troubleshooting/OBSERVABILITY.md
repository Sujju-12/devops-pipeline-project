# Failure, alert and recovery evidence

The repository's Prometheus rules already include `AppDown` and `PodCrashLooping`. The local Compose monitoring setup scrapes the employee API at `host.minikube.internal:8081`; make sure the matching port-forward is running before expecting app alerts:

```bash
kubectl port-forward -n devops svc/employee-api-service 8081:80
```

Start monitoring from the `monitoring` directory:

```bash
docker compose up -d
```

Open Prometheus at `http://localhost:9091/alerts` and Grafana at `http://localhost:3000`. Use the credentials configured in `monitoring/docker-compose.yml` only for this local lab; change them before exposing the services beyond localhost.

## Exercise: application unavailable

1. Confirm Prometheus shows the `employee-api` target as UP before the test.
2. Temporarily scale the Deployment to zero:

   ```bash
   kubectl scale deployment/employee-api --replicas=0 -n devops
   ```

3. Wait for the scrape target to become unavailable and for the `AppDown` alert's one-minute pending period to elapse.
4. Capture evidence: target state, alert state, command output, and timestamp.
5. Restore the Deployment:

   ```bash
   kubectl scale deployment/employee-api --replicas=2 -n devops
   kubectl rollout status deployment/employee-api -n devops --timeout=180s
   ```

6. Confirm the target returns to UP and the alert resolves.

This test temporarily causes downtime. Run it only in the local practice environment. The scrape target may need to be configured to reach the port-forward from the Docker Compose network on your OS; if Prometheus cannot reach it, fix connectivity first rather than interpreting a missing alert as a successful test.

## Exercise: pod crash

Apply one of the intentionally failing manifests from this folder and inspect the evidence:

```bash
kubectl apply -f k8s/troubleshooting/namespace.yaml
kubectl apply -f k8s/troubleshooting/crashloopbackoff.yaml
kubectl get pods -n ai-sre-lab -w
kubectl describe pod -n ai-sre-lab -l app=crashloop-demo
kubectl logs -n ai-sre-lab -l app=crashloop-demo --previous
kubectl delete -f k8s/troubleshooting/crashloopbackoff.yaml
```

The existing `PodCrashLooping` rule relies on Kubernetes pod/container metrics, which are not automatically available in the current standalone Prometheus Compose setup. Treat this rule as unverified until kube-state-metrics is configured and scraped. Do not claim the CrashLoop alert fired unless you observe it in Prometheus.

## Evidence checklist

- [ ] Prometheus target UP before the test
- [ ] Failure command and timestamp recorded
- [ ] Expected alert entered FIRING (or documented why the metric/target is unavailable)
- [ ] Recovery command completed
- [ ] Deployment/pods returned healthy
- [ ] Prometheus target UP and alert resolved
