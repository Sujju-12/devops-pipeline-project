# End-to-End DevOps CI/CD Pipeline

A hands-on DevOps project for learning how to build, containerize, deploy, and monitor an application using common DevOps tools. The primary workload is a Java 17 / Spring Boot employee API, with Kubernetes manifests, Terraform configuration, and Prometheus/Grafana monitoring files.

> **Project status:** This repository contains application code and infrastructure/monitoring configuration intended to support an end-to-end workflow. Treat the full automated CI/CD flow as work in progress until a Jenkins pipeline is configured and each stage is run and verified. This README distinguishes existing files from planned integrations.

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
| Planned CI/CD and quality integrations | Jenkins, SonarQube, Trivy |
| Configuration management and build-host setup | Ansible (playbook included) |

Ansible dependency-installation files and Kubernetes failure-lab manifests are included. Jenkins, SonarQube, and Trivy are part of the intended CI/CD toolset; their presence in this list does not imply that a complete, verified automated pipeline is already configured.

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

The diagram describes the intended design. Configure and test each integration before presenting the complete flow as automated.

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
    ├── ingress.yaml              # Ingress example; verify its backend Service name
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
- Horizontal Pod Autoscaler configuration targeting CPU and memory utilization.

The HPA requires a functioning metrics API (commonly provided by metrics-server) and valid resource requests. Confirm it with kubectl get hpa -n devops and kubectl top pods -n devops where metrics-server is available. The HPA may adjust the replica count after it becomes active.

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

## 8. CI/CD pipeline: intended stages

The goal is to trigger a pipeline when code is pushed to GitHub. A complete implementation should perform and validate stages similar to these:

1. Check out the selected commit from GitHub.
2. Run mvn clean verify and fail the pipeline if tests fail.
3. Run static analysis and enforce the SonarQube quality gate, if configured.
4. Build the Java Docker image.
5. Scan the image with Trivy, if configured, and apply a defined vulnerability policy.
6. Tag the image with an immutable version such as the Git commit SHA.
7. Authenticate securely and push the image to the chosen registry.
8. Update the Kubernetes Deployment to the new image.
9. Wait for kubectl rollout status and run a smoke test against the health endpoint.
10. Confirm Prometheus targets and application metrics after deployment.

Store registry credentials and other secrets in the CI system's credential store. Do not hardcode credentials in a Jenkinsfile, source code, Docker image, or README.

## Troubleshooting checklist

| Symptom | Checks |
| --- | --- |
| Pod is Pending | Run kubectl describe pod -n devops <pod-name>; inspect scheduling events, resource requests, and node capacity. |
| ImagePullBackOff | Check the image name/tag, registry access, image pull secrets, and whether the image was loaded into Minikube. |
| CrashLoopBackOff | Run kubectl logs -n devops <pod-name> --previous and inspect kubectl describe pod. |
| Readiness/liveness probe fails | Check application startup logs, port 8080, and /actuator/health; ensure probes allow enough startup time. |
| HPA shows unknown metrics | Verify metrics-server, resource requests, and kubectl top pods -n devops. |
| Prometheus target is down | Check target hostname/port from the Prometheus container, application endpoint accessibility, scrape path, and Prometheus logs. |
| Ingress returns an error | Check that an Ingress controller is installed and that the backend Service name and port match the actual Service. |
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

For the memory scenario, inspect the pod's last termination state and events to confirm whether it was OOMKilled; timing can vary by node and runtime. The complete walkthrough, diagnostic ideas, and cleanup commands are in [k8s/troubleshooting/README.md](k8s/troubleshooting/README.md).

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

This project is intended to provide practical experience with Ansible-based build-host preparation, Maven builds, Docker image creation, Kubernetes deployment and intentional failure troubleshooting, Terraform-managed Kubernetes resources, and Prometheus/Grafana observability. The next milestone is to implement and demonstrate the automated pipeline end to end, then document its actual results.

## License

No license is specified in this repository yet. Add a license file if you intend to define how others may use, modify, or distribute this project.
