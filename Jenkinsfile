pipeline {

    agent any

    environment {

        AWS_REGION = 'ap-south-1'

        AWS_ACCOUNT_ID = '931527443397'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        ECR_REPOSITORY = 'shoprupee'

        IMAGE_REPOSITORY = "${ECR_REGISTRY}/${ECR_REPOSITORY}"

        IMAGE_TAG = "${BUILD_NUMBER}"

        K8S_NAMESPACE = 'shoprupee'

        HELM_RELEASE = 'shoprupee'

        HELM_CHART = './helm/shoprupee'

        KUBECONFIG_CREDENTIAL = 'KUBECONFIG_FILE'
    }

    stages {

        /*
         * ============================================================
         * VERIFY TOOLS
         * ============================================================
         */
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


        /*
         * ============================================================
         * VERIFY AWS IDENTITY
         * ============================================================
         */
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


        /*
         * ============================================================
         * VERIFY HELM CHART
         * ============================================================
         */
        stage('Verify Helm Chart') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY HELM CHART"
                    echo "======================================"

                    echo ""
                    echo "Chart files:"
                    ls -la ./helm/shoprupee

                    echo ""
                    echo "Template files:"
                    ls -la ./helm/shoprupee/templates

                    echo ""
                    echo "Chart.yaml:"
                    cat ./helm/shoprupee/Chart.yaml

                    echo ""
                    echo "values.yaml:"
                    cat ./helm/shoprupee/values.yaml
                '''
            }
        }


        /*
         * ============================================================
         * HELM LINT
         * ============================================================
         */
        stage('Helm Lint') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM LINT"
                    echo "======================================"

                    helm lint ./helm/shoprupee

                    echo ""
                    echo "Helm lint successful."
                '''
            }
        }


        /*
         * ============================================================
         * DOCKER BUILD
         * ============================================================
         */
        stage('Docker Build') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "DOCKER BUILD"
                    echo "======================================"

                    echo ""
                    echo "Building image:"
                    echo "${IMAGE_REPOSITORY}:${IMAGE_TAG}"

                    docker build \
                        -t "${IMAGE_REPOSITORY}:${IMAGE_TAG}" \
                        .

                    docker tag \
                        "${IMAGE_REPOSITORY}:${IMAGE_TAG}" \
                        "${IMAGE_REPOSITORY}:latest"

                    echo ""
                    echo "Docker images:"
                    docker images | grep shoprupee || true

                    echo ""
                    echo "Docker build successful."
                '''
            }
        }


        /*
         * ============================================================
         * ECR LOGIN
         * ============================================================
         */
        stage('ECR Login') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "ECR LOGIN"
                    echo "======================================"

                    aws ecr get-login-password \
                        --region "${AWS_REGION}" \
                        | docker login \
                            --username AWS \
                            --password-stdin "${ECR_REGISTRY}"

                    echo ""
                    echo "ECR login successful."
                '''
            }
        }


        /*
         * ============================================================
         * PUSH IMAGE TO ECR
         * ============================================================
         */
        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSH IMAGE TO ECR"
                    echo "======================================"

                    docker push "${IMAGE_REPOSITORY}:${IMAGE_TAG}"

                    docker push "${IMAGE_REPOSITORY}:latest"

                    echo ""
                    echo "Image pushed successfully:"
                    echo "${IMAGE_REPOSITORY}:${IMAGE_TAG}"
                '''
            }
        }


        /*
         * ============================================================
         * VERIFY KUBERNETES ACCESS
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "KUBERNETES ACCESS"
                        echo "======================================"

                        echo ""
                        echo "Current Context:"
                        kubectl config current-context

                        echo ""
                        echo "Current Kubernetes User:"
                        kubectl auth whoami

                        echo ""
                        echo "Deployments:"
                        kubectl get deployments -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "ShopRupee Pods:"
                        kubectl get pods \
                            -n "${K8S_NAMESPACE}" \
                            -l app=shoprupee

                        echo ""
                        echo "Services:"
                        kubectl get services -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Kubernetes access successful."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * VERIFY KUBERNETES RBAC
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "KUBERNETES RBAC"
                        echo "======================================"

                        echo ""
                        echo "Get Deployments:"
                        kubectl auth can-i get deployments \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Update Deployments:"
                        kubectl auth can-i update deployments \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Patch Deployments:"
                        kubectl auth can-i patch deployments \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Get Pods:"
                        kubectl auth can-i get pods \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Get ReplicaSets:"
                        kubectl auth can-i get replicasets \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Create Secrets:"
                        kubectl auth can-i create secrets \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Create Services:"
                        kubectl auth can-i create services \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "RBAC verification completed."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * CREATE / UPDATE ECR PULL SECRET
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "CREATE ECR PULL SECRET"
                        echo "======================================"

                        # Disable shell tracing so the temporary ECR
                        # authentication token cannot appear in Jenkins logs.
                        set +x

                        ECR_PASSWORD=$(aws ecr get-login-password \
                            --region "${AWS_REGION}")

                        kubectl create secret docker-registry ecr-registry-secret \
                            --docker-server="${ECR_REGISTRY}" \
                            --docker-username=AWS \
                            --docker-password="${ECR_PASSWORD}" \
                            -n "${K8S_NAMESPACE}" \
                            --dry-run=client \
                            -o yaml \
                            | kubectl apply -f -

                        unset ECR_PASSWORD

                        set -x

                        echo ""
                        echo "ECR pull secret created/updated."

                        kubectl get secret \
                            ecr-registry-secret \
                            -n "${K8S_NAMESPACE}"
                    '''
                }
            }
        }


        /*
         * ============================================================
         * HELM TEMPLATE
         * ============================================================
         */
        stage('Helm Template') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "HELM TEMPLATE"
                    echo "======================================"

                    helm template \
                        "${HELM_RELEASE}" \
                        "${HELM_CHART}" \
                        --namespace "${K8S_NAMESPACE}" \
                        --set image.repository="${IMAGE_REPOSITORY}" \
                        --set image.tag="${IMAGE_TAG}"

                    echo ""
                    echo "Helm template generated successfully."
                '''
            }
        }


        /*
         * ============================================================
         * DEPLOY WITH HELM
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "DEPLOY WITH HELM"
                        echo "======================================"

                        echo ""
                        echo "Helm Release:"
                        echo "${HELM_RELEASE}"

                        echo ""
                        echo "Namespace:"
                        echo "${K8S_NAMESPACE}"

                        echo ""
                        echo "Image:"
                        echo "${IMAGE_REPOSITORY}:${IMAGE_TAG}"

                        helm upgrade --install \
                            "${HELM_RELEASE}" \
                            "${HELM_CHART}" \
                            --namespace "${K8S_NAMESPACE}" \
                            --set image.repository="${IMAGE_REPOSITORY}" \
                            --set image.tag="${IMAGE_TAG}" \
                            --wait \
                            --timeout 5m

                        echo ""
                        echo "Helm deployment successful."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * ROLLING UPDATE
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "ROLLING UPDATE"
                        echo "======================================"

                        kubectl rollout status \
                            deployment/shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            --timeout=5m

                        echo ""
                        echo "Rolling update completed."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * VERIFY HELM RELEASE
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "HELM RELEASE"
                        echo "======================================"

                        helm list \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Helm release details:"

                        helm status \
                            "${HELM_RELEASE}" \
                            -n "${K8S_NAMESPACE}"
                    '''
                }
            }
        }


        /*
         * ============================================================
         * VERIFY 4 REPLICAS
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "VERIFY 4 REPLICAS"
                        echo "======================================"

                        kubectl get deployment shoprupee \
                            -n "${K8S_NAMESPACE}"

                        DESIRED=$(kubectl get deployment shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            -o jsonpath='{.spec.replicas}')

                        READY=$(kubectl get deployment shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            -o jsonpath='{.status.readyReplicas}')

                        DESIRED=${DESIRED:-0}
                        READY=${READY:-0}

                        echo ""
                        echo "Desired replicas: ${DESIRED}"
                        echo "Ready replicas:   ${READY}"

                        if [ "${DESIRED}" != "4" ]; then
                            echo ""
                            echo "ERROR: Expected 4 replicas."
                            exit 1
                        fi

                        if [ "${READY}" != "4" ]; then
                            echo ""
                            echo "ERROR: All 4 replicas are not READY."
                            exit 1
                        fi

                        echo ""
                        echo "All 4 replicas are READY."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * VERIFY SHOPRUPEE PODS
         *
         * IMPORTANT:
         * This stage checks ONLY pods with:
         *
         *     app=shoprupee
         *
         * It will NOT fail because java-app pods are broken.
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "VERIFY SHOPRUPEE PODS"
                        echo "======================================"

                        echo ""
                        echo "ShopRupee pods:"

                        kubectl get pods \
                            -n "${K8S_NAMESPACE}" \
                            -l app=shoprupee \
                            -o wide

                        echo ""
                        echo "Checking ShopRupee pod statuses..."

                        POD_COUNT=$(kubectl get pods \
                            -n "${K8S_NAMESPACE}" \
                            -l app=shoprupee \
                            --no-headers \
                            | wc -l)

                        echo "ShopRupee pod count: ${POD_COUNT}"

                        if [ "${POD_COUNT}" != "4" ]; then
                            echo ""
                            echo "ERROR: Expected 4 ShopRupee pods."
                            exit 1
                        fi

                        NOT_RUNNING=$(kubectl get pods \
                            -n "${K8S_NAMESPACE}" \
                            -l app=shoprupee \
                            --no-headers \
                            | awk '$3 != "Running" {count++} END {print count+0}')

                        if [ "${NOT_RUNNING}" != "0" ]; then
                            echo ""
                            echo "ERROR: Some ShopRupee pods are not Running."

                            kubectl get pods \
                                -n "${K8S_NAMESPACE}" \
                                -l app=shoprupee

                            echo ""
                            echo "Pod details:"

                            kubectl describe pods \
                                -n "${K8S_NAMESPACE}" \
                                -l app=shoprupee

                            exit 1
                        fi

                        echo ""
                        echo "All ShopRupee pods are Running."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * VERIFY SERVICE
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "======================================"
                        echo "VERIFY SERVICE"
                        echo "======================================"

                        kubectl get service shoprupee \
                            -n "${K8S_NAMESPACE}"

                        SERVICE_TYPE=$(kubectl get service shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            -o jsonpath='{.spec.type}')

                        NODE_PORT=$(kubectl get service shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            -o jsonpath='{.spec.ports[0].nodePort}')

                        echo ""
                        echo "Service Type: ${SERVICE_TYPE}"
                        echo "NodePort:     ${NODE_PORT}"

                        if [ "${SERVICE_TYPE}" != "NodePort" ]; then
                            echo ""
                            echo "ERROR: Expected Service type NodePort."
                            exit 1
                        fi

                        echo ""
                        echo "Service verification successful."
                    '''
                }
            }
        }


        /*
         * ============================================================
         * FINAL VERIFICATION
         * ============================================================
         */
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

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "=========================================="
                        echo "FINAL SHOPRUPEE VERIFICATION"
                        echo "=========================================="

                        echo ""
                        echo "Deployment:"
                        kubectl get deployment shoprupee \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Pods:"
                        kubectl get pods \
                            -n "${K8S_NAMESPACE}" \
                            -l app=shoprupee \
                            -o wide

                        echo ""
                        echo "Service:"
                        kubectl get service shoprupee \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Helm:"
                        helm status \
                            "${HELM_RELEASE}" \
                            -n "${K8S_NAMESPACE}"

                        echo ""
                        echo "Image:"
                        kubectl get deployment shoprupee \
                            -n "${K8S_NAMESPACE}" \
                            -o jsonpath='{.spec.template.spec.containers[0].image}'

                        echo ""

                        echo ""
                        echo "=========================================="
                        echo " SHOPRUPEE DEPLOYMENT SUCCESSFUL"
                        echo "=========================================="
                    '''
                }
            }
        }
    }


    /*
     * ================================================================
     * POST ACTIONS
     * ================================================================
     */
    post {

        success {
            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE SUCCESSFUL
==========================================

Deployment:
    shoprupee

Namespace:
    shoprupee

Replicas:
    4/4

Image:
    ECR image successfully deployed

Status:
    SUCCESS
==========================================
'''
        }

        failure {
            echo '''
==========================================
 SHOPRUPEE HELM PIPELINE FAILED
==========================================

Check the FIRST failed stage in Console Output.

Important checks:

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
The Verify Pods stage checks only:

    app=shoprupee

It does NOT check unrelated deployments
such as java-app.

==========================================
'''
        }

        always {
            echo "Jenkins pipeline completed."
        }
    }
}
