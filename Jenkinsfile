pipeline {

    agent {
        label 'djworker3'
    }

    environment {
        AWS_REGION    = 'ap-south-1'
        ECR_REGISTRY  = '931527443397.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'shoprupee'
        IMAGE         = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

        K8S_NAMESPACE = 'shoprupee'
        K8S_CREDENTIAL = 'shoprupee-kubeconfig'
    }

    stages {

        stage('Verify Tools') {
            steps {
                sh '''
                    set -e

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

        stage('Verify AWS Identity') {
            steps {
                sh '''
                    set -e

                    echo "===== AWS Identity ====="
                    aws sts get-caller-identity
                '''
            }
        }

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

                    echo "Docker image created:"
                    docker images | grep shoprupee
                '''
            }
        }

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
                '''
            }
        }

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
                '''
            }
        }

       stage('Deploy Namespace') {
    steps {
        withCredentials([file(credentialsId: 'shoprupee-kubeconfig', variable: 'KUBECONFIG_FILE')]) {
            sh '''
                set -e
                export KUBECONFIG="$KUBECONFIG_FILE"

                echo "======================================"
                echo "Checking Kubernetes Access"
                echo "======================================"

                kubectl get pods -n shoprupee

                echo "Checking Deployment Permission..."
                kubectl auth can-i create deployments -n shoprupee

                echo "Checking Secret Permission..."
                kubectl auth can-i create secrets -n shoprupee
            '''
        }
    }
}

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

                        kubectl create secret docker-registry ecr-registry-secret \
                            --docker-server=${ECR_REGISTRY} \
                            --docker-username=AWS \
                            --docker-password="${ECR_PASSWORD}" \
                            --namespace=${K8S_NAMESPACE} \
                            --dry-run=client \
                            -o yaml | kubectl apply -f -

                        echo "ECR pull secret is ready."
                    '''
                }
            }
        }

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

                        kubectl apply -f k8s/service.yaml

                        echo "ShopRupee resources applied."
                    '''
                }
            }
        }

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
                        echo "Waiting for Zero-Downtime Rollout"
                        echo "======================================"

                        kubectl rollout status \
                            deployment/shoprupee \
                            -n ${K8S_NAMESPACE} \
                            --timeout=5m

                        echo "Rollout completed successfully."
                    '''
                }
            }
        }

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
                        echo "Checking ShopRupee Replicas"
                        echo "======================================"

                        kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE}

                        READY=$(kubectl get deployment shoprupee \
                            -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.status.readyReplicas}')

                        echo "Ready replicas: ${READY}"

                        if [ "${READY}" != "4" ]; then
                            echo "ERROR: Expected 4 ready replicas."
                            exit 1
                        fi

                        echo "SUCCESS: 4 replicas are Ready."
                    '''
                }
            }
        }

        stage('Verify 2 Pods Per Worker') {
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
                        echo "Pod Distribution"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide

                        echo ""
                        echo "Pods by Kubernetes worker:"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o jsonpath='{range .items[*]}{.spec.nodeName}{"\\n"}{end}' \
                            | sort \
                            | uniq -c

                        echo ""
                        echo "Expected:"
                        echo "Worker 1 = 2 pods"
                        echo "Worker 2 = 2 pods"

                        POD_COUNT=$(kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            --field-selector=status.phase=Running \
                            --no-headers | wc -l)

                        if [ "${POD_COUNT}" -ne 4 ]; then
                            echo "ERROR: Expected 4 Running pods."
                            exit 1
                        fi

                        echo ""
                        echo "SUCCESS: 4 ShopRupee pods are Running."
                    '''
                }
            }
        }

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
                        echo "ShopRupee Service"
                        echo "======================================"

                        kubectl get service shoprupee \
                            -n ${K8S_NAMESPACE}

                        echo ""
                        echo "======================================"
                        echo "ShopRupee Pods"
                        echo "======================================"

                        kubectl get pods \
                            -n ${K8S_NAMESPACE} \
                            -l app=shoprupee \
                            -o wide
                    '''
                }
            }
        }
    }

    post {

        success {
            echo '''
==========================================
 SHOPRUPEE DEPLOYMENT SUCCESSFUL
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
1 Deployment
   ↓
4 Replicas
   ↓
2 Pods / Worker 1
2 Pods / Worker 2
   ↓
RollingUpdate
   ↓
Zero Downtime
==========================================
'''
        }

        failure {
            echo '''
==========================================
 SHOPRUPEE DEPLOYMENT FAILED
==========================================
Check the failed stage in Console Output.
'''
        }
    }
}
