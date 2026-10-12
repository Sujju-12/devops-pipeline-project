# Kubernetes Pod Failure Troubleshooting Lab

These manifests intentionally create common pod failure states so you can practice diagnosis. They are **training examples, not production workloads**. All resources are isolated in the `ai-sre-lab` namespace; they do not target the application's `devops` namespace.

## Scenarios

| File | Expected symptom | What to investigate |
| --- | --- | --- |
| `crashloopbackoff.yaml` | `CrashLoopBackOff` | Exit code, current/previous logs, container command |
| `oomkilled.yaml` | Container termination with `OOMKilled` (may restart repeatedly) | Memory limit, resource usage, `lastState`, pod events |
| `imagepullbackoff.yaml` | `ErrImagePull` / `ImagePullBackOff` | Image name/tag, registry events, pull policy |
| `pending-unschedulable.yaml` | `Pending` | Node selector, scheduling events, available nodes |
| `missing-configmap.yaml` | `CreateContainerConfigError` | Referenced ConfigMap and pod events |

## Apply the lab

From the repository root:

```bash
kubectl apply -f k8s/troubleshooting/namespace.yaml
kubectl apply -f k8s/troubleshooting/crashloopbackoff.yaml
kubectl apply -f k8s/troubleshooting/oomkilled.yaml
kubectl apply -f k8s/troubleshooting/imagepullbackoff.yaml
kubectl apply -f k8s/troubleshooting/pending-unschedulable.yaml
kubectl apply -f k8s/troubleshooting/missing-configmap.yaml
```

Watch and inspect the pods:

```bash
kubectl get pods -n ai-sre-lab -w
kubectl get events -n ai-sre-lab --sort-by=.lastTimestamp
kubectl describe pods -n ai-sre-lab
kubectl logs -n ai-sre-lab deployment/lab-crashloop
kubectl logs -n ai-sre-lab deployment/lab-crashloop --previous
kubectl describe pod -n ai-sre-lab lab-oomkilled-<pod-suffix>
kubectl get pod -n ai-sre-lab lab-oomkilled-<pod-suffix> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

Replace `<pod-suffix>` with the actual pod name from `kubectl get pods`. For the memory case, the exact timing depends on the node and runtime; inspect `lastState.terminated.reason` and events to confirm whether it was OOMKilled.

## Suggested troubleshooting loop

1. Observe the symptom with `kubectl get pods -n ai-sre-lab -o wide`.
2. Gather events with `kubectl describe pod` and `kubectl get events`.
3. Inspect current and previous logs where applicable.
4. State the likely root cause and the evidence supporting it.
5. Make a minimal fix in a copy of the manifest.
6. Re-apply and verify pod status, readiness, logs, and events.

## Cleanup

Delete only the isolated lab resources:

```bash
kubectl delete -f k8s/troubleshooting/missing-configmap.yaml --ignore-not-found
kubectl delete -f k8s/troubleshooting/pending-unschedulable.yaml --ignore-not-found
kubectl delete -f k8s/troubleshooting/imagepullbackoff.yaml --ignore-not-found
kubectl delete -f k8s/troubleshooting/oomkilled.yaml --ignore-not-found
kubectl delete -f k8s/troubleshooting/crashloopbackoff.yaml --ignore-not-found
kubectl delete namespace ai-sre-lab --ignore-not-found
```

These deliberately broken resources can generate restart activity and events. Do not apply them to a production cluster.
