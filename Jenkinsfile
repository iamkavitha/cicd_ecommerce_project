pipeline {

    agent {
        label 'djworker3'
    }

    environment {

        AWS_REGION = 'ap-south-1'

        AWS_ACCOUNT_ID = '931527443397'

        ECR_REPOSITORY = 'shoprupee'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        ECR_IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}"

        NAMESPACE = 'shoprupee'

        HELM_RELEASE = 'shoprupee'

        HELM_CHART = './helm/shoprupee'

        KUBECONFIG_CREDENTIAL = 'shoprupee-kubeconfig'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }


    stages {


        stage('Verify Tools') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFYING TOOLS"
                    echo "======================================"

                    echo ""
                    echo "===== Git ====="
                    git --version

                    echo ""
                    echo "===== Docker ====="
                    docker --version

                    echo ""
                    echo "===== AWS CLI ====="
                    aws --version

                    echo ""
                    echo "===== kubectl ====="
                    kubectl version --client

                    echo ""
                    echo "===== Helm ====="
                    helm version

                    echo ""
                    echo "All required tools are available."
                '''
            }
        }


        stage('Verify AWS Identity') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "AWS IDENTITY"
                    echo "======================================"

                    aws sts get-caller-identity
                '''
            }
        }


        stage('Verify Helm Chart') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY HELM CHART"
                    echo "======================================"

                    echo ""
                    echo "Chart files:"
                    ls -la ${HELM_CHART}

                    echo ""
                    echo "Template files:"
                    ls -la ${HELM_CHART}/templates

                    echo ""
                    echo "Chart.yaml:"
                    cat ${HELM_CHART}/Chart.yaml
                '''
            }
        }


        stage('Helm Lint') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM LINT"
                    echo "======================================"

                    helm lint ${HELM_CHART}
                '''
            }
        }


        stage('Docker Build') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "DOCKER BUILD"
                    echo "======================================"

                    echo "Building image:"
                    echo "${ECR_IMAGE}:${IMAGE_TAG}"

                    docker build \
                        -t ${ECR_IMAGE}:${IMAGE_TAG} \
                        .

                    docker tag \
                        ${ECR_IMAGE}:${IMAGE_TAG} \
                        ${ECR_IMAGE}:latest

                    echo ""
                    echo "Docker images:"
                    docker images | grep shoprupee
                '''
            }
        }


        stage('ECR Login') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "ECR LOGIN"
                    echo "======================================"

                    aws ecr get-login-password \
                        --region ${AWS_REGION} \
                    | docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}

                    echo "ECR login successful."
                '''
            }
        }


        stage('Push Image to ECR') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSH IMAGE TO ECR"
                    echo "======================================"

                    docker push ${ECR_IMAGE}:${IMAGE_TAG}

                    docker push ${ECR_IMAGE}:latest

                    echo ""
                    echo "Image pushed successfully:"
                    echo "${ECR_IMAGE}:${IMAGE_TAG}"
                '''
            }
        }


        stage('Verify Kubernetes Access') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "KUBERNETES ACCESS"
                        echo "======================================"

                        echo ""
                        echo "Current Context:"
                        kubectl config current-context

                        echo ""
                        echo "Namespace:"
                        kubectl get namespace ${NAMESPACE}

                        echo ""
                        echo "Deployments:"
                        kubectl get deployments -n ${NAMESPACE}

                        echo ""
                        echo "Pods:"
                        kubectl get pods -n ${NAMESPACE}

                        echo ""
                        echo "Services:"
                        kubectl get services -n ${NAMESPACE}

                        echo ""
                        echo "Kubernetes access successful."
                    '''
                }
            }
        }


        stage('Verify Kubernetes RBAC') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "VERIFY KUBERNETES RBAC"
                        echo "======================================"

                        echo ""
                        echo "Current user:"
                        kubectl auth whoami

                        echo ""
                        echo "Deployment GET:"
                        kubectl auth can-i get deployments \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Deployment UPDATE:"
                        kubectl auth can-i update deployments \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Deployment PATCH:"
                        kubectl auth can-i patch deployments \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Pods GET:"
                        kubectl auth can-i get pods \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Services CREATE:"
                        kubectl auth can-i create services \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Secrets CREATE:"
                        kubectl auth can-i create secrets \
                            -n ${NAMESPACE}

                        echo ""
                        echo "ReplicaSets GET:"
                        kubectl auth can-i get replicasets \
                            -n ${NAMESPACE}

                        echo ""
                        echo "RBAC verification completed."
                    '''
                }
            }
        }


        stage('Create ECR Pull Secret') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "CREATE ECR PULL SECRET"
                        echo "======================================"

                        ECR_PASSWORD=$(aws ecr get-login-password \
                            --region ${AWS_REGION})

                        kubectl create secret docker-registry ecr-registry-secret \
                            --docker-server=${ECR_REGISTRY} \
                            --docker-username=AWS \
                            --docker-password="${ECR_PASSWORD}" \
                            --namespace=${NAMESPACE} \
                            --dry-run=client \
                            -o yaml \
                        | kubectl apply -f -

                        echo ""
                        echo "ECR pull secret:"
                        kubectl get secret ecr-registry-secret \
                            -n ${NAMESPACE}
                    '''
                }
            }
        }


        stage('Helm Template') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "HELM TEMPLATE"
                        echo "======================================"

                        helm template ${HELM_RELEASE} ${HELM_CHART} \
                            --namespace ${NAMESPACE} \
                            --set image.repository=${ECR_IMAGE} \
                            --set image.tag=${IMAGE_TAG}
                    '''
                }
            }
        }


        stage('Deploy with Helm') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "HELM DEPLOYMENT"
                        echo "======================================"

                        helm upgrade --install ${HELM_RELEASE} ${HELM_CHART} \
                            --namespace ${NAMESPACE} \
                            --set image.repository=${ECR_IMAGE} \
                            --set image.tag=${IMAGE_TAG} \
                            --wait \
                            --timeout 5m

                        echo ""
                        echo "Helm deployment successful."
                    '''
                }
            }
        }


        stage('Rolling Update') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "ROLLING UPDATE"
                        echo "======================================"

                        kubectl rollout status \
                            deployment/shoprupee \
                            -n ${NAMESPACE} \
                            --timeout=5m
                    '''
                }
            }
        }


        stage('Verify Helm Release') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "HELM RELEASE"
                        echo "======================================"

                        helm list \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Release status:"
                        helm status ${HELM_RELEASE} \
                            -n ${NAMESPACE}
                    '''
                }
            }
        }


        stage('Verify 4 Replicas') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "VERIFY 4 REPLICAS"
                        echo "======================================"

                        kubectl get deployment shoprupee \
                            -n ${NAMESPACE}

                        READY=$(kubectl get deployment shoprupee \
                            -n ${NAMESPACE} \
                            -o jsonpath='{.status.readyReplicas}')

                        echo ""
                        echo "Ready replicas: ${READY}"

                        if [ "${READY}" != "4" ]; then
                            echo "ERROR: Expected 4 ready replicas."
                            exit 1
                        fi

                        echo "4 replicas are running."
                    '''
                }
            }
        }


        stage('Verify Pods') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "VERIFY PODS"
                        echo "======================================"

                        kubectl get pods \
                            -n ${NAMESPACE} \
                            -o wide

                        echo ""
                        echo "Checking pod status..."

                        NOT_RUNNING=$(kubectl get pods \
                            -n ${NAMESPACE} \
                            --no-headers \
                            | awk '$3 != "Running" {count++} END {print count+0}')

                        if [ "${NOT_RUNNING}" != "0" ]; then
                            echo "ERROR: Some pods are not Running."
                            exit 1
                        fi

                        echo ""
                        echo "All ShopRupee pods are Running."
                    '''
                }
            }
        }


        stage('Verify Service') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "VERIFY SERVICE"
                        echo "======================================"

                        kubectl get service shoprupee \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Service details:"

                        kubectl get service shoprupee \
                            -n ${NAMESPACE} \
                            -o wide

                        echo ""
                        echo "ShopRupee NodePort:"
                        kubectl get service shoprupee \
                            -n ${NAMESPACE} \
                            -o jsonpath='{.spec.ports[0].nodePort}'

                        echo ""
                    '''
                }
            }
        }


        stage('Final Verification') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo ""
                        echo "=========================================="
                        echo "SHOPRUPEE DEPLOYMENT SUCCESSFUL"
                        echo "=========================================="

                        echo ""
                        echo "Helm:"
                        helm list -n ${NAMESPACE}

                        echo ""
                        echo "Deployment:"
                        kubectl get deployment \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Pods:"
                        kubectl get pods \
                            -n ${NAMESPACE} \
                            -o wide

                        echo ""
                        echo "Service:"
                        kubectl get service \
                            -n ${NAMESPACE}

                        echo ""
                        echo "Image:"
                        echo "${ECR_IMAGE}:${IMAGE_TAG}"

                        echo ""
                        echo "Application:"
                        echo "http://13.232.204.142:30081/"

                        echo ""
                        echo "=========================================="
                    '''
                }
            }
        }
    }


    post {

        success {

            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE SUCCESS
==========================================

Docker image built and pushed.
Helm chart validated.
Kubernetes RBAC verified.
ECR pull secret created.
Application deployed with Helm.
Rolling update completed.
4 replicas verified.
Service verified.

==========================================
'''
        }

        failure {

            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE FAILED
==========================================

Check the FIRST failed stage in Console Output.

Possible areas:

1. Docker Build
2. ECR Login
3. ECR Push
4. Kubernetes Authentication
5. Kubernetes RBAC
6. ECR Pull Secret
7. Helm Lint
8. Helm Template
9. Helm Deployment
10. Kubernetes Rollout
11. Pod Scheduling
12. ImagePullBackOff
13. CrashLoopBackOff
14. Readiness/Liveness Probe

==========================================
'''
        }
    }
}
