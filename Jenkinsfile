pipeline {

    agent {
        label 'djworker3'
    }

    environment {

        // =====================================================
        // AWS / ECR
        // =====================================================

        AWS_REGION     = 'ap-south-1'

        ECR_REGISTRY   = '931527443397.dkr.ecr.ap-south-1.amazonaws.com'

        ECR_REPOSITORY = 'shoprupee'

        IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"


        // =====================================================
        // Kubernetes
        // =====================================================

        K8S_NAMESPACE  = 'shoprupee'

        K8S_CREDENTIAL = 'shoprupee-kubeconfig'


        // =====================================================
        // Helm
        // =====================================================

        HELM_RELEASE   = 'shoprupee'

        HELM_CHART     = './helm/shoprupee'
    }


    stages {


        // =====================================================
        // 1. VERIFY TOOLS
        // =====================================================

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


        // =====================================================
        // 2. VERIFY AWS IDENTITY
        // =====================================================

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


        // =====================================================
        // 3. VERIFY HELM CHART
        // =====================================================

        stage('Helm Lint') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM LINT"
                    echo "======================================"

                    helm lint ${HELM_CHART}

                    echo ""
                    echo "Helm chart validation successful."
                '''
            }
        }


        // =====================================================
        // 4. DOCKER BUILD
        // =====================================================

        stage('Docker Build') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "BUILDING SHOPRUPEE DOCKER IMAGE"
                    echo "======================================"

                    echo "Image:"
                    echo "${IMAGE}"

                    docker build \
                        -t ${IMAGE} .

                    docker tag \
                        ${IMAGE} \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                    echo ""
                    echo "Docker images:"

                    docker images | grep shoprupee
                '''
            }
        }


        // =====================================================
        // 5. ECR LOGIN
        // =====================================================

        stage('ECR Login') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "LOGGING IN TO AMAZON ECR"
                    echo "======================================"

                    aws ecr get-login-password \
                        --region ${AWS_REGION} | \
                    docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}

                    echo ""
                    echo "ECR login successful."
                '''
            }
        }


        // =====================================================
        // 6. PUSH IMAGE TO ECR
        // =====================================================

        stage('Push Image to ECR') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSHING IMAGE TO ECR"
                    echo "======================================"

                    docker push ${IMAGE}

                    docker push \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                    echo ""
                    echo "Image pushed successfully."

                    echo ""
                    echo "Image:"
                    echo "${IMAGE}"
                '''
            }
        }


        // =====================================================
        // 7. CHECK KUBERNETES ACCESS
        // =====================================================

        stage('Verify Kubernetes Access') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
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
                        echo "Current Kubernetes context:"

                        kubectl config current-context

                        echo ""
                        echo "Kubernetes nodes:"

                        kubectl get nodes

                        echo ""
                        echo "Checking namespace:"

                        kubectl get namespace ${K8S_NAMESPACE}

                        echo ""
                        echo "Kubernetes authentication successful."
                    '''
                }
            }
        }


        // =====================================================
        // 8. CHECK RBAC PERMISSIONS
        // =====================================================

        stage('Verify Kubernetes RBAC') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "KUBERNETES RBAC CHECK"
                        echo "======================================"

                        echo ""
                        echo "Current Kubernetes identity:"

                        kubectl auth whoami || true

                        echo ""
                        echo "Deployment permissions:"

                        kubectl auth can-i \
                            create deployments \
                            -n ${K8S_NAMESPACE}

                        kubectl auth can-i \
                            update deployments \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Service permissions:"

                        kubectl auth can-i \
                            create services \
                            -n ${K8S_NAMESPACE}

                        kubectl auth can-i \
                            update services \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Secret permissions:"

                        kubectl auth can-i \
                            create secrets \
                            -n ${K8S_NAMESPACE}

                        kubectl auth can-i \
                            update secrets \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "RBAC check completed."
                    '''
                }
            }
        }


        // =====================================================
        // 9. CREATE / UPDATE ECR PULL SECRET
        // =====================================================

        stage('Create ECR Pull Secret') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "CREATING / UPDATING ECR PULL SECRET"
                        echo "======================================"

                        ECR_PASSWORD=$(aws ecr get-login-password \
                            --region ${AWS_REGION})

                        kubectl create secret docker-registry \
                            ecr-registry-secret \
                            --docker-server=${ECR_REGISTRY} \
                            --docker-username=AWS \
                            --docker-password="${ECR_PASSWORD}" \
                            --namespace=${K8S_NAMESPACE} \
                            --dry-run=client \
                            -o yaml | kubectl apply -f -

                        echo ""
                        echo "ECR pull secret is ready."

                        kubectl get secret \
                            ecr-registry-secret \
                            -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }


        // =====================================================
        // 10. HELM TEMPLATE
        // =====================================================

        stage('Helm Template') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "RENDERING HELM TEMPLATE"
                    echo "======================================"

                    helm template ${HELM_RELEASE} \
                        ${HELM_CHART} \
                        --namespace ${K8S_NAMESPACE} \
                        --set image.repository=${ECR_REGISTRY}/${ECR_REPOSITORY} \
                        --set image.tag=${BUILD_NUMBER} \
                        --set image.pullPolicy=Always

                    echo ""
                    echo "Helm template rendered successfully."
                '''
            }
        }


        // =====================================================
        // 11. HELM DEPLOYMENT
        // =====================================================

        stage('Deploy with Helm') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "DEPLOYING SHOPRUPEE USING HELM"
                        echo "======================================"

                        echo ""
                        echo "Helm Release:"
                        echo "${HELM_RELEASE}"

                        echo ""
                        echo "Helm Chart:"
                        echo "${HELM_CHART}"

                        echo ""
                        echo "Docker Image:"
                        echo "${IMAGE}"

                        echo ""

                        helm upgrade --install ${HELM_RELEASE} \
                            ${HELM_CHART} \
                            --namespace ${K8S_NAMESPACE} \
                            --set image.repository=${ECR_REGISTRY}/${ECR_REPOSITORY} \
                            --set image.tag=${BUILD_NUMBER} \
                            --set image.pullPolicy=Always

                        echo ""
                        echo "======================================"
                        echo "HELM DEPLOYMENT COMPLETED"
                        echo "======================================"

                        helm status \
                            ${HELM_RELEASE} \
                            --namespace ${K8S_NAMESPACE}
                    '''
                }
            }
        }


        // =====================================================
        // 12. ROLLING UPDATE
        // =====================================================

        stage('Rolling Update') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "WAITING FOR ROLLOUT"
                        echo "======================================"

                        kubectl rollout status \
                            deployment/shoprupee \
                            -n ${K8S_NAMESPACE} \
                            --timeout=180s

                        echo ""
                        echo "Rolling update completed."
                    '''
                }
            }
        }


        // =====================================================
        // 13. VERIFY HELM RELEASE
        // =====================================================

        stage('Verify Helm Release') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
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
                            --namespace ${K8S_NAMESPACE}

                        echo ""

                        helm status \
                            ${HELM_RELEASE} \
                            --namespace ${K8S_NAMESPACE}
                    '''
                }
            }
        }


        // =====================================================
        // 14. VERIFY 4 REPLICAS
        // =====================================================

        stage('Verify 4 Replicas') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "VERIFYING 4 SHOPRUPEE REPLICAS"
                        echo "======================================"

                        kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""

                        READY=$(kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.status.readyReplicas}')

                        READY=${READY:-0}

                        echo "Ready replicas: ${READY}"
                        echo "Expected replicas: 4"

                        if [ "${READY}" -ne 4 ]; then

                            echo ""
                            echo "ERROR: Expected 4 Ready replicas."
                            echo "Current Ready replicas: ${READY}"

                            kubectl get pods \
                                -n ${K8S_NAMESPACE} \
                                -l app=shoprupee \
                                -o wide

                            exit 1

                        fi

                        echo ""
                        echo "SUCCESS: All 4 replicas are Ready."
                    '''
                }
            }
        }


        // =====================================================
        // 15. VERIFY PODS
        // =====================================================

        stage('Verify Pods') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "SHOPRUPEE PODS"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide

                        echo ""
                        echo "Pods by worker:"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o jsonpath='{range .items[*]}{.spec.nodeName}{"\\n"}{end}' \
                            | sort \
                            | uniq -c

                        echo ""
                        echo "Note:"
                        echo "Kubernetes scheduler decides pod placement."
                        echo "We removed affinity/topology constraints."
                    '''
                }
            }
        }


        // =====================================================
        // 16. VERIFY SERVICE
        // =====================================================

        stage('Verify Service') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "SHOPRUPEE SERVICE"
                        echo "======================================"

                        kubectl get service shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Service details:"

                        kubectl describe service shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Endpoints:"

                        kubectl get endpoints \
                            shoprupee \
                            -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }


        // =====================================================
        // 17. FINAL VERIFICATION
        // =====================================================

        stage('Final Verification') {

            steps {

                withCredentials([

                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )

                ]) {

                    sh '''
                        set -e

                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo ""
                        echo "=========================================="
                        echo "FINAL SHOPRUPEE VERIFICATION"
                        echo "=========================================="

                        echo ""
                        echo "===== HELM ====="

                        helm status \
                            ${HELM_RELEASE} \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "===== DEPLOYMENT ====="

                        kubectl get deployment \
                            shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "===== PODS ====="

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide

                        echo ""
                        echo "===== SERVICE ====="

                        kubectl get service \
                            shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "=========================================="
                        echo "SHOPRUPEE DEPLOYMENT SUCCESSFUL"
                        echo "=========================================="

                        echo ""
                        echo "Application:"
                        echo "http://13.232.204.142:30081/"
                    '''
                }
            }
        }
    }


    // =========================================================
    // POST ACTIONS
    // =========================================================

    post {

        success {

            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE SUCCESS
==========================================

GitHub
   ↓
Jenkins
   ↓
DJWorker3
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Kubernetes Authentication
   ↓
ECR Pull Secret
   ↓
Helm Lint
   ↓
Helm Template
   ↓
Helm Upgrade/Install
   ↓
Kubernetes Deployment
   ↓
ReplicaSet
   ↓
4 ShopRupee Pods
   ↓
NodePort 30081
   ↓
ShopRupee Website

==========================================
 HELM RELEASE:
 shoprupee

 NAMESPACE:
 shoprupee

 REPLICAS:
 4

 SERVICE:
 NodePort 30081
==========================================
'''
        }


        failure {

            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE FAILED
==========================================

Check the failed stage in Console Output.

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
