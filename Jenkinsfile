pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(
            name: 'DOCKERHUB_REPOSITORY',
            defaultValue: '',
            description: 'Docker Hub repository, e.g. yourusername/employee-api. Keep it public for this simple Minikube setup, or configure imagePullSecrets.'
        )
    }

    environment {
        APP_DIR = 'app/employee-api'
        K8S_NAMESPACE = 'devops'
        K8S_DEPLOYMENT = 'employee-api'
        K8S_CONTAINER = 'employee-api'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        KUBECONFIG_CREDENTIAL_ID = 'minikube-kubeconfig'
    }

    stages {
        stage('Checkout and Version') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()
                    env.IMAGE_REPOSITORY = params.DOCKERHUB_REPOSITORY?.trim()
                }
            }
        }

        stage('Build and Test') {
            steps {
                sh 'mvn -B -f "$APP_DIR/pom.xml" clean verify'
            }
            post {
                always {
                    junit testResults: 'app/employee-api/target/surefire-reports/*.xml',
                          allowEmptyResults: true
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    if (!env.IMAGE_REPOSITORY) {
                        error('Set the build parameter DOCKERHUB_REPOSITORY to your Docker Hub repository, for example username/employee-api.')
                    }
                    env.IMAGE = "${env.IMAGE_REPOSITORY}:${env.IMAGE_TAG}"
                }
                sh 'docker build -f "$APP_DIR/Dockerfile" -t "$IMAGE" "$APP_DIR"'
            }
        }

        stage('Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL "$IMAGE"'
            }
        }

        stage('Publish and Deploy') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKERHUB_CREDENTIALS_ID,
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        trap 'docker logout >/dev/null 2>&1 || true' EXIT
                        printf '%s' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
                        docker push "$IMAGE"
                    '''
                }
                withCredentials([file(
                    credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
                    variable: 'KUBECONFIG'
                )]) {
                    sh '''
                        kubectl apply -f k8s/base/namespace.yml
                        kubectl apply -f k8s/base/configmap.yml
                        kubectl apply -f k8s/base/deployment.yml
                        kubectl apply -f k8s/base/service.yml
                        kubectl apply -f k8s/base/serviceaccount.yml
                        kubectl apply -f k8s/base/pdb.yml
                        kubectl apply -f k8s/base/rbac-readonly.yml
                        kubectl apply -f k8s/base/hpa.yml
                        kubectl apply -f ingress.yaml
                        kubectl set image deployment/"$K8S_DEPLOYMENT" "$K8S_CONTAINER"="$IMAGE" -n "$K8S_NAMESPACE"
                        kubectl rollout status deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE" --timeout=180s
                        kubectl get pods -n "$K8S_NAMESPACE" -l app=employee-api
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'if [ -n "$IMAGE" ]; then docker image rm "$IMAGE" 2>/dev/null || true; fi'
        }
        success {
            echo 'Employee API pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review the first failing stage and its console output.'
        }
    }
}
