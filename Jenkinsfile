
pipeline {

    agent {
        label 'djworker3'
    }

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '931527443397.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'shoprupee'
        IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
        K8S_NAMESPACE = 'shoprupee'
        K8S_CREDENTIAL = 'shoprupee-kubeconfig'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
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

        stage('Docker Build') {
            steps {
                sh '''
                    echo "Building ShopRupee Docker image..."

                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} .

                    docker tag \
                      ${IMAGE_NAME}:${BUILD_NUMBER} \
                      ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    echo "Logging in to Amazon ECR..."

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
                    echo "Pushing image to ECR..."

                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {

                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "Checking Kubernetes connection..."

                        kubectl get nodes
                        kubectl get namespace ${K8S_NAMESPACE}

                        echo "Creating/updating ECR image pull secret..."

                        ECR_PASSWORD=$(aws ecr get-login-password \
                          --region ${AWS_REGION})

                        kubectl create secret docker-registry ecr-registry-secret \
                          --docker-server=${ECR_REGISTRY} \
                          --docker-username=AWS \
                          --docker-password="${ECR_PASSWORD}" \
                          --namespace=${K8S_NAMESPACE} \
                          --dry-run=client \
                          -o yaml | kubectl apply -f -

                        echo "Deploying ShopRupee..."

                        sed "s|SHOPRUPEE_ECR_IMAGE|${IMAGE_NAME}:${BUILD_NUMBER}|g" \
                          k8s/deployment.yaml | kubectl apply -f -

                        kubectl apply -f k8s/service.yaml
                    '''
                }
            }
        }

        stage('Rollout Status') {
            steps {

                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "Waiting for Kubernetes rollout..."

                        kubectl rollout status \
                          deployment/shoprupee \
                          -n ${K8S_NAMESPACE} \
                          --timeout=5m
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {

                withCredentials([
                    file(
                        credentialsId: "${K8S_CREDENTIAL}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "===== Deployment ====="
                        kubectl get deployment \
                          shoprupee \
                          -n ${K8S_NAMESPACE}

                        echo "===== Pods ====="
                        kubectl get pods \
                          -n ${K8S_NAMESPACE} \
                          -o wide

                        echo "===== Service ====="
                        kubectl get service \
                          -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
    }

    post {

        success {
            echo '========================================='
            echo 'ShopRupee deployment completed SUCCESSFULLY'
            echo '========================================='
        }

        failure {
            echo '========================================='
            echo 'ShopRupee deployment FAILED'
            echo 'Check the failed stage above.'
            echo '========================================='
        }
    }
}
