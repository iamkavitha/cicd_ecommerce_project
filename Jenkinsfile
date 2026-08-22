pipeline {

    agent any

    environment {

        // ============================================================
        // AWS / ECR
        // ============================================================

        AWS_REGION = 'us-east-1'

        AWS_ACCOUNT_ID = '369559608554'

        ECR_REPOSITORY = 'cicd_ecommerce'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        ECR_IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}"

        // Jenkins build number becomes Docker image tag
        IMAGE_TAG = "${BUILD_NUMBER}"


        // ============================================================
        // Kubernetes
        // ============================================================

        NAMESPACE = 'shoprupee'

        // Jenkins master and Kubernetes master are the same server
        KUBECONFIG = '/var/lib/jenkins/.kube/config'


        // ============================================================
        // Helm
        // ============================================================

        HELM_CHART = './helm/shoprupee'

        HELM_RELEASE = 'shoprupee'
    }


    stages {

        // ============================================================
        // 1. VERIFY TOOLS
        // ============================================================

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


        // ============================================================
        // 2. VERIFY AWS IDENTITY
        // ============================================================

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


        // ============================================================
        // 3. VERIFY HELM CHART
        // ============================================================

        stage('Verify Helm Chart') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY HELM CHART"
                    echo "======================================"

                    echo ""
                    echo "Chart directory:"
                    ls -la ${HELM_CHART}

                    echo ""
                    echo "Template directory:"
                    ls -la ${HELM_CHART}/templates

                    echo ""
                    echo "Chart.yaml:"
                    cat ${HELM_CHART}/Chart.yaml

                    echo ""
                    echo "values.yaml:"
                    cat ${HELM_CHART}/values.yaml
                '''
            }
        }


        // ============================================================
        // 4. HELM LINT
        // ============================================================

        stage('Helm Lint') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM LINT"
                    echo "======================================"

                    helm lint ${HELM_CHART}

                    echo ""
                    echo "Helm lint successful."
                '''
            }
        }


        // ============================================================
        // 5. DOCKER BUILD
        // ============================================================

        stage('Docker Build') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "DOCKER BUILD"
                    echo "======================================"

                    echo ""
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
                    docker images | grep shoprupee || true

                    echo ""
                    echo "Docker build successful."
                '''
            }
        }


        // ============================================================
        // 6. ECR LOGIN
        // ============================================================

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

                    echo ""
                    echo "ECR login successful."
                '''
            }
        }


        // ============================================================
        // 7. PUSH IMAGE TO ECR
        // ============================================================

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSH IMAGE TO ECR"
                    echo "======================================"

                    echo ""
                    echo "Pushing:"
                    echo "${ECR_IMAGE}:${IMAGE_TAG}"

                    docker push ${ECR_IMAGE}:${IMAGE_TAG}

                    echo ""
                    echo "Pushing latest tag..."

                    docker push ${ECR_IMAGE}:latest

                    echo ""
                    echo "Image pushed successfully."
                '''
            }
        }


        // ============================================================
        // 8. VERIFY KUBERNETES ACCESS
        // ============================================================

        stage('Verify Kubernetes Access') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "KUBERNETES ACCESS"
                    echo "======================================"

                    echo ""
                    echo "Kubeconfig:"
                    echo "${KUBECONFIG}"

                    echo ""
                    echo "Current Context:"
                    kubectl config current-context

                    echo ""
                    echo "Current Kubernetes User:"
                    kubectl auth whoami

                    echo ""
                    echo "Kubernetes Nodes:"
                    kubectl get nodes -o wide

                    echo ""
                    echo "ShopRupee Deployment:"
                    kubectl get deployment \
                        shoprupee \
                        -n ${NAMESPACE} \
                        || true

                    echo ""
                    echo "ShopRupee Pods:"
                    kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        -o wide \
                        || true

                    echo ""
                    echo "ShopRupee Service:"
                    kubectl get service \
                        shoprupee \
                        -n ${NAMESPACE} \
                        || true

                    echo ""
                    echo "Kubernetes access successful."
                '''
            }
        }


        // ============================================================
        // 9. VERIFY KUBERNETES RBAC
        // ============================================================

        stage('Verify Kubernetes RBAC') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "KUBERNETES RBAC"
                    echo "======================================"

                    echo ""
                    echo "Get Deployments:"
                    kubectl auth can-i get deployments \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Update Deployments:"
                    kubectl auth can-i update deployments \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Patch Deployments:"
                    kubectl auth can-i patch deployments \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Get Pods:"
                    kubectl auth can-i get pods \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Get ReplicaSets:"
                    kubectl auth can-i get replicasets \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Create Secrets:"
                    kubectl auth can-i create secrets \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Create Services:"
                    kubectl auth can-i create services \
                        -n ${NAMESPACE}

                    echo ""
                    echo "RBAC verification completed."
                '''
            }
        }


        // ============================================================
        // 10. CREATE / UPDATE ECR PULL SECRET
        // ============================================================

        stage('Create ECR Pull Secret') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "CREATE ECR PULL SECRET"
                    echo "======================================"

                    echo ""
                    echo "Creating/updating ECR pull secret..."

                    set +x

                    ECR_PASSWORD=$(aws ecr get-login-password \
                        --region ${AWS_REGION})

                    kubectl create secret docker-registry \
                        ecr-registry-secret \
                        --docker-server=${ECR_REGISTRY} \
                        --docker-username=AWS \
                        --docker-password="${ECR_PASSWORD}" \
                        -n ${NAMESPACE} \
                        --dry-run=client \
                        -o yaml \
                    | kubectl apply -f -

                    unset ECR_PASSWORD

                    set -x

                    echo ""
                    echo "ECR pull secret created/updated."

                    kubectl get secret \
                        ecr-registry-secret \
                        -n ${NAMESPACE}
                '''
            }
        }


        // ============================================================
        // 11. HELM TEMPLATE
        // ============================================================

        stage('Helm Template') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM TEMPLATE"
                    echo "======================================"

                    helm template \
                        ${HELM_RELEASE} \
                        ${HELM_CHART} \
                        --namespace ${NAMESPACE} \
                        --set image.repository=${ECR_IMAGE} \
                        --set image.tag=${IMAGE_TAG}

                    echo ""
                    echo "Helm template generated successfully."
                '''
            }
        }


        // ============================================================
        // 12. DEPLOY WITH HELM
        // ============================================================

        stage('Deploy with Helm') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "DEPLOY WITH HELM"
                    echo "======================================"

                    echo ""
                    echo "Helm Release:"
                    echo "${HELM_RELEASE}"

                    echo ""
                    echo "Namespace:"
                    echo "${NAMESPACE}"

                    echo ""
                    echo "Image:"
                    echo "${ECR_IMAGE}:${IMAGE_TAG}"

                    helm upgrade --install \
                        ${HELM_RELEASE} \
                        ${HELM_CHART} \
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


        // ============================================================
        // 13. ROLLING UPDATE
        // ============================================================

//         stage('Rolling Update') {
//             steps {
//                 sh '''
//                     set -e
//
//                     echo "======================================"
//                     echo "ROLLING UPDATE"
//                     echo "======================================"
//
//                     kubectl rollout status \
//                         deployment/${HELM_RELEASE} \
//                         -n ${NAMESPACE} \
//                         --timeout=5m
//
//                     echo ""
//                     echo "Rolling update completed."
//                 '''
//             }
//         }


        // ============================================================
        // 14. VERIFY HELM RELEASE
        // ============================================================

        stage('Verify Helm Release') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM RELEASE"
                    echo "======================================"

                    helm list \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Helm release details:"

                    helm status \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE}
                '''
            }
        }


        // ============================================================
        // 15. VERIFY 4 SHOPRUPEE REPLICAS
        // ============================================================

        stage('Verify 4 Replicas') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY 4 SHOPRUPEE REPLICAS"
                    echo "======================================"

                    kubectl get deployment \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE}

                    DESIRED=$(kubectl get deployment \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE} \
                        -o jsonpath='{.spec.replicas}')

                    READY=$(kubectl get deployment \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE} \
                        -o jsonpath='{.status.readyReplicas}')

                    echo ""
                    echo "Desired replicas: ${DESIRED}"
                    echo "Ready replicas:   ${READY}"

                    if [ "${DESIRED}" != "4" ]; then
                        echo "ERROR: Expected 4 replicas."
                        exit 1
                    fi

                    if [ "${READY}" != "4" ]; then
                        echo "ERROR: ShopRupee does not have 4 ready replicas."
                        exit 1
                    fi

                    echo ""
                    echo "All 4 ShopRupee replicas are READY."
                '''
            }
        }


        // ============================================================
        // 16. VERIFY SHOPRUPEE PODS ONLY
        // ============================================================

        stage('Verify Shoprupee Pods') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY SHOPRUPEE PODS ONLY"
                    echo "======================================"

                    echo ""
                    echo "ShopRupee pods:"
                    echo ""

                    kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        -o wide

                    echo ""
                    echo "Java pods are intentionally ignored."
                    echo "This pipeline validates only app=shoprupee."

                    echo ""
                    echo "Checking ShopRupee rollout..."

                    kubectl rollout status \
                        deployment/${HELM_RELEASE} \
                        -n ${NAMESPACE} \
                        --timeout=5m

                    echo ""
                    echo "Checking ShopRupee pod count..."

                    POD_COUNT=$(kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        --no-headers \
                        | wc -l)

                    echo "ShopRupee pod count: ${POD_COUNT}"

                    if [ "${POD_COUNT}" != "4" ]; then
                        echo "ERROR: Expected 4 ShopRupee pods."
                        exit 1
                    fi

                    echo ""
                    echo "Checking ShopRupee pod statuses..."

                    NOT_RUNNING=$(kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        --no-headers \
                        | awk '$3 != "Running" {count++} END {print count+0}')

                    if [ "${NOT_RUNNING}" != "0" ]; then
                        echo "ERROR: One or more ShopRupee pods are not Running."
                        exit 1
                    fi

                    echo ""
                    echo "Checking ShopRupee READY containers..."

                    NOT_READY=$(kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        --no-headers \
                        | awk '$2 != "1/1" {count++} END {print count+0}')

                    if [ "${NOT_READY}" != "0" ]; then
                        echo "ERROR: One or more ShopRupee pods are not Ready."
                        exit 1
                    fi

                    echo ""
                    echo "======================================"
                    echo "SHOPRUPEE PODS ARE HEALTHY"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // 17. VERIFY SHOPRUPEE SERVICE
        // ============================================================

        stage('Verify Service') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY SHOPRUPEE SERVICE"
                    echo "======================================"

                    echo ""
                    echo "Service:"

                    kubectl get service \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Service endpoints:"

                    kubectl get endpoints \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE} \
                        || true

                    echo ""
                    echo "Service verification completed."
                '''
            }
        }


        // ============================================================
        // 18. FINAL VERIFICATION
        // ============================================================

        stage('Final Verification') {
            steps {
                sh '''
                    set -e

                    echo ""
                    echo "================================================"
                    echo "        SHOPRUPEE DEPLOYMENT SUCCESS"
                    echo "================================================"

                    echo ""
                    echo "Kubernetes Context:"
                    kubectl config current-context

                    echo ""
                    echo "Helm Release:"
                    helm list \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Deployment:"
                    kubectl get deployment \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE}

                    echo ""
                    echo "ShopRupee Pods Only:"
                    kubectl get pods \
                        -n ${NAMESPACE} \
                        -l app=shoprupee \
                        -o wide

                    echo ""
                    echo "Service:"
                    kubectl get service \
                        ${HELM_RELEASE} \
                        -n ${NAMESPACE}

                    echo ""
                    echo "Image:"
                    echo "${ECR_IMAGE}:${IMAGE_TAG}"

                    echo ""
                    echo "================================================"
                    echo "        DEPLOYMENT COMPLETED SUCCESSFULLY"
                    echo "================================================"
                '''
            }
        }
    }


    // ================================================================
    // POST ACTIONS
    // ================================================================

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
Docker Build
   ↓
Amazon ECR
   ↓
Kubernetes Authentication
   ↓
RBAC
   ↓
ECR Pull Secret
   ↓
Helm Lint
   ↓
Helm Template
   ↓
Helm Upgrade/Install
   ↓
Rolling Update
   ↓
4 ShopRupee Pods
   ↓
ShopRupee Service
   ↓
SUCCESS

NOTE:
Java application runs in the same namespace,
but this pipeline verifies only:
app=shoprupee

SHOPRUPEE DEPLOYMENT SUCCESSFUL
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

NOTE:
Java pods in the shared namespace are NOT
used for ShopRupee pod verification.

==========================================
'''
        }
    }
}