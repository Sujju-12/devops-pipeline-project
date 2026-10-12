# End-to-End DevOps CI/CD Pipeline

A hands-on DevOps project for learning how to build, containerize, deploy, and monitor an application using common DevOps tools. The primary workload is a Java 17 / Spring Boot employee API, with Kubernetes manifests, Terraform configuration, and Prometheus/Grafana monitoring files.

> **Project status:** A focused Jenkins pipeline and Kubernetes routing, autoscaling, disruption, RBAC, NetworkPolicy, load-test, and observability exercises are now included. These are configuration and practice assets; the pipeline, HPA behavior, Ingress access, policies, and alerts still need to be executed in the user's cluster and Jenkins environment before claiming runtime verification.

## Goals

- Build and package a Spring Boot application with Maven.
- Package the application as a Docker image.
- Deploy the container to Kubernetes locally with Minikube.
- Practice Kubernetes health probes, resource requests and limits, rolling updates, and autoscaling.
- Explore infrastructure configuration with Terraform.
- Use Ansible to install Java/Maven build dependencies on Debian/Ubuntu hosts.
- Practice diagnosing intentionally created Kubernetes pod failures in an isolated lab namespace.
- Explore metrics collection and dashboards with Prometheus and Grafana.
- Extend the workflow with automated quality and security checks.

## Technology stack

| Area | Tools |
| --- | --- |
| Application | Java 17, Spring Boot |
| Build and test | Maven |
| Version control | Git, GitHub |
| Containerization | Docker |
| Orchestration | Kubernetes, Minikube, kubectl |
| Infrastructure as Code | Terraform, Kubernetes provider |
| Monitoring and dashboards | Prometheus, Grafana |
| CI/CD and image security | Jenkinsfile, Maven, Trivy |
| Configuration management and build-host setup | Ansible (playbook included) |

Ansible dependency-installation files, a Jenkins pipeline, Trivy scans, Kubernetes security manifests, and failure-lab scenarios are included. Jenkins requires the documented credentials and tools; no SonarQube stage or Helm chart is included.

## Architecture and intended workflow

    Developer
       |
       | Git commit / push
       v
    GitHub repository
       |
       | Webhook or SCM polling (to be configured)
       v
    Jenkins pipeline (to be implemented and validated)
       |
       +--> Maven build and tests
       +--> SonarQube quality gate (optional integration)
       +--> Docker image build
       +--> Trivy image scan (optional integration)
       +--> Publish a versioned image to a registry (if configured)
       |
       v
    Kubernetes / Minikube
       |
       +--> Deployment and rolling updates
       +--> Service
       +--> Readiness and liveness probes
       +--> Horizontal Pod Autoscaler (requires metrics-server)
       |
       v
    Prometheus --> Grafana dashboards and alerts

The diagram describes the configured pipeline stages. Registry credentials, cluster access, Jenkins tools, and runtime behavior must be configured and verified locally.

## Repository structure

    .
    ├── app/
    │   └── employee-api/       # Spring Boot application, pom.xml and Dockerfile
    ├── k8s/
    │   ├── base/               # Namespace, ConfigMap, Deployment, Service and HPA
    │   └── troubleshooting/    # Intentional pod-failure manifests and lab guide
    ├── ansible/
    │   ├── install-build-dependencies.yml  # Install Java 17, Maven, Git and curl
    │   ├── inventory.ini                  # Example localhost inventory
    │   └── README.md                      # Ansible usage instructions
    ├── terraform/              # Terraform configuration for local Kubernetes resources
    ├── monitoring/
    │   ├── docker-compose.yml  # Prometheus and Grafana services
    │   ├── prometheus/          # Prometheus configuration and alert rules
    │   └── grafana/             # Grafana datasource configuration
    ├── Dockerfile               # Root-level Flask example, separate from the Java API
    ├── app.py                   # Root-level Flask example
    ├── requirements.txt         # Python dependencies for the Flask example
    ├── ingress.yaml              # devops.local -> employee-api-service
    └── README.md

**Important:** The root-level app.py and Dockerfile are a separate Flask example. The Java API's Dockerfile is under app/employee-api/. Use the Java API Dockerfile and build context for the Spring Boot Kubernetes deployment.

## Prerequisites

Install and configure the following for the local Kubernetes path:

- Git
- Docker Engine / Docker Desktop
- Java 17 and Maven (for building and testing outside Docker)
- Minikube
- kubectl
- Ansible (only if using the dependency-installation playbook)
- Terraform (only if using the Terraform path)
- Docker Compose (for the monitoring stack)

Check the tools are available:

    git --version
    docker --version
    java -version
    mvn -version
    minikube version
    kubectl version --client
    terraform version
    docker compose version

You do not need Terraform to deploy with Kubernetes YAML manifests. Choose **one resource-management path** for a given set of Kubernetes objects: manifests with kubectl, or Terraform. Applying both to the same resources can create configuration drift.

## 1. Clone the repository

    git clone https://github.com/Sujju-12/devops-pipeline-project.git
    cd devops-pipeline-project

## 2. Build and test the Java application

From the repository root:

    cd app/employee-api
    mvn clean verify
    cd ../..

This runs the Maven verification lifecycle, including tests configured by the project. Review the command output and test reports before proceeding.

## 3. Install build dependencies with Ansible (optional)

The `ansible/` directory contains a playbook for installing Java 17, Maven, Git, and curl on Debian/Ubuntu build hosts. It prepares the host for the Maven build; it does not install or configure Jenkins or Docker.

With Ansible installed, run from the repository root:

    ansible --version
    ansible-playbook -i ansible/inventory.ini ansible/install-build-dependencies.yml --ask-become-pass

The sample inventory targets localhost. The playbook uses privilege escalation, so provide the sudo password if your local configuration requires it. To use a remote build host, configure SSH access and update the inventory. Do not commit passwords, private keys, or other secrets. See [ansible/README.md](ansible/README.md) for details.

## 4. Build the Java Docker image

From the repository root:

    docker build -t employee-api:latest -f app/employee-api/Dockerfile app/employee-api

For local Minikube deployments, make the image available to the Minikube node:

    minikube start
    minikube image load employee-api:latest

The Kubernetes Deployment currently refers to employee-api:latest and uses imagePullPolicy IfNotPresent. For a shared or production-like environment, prefer immutable version tags (for example, a Git commit SHA) and a configured image registry.

## 5. Deploy to Minikube with Kubernetes manifests

Start Minikube if it is not already running:

    minikube start
    kubectl get nodes

Apply the namespace and configuration, then the base manifests:

    kubectl apply -f k8s/base/namespace.yml
    kubectl apply -f k8s/base/configmap.yml
    kubectl apply -f k8s/base/

Inspect the deployment:

    kubectl get all -n devops
    kubectl get hpa -n devops
    kubectl describe deployment employee-api -n devops
    kubectl rollout status deployment/employee-api -n devops
    kubectl get pods -n devops -o wide

To inspect logs:

    kubectl logs -n devops deployment/employee-api

To inspect the NodePort Service:

    kubectl get service employee-api-service -n devops
    minikube ip

The Service manifest maps port 80 to container port 8080 and declares NodePort 30080. Depending on your operating system and Minikube driver, you may need to run:

    minikube service employee-api-service -n devops --url

The Deployment defines readiness/liveness checks against /actuator/health. Confirm the application starts and these endpoints respond successfully before considering the rollout healthy.

### Kubernetes features represented in the manifests

- Namespace isolation for the workload.
- Deployment with two desired replicas and rolling-update settings.
- ConfigMap-based application configuration.
- CPU and memory requests/limits.
- Readiness and liveness HTTP probes.
- NodePort Service.
- Horizontal Pod Autoscaler configuration targeting CPU and memory utilization.\n- PodDisruptionBudget to preserve one available pod during voluntary disruptions.\n- Application ServiceAccount without an automatically mounted API token.\n- Namespace-scoped read-only observer Role/RoleBinding.\n- Ingress NetworkPolicy for the devops and ingress-nginx namespaces (requires a policy-enforcing CNI).\n- Ingress routing for devops.local to employee-api-service.

The HPA requires a functioning metrics API (commonly provided by metrics-server) and valid resource requests. Follow [k8s/base/README.md](k8s/base/README.md) to enable metrics-server, run the load test, and watch replica changes. A load test is evidence only if the observed metrics actually trigger a scale event.

## 6. Optional: use Terraform

The terraform/ directory contains Terraform configuration using the Kubernetes provider and a local kubeconfig context for Minikube. This is a local learning setup, not an AWS/EKS deployment configuration.

Ensure Minikube is running and your kubeconfig context is set correctly. Then:

    cd terraform
    terraform init
    terraform validate
    terraform plan

Review the plan carefully before applying it:

    terraform apply

Use terraform destroy only after reviewing the planned changes and confirming you want the resources removed.

**Do not use Terraform and kubectl apply as competing owners of the same resources.** Choose one method and keep its configuration as the source of truth. Never commit Terraform state or state backup files to a public repository; state can contain sensitive infrastructure details.

## 7. Monitoring with Prometheus and Grafana

The monitoring/ directory contains a Docker Compose configuration, Prometheus scrape configuration and alert rules, and a Grafana Prometheus datasource configuration.

Start the monitoring containers from the repository root:

    docker compose -f monitoring/docker-compose.yml config
    docker compose -f monitoring/docker-compose.yml up -d
    docker compose -f monitoring/docker-compose.yml ps

Open the local endpoints:

- Prometheus: http://localhost:9091
- Grafana: http://localhost:3000

The Compose configuration currently defines a default Grafana login. Before using this setup beyond a disposable local lab, change the default credentials and manage secrets outside version control.

Prometheus must be able to reach each configured scrape target from inside its container. Check http://localhost:9091/targets and verify targets show as UP. The employee API scrape configuration uses a host/port target that may need to be adjusted to match how the API is exposed or port-forwarded in your environment. Kubernetes pod discovery and some alert expressions also depend on the required Kubernetes metrics and API access being available.

Useful checks:

    docker compose -f monitoring/docker-compose.yml logs prometheus
    docker compose -f monitoring/docker-compose.yml logs grafana
    kubectl get pods -n devops
    kubectl get service -n devops

A configured scrape target or alert rule is not proof that metrics are currently being collected. Verify targets, query the expected metrics, and test alert conditions in your environment.

## 8. Jenkins CI/CD pipeline

The root `Jenkinsfile` targets the Java application under `app/employee-api` and defines these stages:

1. Check out the commit and derive a short Git-SHA image tag.
2. Run `mvn clean verify` and publish JUnit test reports.
3. Scan application files with Trivy.
4. Build the Docker image from the Java application's Dockerfile and context.
5. Scan the built image with Trivy.
6. On the `main` branch, push the image to Docker Hub and update the Kubernetes Deployment.
7. Wait for `kubectl rollout status` and list the resulting pods.

### Jenkins setup required

- Create a **Multibranch Pipeline** job for this GitHub repository so the `main` branch condition works.
- Use an agent with Git, Java 17/Maven, Docker, Trivy, and kubectl installed and configured.
- Add a Jenkins username/password credential with ID `dockerhub-credentials`.
- Add a Jenkins **Secret file** credential with ID `minikube-kubeconfig`; the kubeconfig must work from the Jenkins agent and reach the target cluster.
- Set the build parameter `DOCKERHUB_REPOSITORY` to your Docker Hub repository, such as `yourusername/employee-api`. For this simple setup, make the repository public so Kubernetes can pull the image, or create and reference an imagePullSecret.
- Configure the Jenkins SCM trigger/webhook separately if you want pushes to start builds automatically.

The Trivy stages fail the build for unfixed HIGH or CRITICAL findings. Review findings and update vulnerable dependencies/base images rather than silently disabling the scan. The pipeline is a starter implementation and has not been proven against your Jenkins instance or cluster until a real run succeeds. It does not include SonarQube or Helm.

## Troubleshooting checklist

| Symptom | Checks |
| --- | --- |
| Pod is Pending | Run kubectl describe pod -n devops <pod-name>; inspect scheduling events, resource requests, and node capacity. |
| ImagePullBackOff | Check the image name/tag, registry access, image pull secrets, and whether the image was loaded into Minikube. |
| CrashLoopBackOff | Run kubectl logs -n devops <pod-name> --previous and inspect kubectl describe pod. |
| Readiness/liveness probe fails | Check application startup logs, port 8080, and /actuator/health; ensure probes allow enough startup time. |
| HPA shows unknown metrics | Verify metrics-server, resource requests, and kubectl top pods -n devops. |
| Prometheus target is down | Check target hostname/port from the Prometheus container, application endpoint accessibility, scrape path, and Prometheus logs. |
| Ingress returns an error | Check that the Ingress controller is installed, the Ingress is in namespace devops, and its backend is employee-api-service:80. |\n| Jenkins cannot push an image | Check DOCKERHUB_REPOSITORY and the dockerhub-credentials Jenkins credential. |\n| Jenkins cannot deploy | Check that minikube-kubeconfig is valid from the Jenkins agent and the agent can reach the cluster. |\n| NetworkPolicy blocks traffic | Check the ingress controller namespace and whether the cluster CNI enforces NetworkPolicy. |
| Terraform plan differs from manifests | Ensure only one tool owns each resource and compare replica counts, images, ports, and configuration. |

## Intentional Kubernetes pod-failure lab

The `k8s/troubleshooting/` directory contains deliberately misconfigured workloads for practicing diagnosis. They are isolated in the `ai-sre-lab` namespace and are separate from the application's `devops` namespace.

Scenarios included:

- `crashloopbackoff.yaml`: exits repeatedly to trigger `CrashLoopBackOff`.
- `oomkilled.yaml`: attempts to allocate more memory than its container limit, to practice investigating `OOMKilled`.
- `imagepullbackoff.yaml`: uses a deliberately nonexistent image tag.
- `pending-unschedulable.yaml`: selects a node label that should not exist, leaving the pod unscheduled.
- `missing-configmap.yaml`: references a deliberately missing ConfigMap, causing a container configuration error.

Create the isolated namespace and apply the lab scenarios:

    kubectl apply -f k8s/troubleshooting/namespace.yaml
    kubectl apply -f k8s/troubleshooting/crashloopbackoff.yaml
    kubectl apply -f k8s/troubleshooting/oomkilled.yaml
    kubectl apply -f k8s/troubleshooting/imagepullbackoff.yaml
    kubectl apply -f k8s/troubleshooting/pending-unschedulable.yaml
    kubectl apply -f k8s/troubleshooting/missing-configmap.yaml

Observe and diagnose:

    kubectl get pods -n ai-sre-lab -w
    kubectl get events -n ai-sre-lab --sort-by=.lastTimestamp
    kubectl describe pods -n ai-sre-lab
    kubectl logs -n ai-sre-lab deployment/lab-crashloop --previous

For the memory scenario, inspect the pod's last termination state and events to confirm whether it was OOMKilled; timing can vary by node and runtime. The complete walkthrough, diagnostic ideas, and cleanup commands are in [k8s/troubleshooting/README.md](k8s/troubleshooting/README.md). See [k8s/troubleshooting/OBSERVABILITY.md](k8s/troubleshooting/OBSERVABILITY.md) for the failure-to-alert-to-recovery exercise. The HPA, Ingress, PDB, RBAC, NetworkPolicy, and load-test steps are documented in [k8s/base/README.md](k8s/base/README.md).

**Safety:** These workloads are intentionally broken and can create restart activity and events. Use them only in a disposable training cluster, never in production. Delete the individual lab resources or the `ai-sre-lab` namespace when finished.

## Security and good practices

- Never commit credentials, .env files, Terraform state, or state backups.
- Replace default Grafana credentials before exposing the service beyond a local lab.
- Use least-privilege permissions for Kubernetes and registry access.
- Prefer immutable image tags instead of relying on latest for releases.
- Run tests and security scans before deployment.
- Verify rollout health and perform smoke tests rather than assuming a successful command means the application works.
- Keep project claims aligned with what has actually been executed and verified.

## Learning outcomes

This project provides practice with Ansible-based build-host preparation, Maven builds, Docker image creation, Jenkins CI/CD, Kubernetes deployment and intentional failure troubleshooting, HPA/load testing, Ingress routing, PDB/RBAC/NetworkPolicy controls, Terraform-managed Kubernetes resources, and Prometheus/Grafana observability. The remaining work is runtime verification: execute the pipeline, observe HPA scale changes, test Ingress and policies, and capture alert/recovery evidence.

## License

No license is specified in this repository yet. Add a license file if you intend to define how others may use, modify, or distribute this project.
