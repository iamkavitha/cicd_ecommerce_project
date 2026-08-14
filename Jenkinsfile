pipeline {

    agent {
        label 'djworker3'
    }

    environment {
        AWS_REGION     = 'ap-south-1'
        ECR_REGISTRY   = '931527443397.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'shoprupee'
        IMAGE          = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

        K8S_NAMESPACE  = 'shoprupee'
        K8S_CREDENTIAL = 'shoprupee-kubeconfig'
    }

    stages {

        // =========================================================
        // 1. VERIFY TOOLS
        // =========================================================

        stage('Verify Tools') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Verifying Tools"
                    echo "======================================"

                    echo "===== Git ====="
                    git --version

                    echo "===== Docker ====="
                    docker --version

                    echo "===== AWS CLI ====="
                    aws --version

                    echo "===== kubectl ====="
                    kubectl version --client
                '''
            }
        }


        // =========================================================
        // 2. VERIFY AWS IDENTITY
        // =========================================================

        stage('Verify AWS Identity') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "AWS Identity"
                    echo "======================================"

                    aws sts get-caller-identity
                '''
            }
        }


        // =========================================================
        // 3. DOCKER BUILD
        // =========================================================

        stage('Docker Build') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Building ShopRupee Docker Image"
                    echo "======================================"

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


        // =========================================================
        // 4. ECR LOGIN
        // =========================================================

        stage('ECR Login') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Logging in to Amazon ECR"
                    echo "======================================"

                    aws ecr get-login-password \
                        --region ${AWS_REGION} | \
                    docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}

                    echo "ECR login successful."
                '''
            }
        }


        // =========================================================
        // 5. PUSH IMAGE TO ECR
        // =========================================================

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "Pushing ShopRupee Image to ECR"
                    echo "======================================"

                    docker push ${IMAGE}

                    docker push \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

                    echo "Image pushed successfully."
                    echo "Image: ${IMAGE}"
                '''
            }
        }


        // =========================================================
        // 6. CHECK KUBERNETES ACCESS
        // =========================================================

        stage('Deploy Namespace') {
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
                        echo "Checking Kubernetes Access"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Checking Deployment Permission..."

                        kubectl auth can-i \
                            create deployments \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Checking Secret Permission..."

                        kubectl auth can-i \
                            create secrets \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "Kubernetes access verified."
                    '''
                }
            }
        }


        // =========================================================
        // 7. CREATE / UPDATE ECR PULL SECRET
        // =========================================================

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
                        echo "Creating/Updating ECR Pull Secret"
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


        // =========================================================
        // 8. DEPLOY SHOPRUPEE
        // =========================================================

        stage('Deploy ShopRupee') {
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
                        echo "Deploying ShopRupee"
                        echo "======================================"

                        echo "Image:"
                        echo "${IMAGE}"

                        sed "s|SHOPRUPEE_ECR_IMAGE|${IMAGE}|g" \
                            k8s/deployment.yaml | \
                            kubectl apply -f -

                        echo ""

                        kubectl apply \
                            -f k8s/service.yaml

                        echo ""
                        echo "ShopRupee resources applied."
                    '''
                }
            }
        }


        // =========================================================
        // 9. ROLLING UPDATE - NON BLOCKING FOR LAB
        // =========================================================

        stage('Rolling Update') {
            steps {
                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "Checking Rollout Status"
                        echo "======================================"

                        kubectl rollout status \
                            deployment/shoprupee \
                            -n ${K8S_NAMESPACE} \
                            --timeout=30s || true

                        echo ""
                        echo "Current Deployment:"
                        kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} || true

                        echo ""
                        echo "Current ReplicaSets:"
                        kubectl get rs \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee || true

                        echo ""
                        echo "Current Pods:"
                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide || true

                        echo ""
                        echo "Recent Kubernetes Events:"
                        kubectl get events \
                            -n ${K8S_NAMESPACE} \
                            --sort-by=.lastTimestamp \
                            | tail -30 || true

                        echo ""
                        echo "Rollout diagnostic completed."
                    '''
                }
            }
        }


        // =========================================================
        // 10. VERIFY REPLICAS - NON BLOCKING FOR LAB
        // =========================================================

        stage('Verify 4 Replicas') {
            steps {
                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "ShopRupee Replica Status"
                        echo "======================================"

                        kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} || true

                        READY=$(kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.status.readyReplicas}' \
                            2>/dev/null || echo "0")

                        READY=${READY:-0}

                        echo ""
                        echo "Ready replicas: ${READY}"
                        echo "Expected healthy state: 4"

                        if [ "${READY}" = "4" ]; then
                            echo ""
                            echo "SUCCESS: 4 replicas are Ready."
                        else
                            echo ""
                            echo "WARNING: Deployment is not healthy yet."
                            echo "This is allowed during troubleshooting practice."
                        fi
                    '''
                }
            }
        }


        // =========================================================
        // 11. VERIFY POD DISTRIBUTION - NON BLOCKING
        // =========================================================

        stage('Verify 2 Pods Per Worker') {
            steps {
                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "Pod Distribution"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide || true

                        echo ""
                        echo "Pods by Kubernetes worker:"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o jsonpath='{range .items[*]}{.spec.nodeName}{"\\n"}{end}' \
                            | sort \
                            | uniq -c || true

                        echo ""
                        echo "Healthy target:"
                        echo "4 Running ShopRupee pods"

                        POD_COUNT=$(kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            --field-selector=status.phase=Running \
                            --no-headers 2>/dev/null \
                            | wc -l)

                        echo ""
                        echo "Current Running pods: ${POD_COUNT}"

                        if [ "${POD_COUNT}" -eq 4 ]; then
                            echo ""
                            echo "SUCCESS: 4 ShopRupee pods are Running."
                        else
                            echo ""
                            echo "WARNING: Less than 4 pods are Running."
                            echo "This is allowed during troubleshooting practice."
                        fi
                    '''
                }
            }
        }


        // =========================================================
        // 12. VERIFY SERVICE
        // =========================================================

        stage('Verify Service') {
            steps {
                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo "======================================"
                        echo "ShopRupee Service"
                        echo "======================================"

                        kubectl get service shoprupee \
                            -n ${K8S_NAMESPACE} || true

                        echo ""
                        echo "======================================"
                        echo "ShopRupee Pods"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide || true

                        echo ""
                        echo "======================================"
                        echo "ShopRupee Endpoints"
                        echo "======================================"

                        kubectl get endpoints \
                            shoprupee \
                            -n ${K8S_NAMESPACE} || true
                    '''
                }
            }
        }


        // =========================================================
        // 13. TROUBLESHOOTING SUMMARY
        // =========================================================

        stage('Troubleshooting Summary') {
            steps {
                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="${KUBECONFIG_FILE}"

                        echo ""
                        echo "======================================"
                        echo "KUBERNETES TROUBLESHOOTING SUMMARY"
                        echo "======================================"

                        echo ""
                        echo "===== POD STATUS ====="

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide || true

                        echo ""
                        echo "===== DEPLOYMENT ====="

                        kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} || true

                        echo ""
                        echo "===== RECENT EVENTS ====="

                        kubectl get events \
                            -n ${K8S_NAMESPACE} \
                            --sort-by=.lastTimestamp \
                            | tail -40 || true

                        echo ""
                        echo "======================================"
                        echo "Diagnostic stages completed."
                        echo "======================================"
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
 SHOPRUPEE PIPELINE COMPLETED
==========================================

GitHub
   ↓
Jenkins
   ↓
DJworker3
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Kubernetes
   ↓
Deployment
   ↓
4 Replicas
   ↓
Troubleshooting Diagnostics
==========================================

NOTE:
The verification stages are currently
NON-BLOCKING for Kubernetes troubleshooting
practice.

An unhealthy Pod will be reported but will
not automatically fail this Jenkins build.
==========================================
'''
        }

        failure {
            echo '''
==========================================
 SHOPRUPEE PIPELINE FAILED
==========================================

The failure occurred in a BUILD,
ECR, AUTHENTICATION, SECRET, or DEPLOYMENT
stage.

Check the failed stage in Console Output.
==========================================
'''
        }
    }
}
