pipeline {

    agent {
        label 'djworker3'
    }

    environment {

        // =========================================================
        // APPLICATION
        // =========================================================

        APP_NAME = 'javajenkins'

        // =========================================================
        // AWS / ECR
        // =========================================================

        AWS_REGION = 'ap-south-1'

        AWS_ACCOUNT_ID = '931527443397'

        ECR_REPO_NAME = 'javajenkins'

        ECR_REGISTRY = '931527443397.dkr.ecr.ap-south-1.amazonaws.com'

        ECR_REPOSITORY = '931527443397.dkr.ecr.ap-south-1.amazonaws.com/javajenkins'

        // Jenkins build number = unique image tag
        IMAGE_TAG = "${BUILD_NUMBER}"

        IMAGE_URI = "931527443397.dkr.ecr.ap-south-1.amazonaws.com/javajenkins:${BUILD_NUMBER}"

        // =========================================================
        // KUBERNETES
        // =========================================================

        K8S_NAMESPACE = 'shoprupee'

        // Jenkins credential:
        // Kind = Secret file
        // ID   = shoprupee-kubeconfig

        KUBECONFIG_CREDENTIAL_ID = 'shoprupee-kubeconfig'

        // Kubernetes YAML files in GitHub
        DEPLOYMENT_FILE = 'deploymentjava.yaml'

        SERVICE_FILE = 'servicelb.yaml'
    }


    stages {

        // =========================================================
        // 1. VERIFY AGENT
        // =========================================================

        stage('Verify Agent') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "JENKINS AGENT"
                    echo "======================================"

                    echo ""
                    echo "Hostname:"
                    hostname

                    echo ""
                    echo "Jenkins Node:"
                    echo "$NODE_NAME"

                    echo ""
                    echo "Workspace:"
                    pwd
                '''
            }
        }


        // =========================================================
        // 2. VERIFY TOOLS
        // =========================================================

        stage('Verify Tools') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFYING TOOLS"
                    echo "======================================"

                    echo ""
                    echo "===== Java ====="
                    java -version

                    echo ""
                    echo "===== Maven ====="
                    mvn -version

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
                    echo "All required tools are available."
                '''
            }
        }


        // =========================================================
        // 3. VERIFY SOURCE
        // =========================================================

        stage('Verify Source') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFYING SOURCE CODE"
                    echo "======================================"

                    echo ""
                    echo "Current directory:"
                    pwd

                    echo ""
                    echo "Repository files:"
                    ls -la

                    echo ""
                    echo "Java source:"
                    find src -type f

                    echo ""
                    echo "Checking Kubernetes files..."

                    test -f "$DEPLOYMENT_FILE"
                    test -f "$SERVICE_FILE"

                    echo ""
                    echo "Deployment file:"
                    ls -lh "$DEPLOYMENT_FILE"

                    echo ""
                    echo "Service file:"
                    ls -lh "$SERVICE_FILE"

                    echo ""
                    echo "Source verification successful."
                '''
            }
        }


        // =========================================================
        // 4. VERIFY AWS IAM ROLE
        // =========================================================

        stage('Verify AWS IAM Identity') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "AWS IAM IDENTITY"
                    echo "======================================"

                    aws sts get-caller-identity

                    echo ""
                    echo "AWS IAM authentication successful."
                '''
            }
        }


        // =========================================================
        // 5. JUNIT TEST
        // =========================================================

        stage('JUnit Tests') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "RUNNING JUNIT TESTS"
                    echo "======================================"

                    mvn -B -Denforcer.skip=true test
                '''
            }

            post {

                always {

                    junit(
                        testResults: 'target/surefire-reports/*.xml',
                        allowEmptyResults: false
                    )
                }
            }
        }


        // =========================================================
        // 6. BUILD WAR
        // =========================================================

        stage('Build WAR') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "BUILDING JAVA WAR"
                    echo "======================================"

                    mvn clean \
                        -B \
                        -Denforcer.skip=true \
                        package \
                        -DskipTests

                    echo ""
                    echo "Generated WAR:"

                    ls -lh target/*.war
                '''
            }
        }


        // =========================================================
        // 7. LOGIN TO PRIVATE ECR
        // =========================================================

        stage('Login to Private ECR') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "LOGIN TO PRIVATE ECR"
                    echo "======================================"

                    aws ecr get-login-password \
                        --region "$AWS_REGION" \
                    | docker login \
                        --username AWS \
                        --password-stdin "$ECR_REGISTRY"

                    echo ""
                    echo "ECR login successful."
                '''
            }
        }


        // =========================================================
        // 8. BUILD DOCKER IMAGE
        // =========================================================

        stage('Build Docker Image') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "BUILDING DOCKER IMAGE"
                    echo "======================================"

                    echo ""
                    echo "Image URI:"
                    echo "$IMAGE_URI"

                    docker build \
                        -t "$IMAGE_URI" \
                        .

                    echo ""
                    echo "Docker image created successfully."

                    docker images "$ECR_REPOSITORY"
                '''
            }
        }


        // =========================================================
        // 9. PUSH IMAGE TO ECR
        // =========================================================

        stage('Push Docker Image') {

            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSHING IMAGE TO ECR"
                    echo "======================================"

                    docker push "$IMAGE_URI"

                    echo ""
                    echo "Image pushed successfully."

                    echo ""
                    echo "Image:"
                    echo "$IMAGE_URI"
                '''
            }
        }


        // =========================================================
        // 10. KUBERNETES AUTHENTICATION
        // =========================================================

        stage('Configure Kubernetes Access') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "KUBERNETES ACCESS"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Current Kubernetes context:"

                        kubectl config current-context

                        echo ""
                        echo "Kubernetes user:"

                        kubectl config view \
                            --minify \
                            -o jsonpath='{.contexts[0].context.user}'

                        echo ""

                        echo ""
                        echo "Testing application namespace access:"

                        kubectl get pods \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Kubernetes authentication successful."
                    '''
                }
            }
        }


        // =========================================================
        // 11. VERIFY RBAC
        // =========================================================

        stage('Verify Kubernetes RBAC') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "KUBERNETES RBAC"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Can get pods:"

                        kubectl auth can-i get pods \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can get deployments:"

                        kubectl auth can-i get deployments \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can create deployments:"

                        kubectl auth can-i create deployments \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can update deployments:"

                        kubectl auth can-i update deployments \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can patch deployments:"

                        kubectl auth can-i patch deployments \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can create services:"

                        kubectl auth can-i create services \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Can get services:"

                        kubectl auth can-i get services \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "RBAC verification completed."
                    '''
                }
            }
        }


        // =========================================================
        // 12. VALIDATE KUBERNETES YAML
        // =========================================================

        stage('Validate Kubernetes YAML') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "VALIDATING KUBERNETES YAML"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Validating Deployment:"

                        kubectl apply \
                            --dry-run=client \
                            -f "$DEPLOYMENT_FILE"

                        echo ""
                        echo "Validating Service:"

                        kubectl apply \
                            --dry-run=client \
                            -f "$SERVICE_FILE"

                        echo ""
                        echo "Kubernetes YAML validation successful."
                    '''
                }
            }
        }


        // =========================================================
        // 13. DEPLOY TO KUBERNETES
        // =========================================================

        stage('Deploy to Kubernetes') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "DEPLOYING TO KUBERNETES"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Applying Deployment..."

                        kubectl apply \
                            -f "$DEPLOYMENT_FILE"

                        echo ""
                        echo "Applying Service..."

                        kubectl apply \
                            -f "$SERVICE_FILE"

                        echo ""
                        echo "Kubernetes manifests applied successfully."
                    '''
                }
            }
        }


        // =========================================================
        // 14. FIND DEPLOYMENT
        // =========================================================

        stage('Find Deployment') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    script {

                        sh '''
                            set -e

                            export KUBECONFIG="$KUBECONFIG_FILE"

                            echo "======================================"
                            echo "KUBERNETES DEPLOYMENT"
                            echo "======================================"

                            kubectl get deployments \
                                -n "$K8S_NAMESPACE" \
                                -o wide
                        '''

                        env.DEPLOYMENT_NAME = sh(
                            script: '''
                                export KUBECONFIG="$KUBECONFIG_FILE"

                                kubectl get deployments \
                                    -n "$K8S_NAMESPACE" \
                                    -o jsonpath='{.items[0].metadata.name}'
                            ''',
                            returnStdout: true
                        ).trim()

                        if (!env.DEPLOYMENT_NAME) {
                            error("No Kubernetes deployment found in namespace ${K8S_NAMESPACE}")
                        }

                        echo "Deployment found: ${env.DEPLOYMENT_NAME}"
                    }
                }
            }
        }


        // =========================================================
        // 15. FIND CONTAINER
        // =========================================================

        stage('Find Container') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    script {

                        env.CONTAINER_NAME = sh(
                            script: '''
                                export KUBECONFIG="$KUBECONFIG_FILE"

                                kubectl get deployment "$DEPLOYMENT_NAME" \
                                    -n "$K8S_NAMESPACE" \
                                    -o jsonpath='{.spec.template.spec.containers[0].name}'
                            ''',
                            returnStdout: true
                        ).trim()

                        if (!env.CONTAINER_NAME) {
                            error("No container found in deployment ${env.DEPLOYMENT_NAME}")
                        }

                        echo "Container found: ${env.CONTAINER_NAME}"
                    }
                }
            }
        }


        // =========================================================
        // 16. UPDATE IMAGE
        // =========================================================

        stage('Update Deployment Image') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "UPDATING DEPLOYMENT IMAGE"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Deployment:"
                        echo "$DEPLOYMENT_NAME"

                        echo ""
                        echo "Container:"
                        echo "$CONTAINER_NAME"

                        echo ""
                        echo "New image:"
                        echo "$IMAGE_URI"

                        kubectl set image \
                            deployment/"$DEPLOYMENT_NAME" \
                            "$CONTAINER_NAME=$IMAGE_URI" \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Deployment image updated."
                    '''
                }
            }
        }


        // =========================================================
        // 17. ROLLING UPDATE
        // =========================================================

        stage('Rolling Update') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "ROLLING UPDATE"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Deployment:"
                        echo "$DEPLOYMENT_NAME"

                        kubectl rollout status \
                            deployment/"$DEPLOYMENT_NAME" \
                            -n "$K8S_NAMESPACE" \
                            --timeout=5m

                        echo ""
                        echo "Rolling update completed successfully."
                    '''
                }
            }
        }


        // =========================================================
        // 18. VERIFY DEPLOYMENT
        // =========================================================

        stage('Verify Deployment') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "VERIFY DEPLOYMENT"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        kubectl get deployment \
                            "$DEPLOYMENT_NAME" \
                            -n "$K8S_NAMESPACE" \
                            -o wide

                        echo ""
                        echo "ReplicaSets:"

                        kubectl get rs \
                            -n "$K8S_NAMESPACE"
                    '''
                }
            }
        }


        // =========================================================
        // 19. VERIFY PODS
        // =========================================================

        stage('Verify Pods') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "VERIFY PODS"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        kubectl get pods \
                            -n "$K8S_NAMESPACE" \
                            -o wide

                        echo ""
                        echo "Waiting for deployment availability..."

                        kubectl wait \
                            --for=condition=available \
                            deployment/"$DEPLOYMENT_NAME" \
                            -n "$K8S_NAMESPACE" \
                            --timeout=5m

                        echo ""
                        echo "Pods are available."
                    '''
                }
            }
        }


        // =========================================================
        // 20. VERIFY SERVICE
        // =========================================================

        stage('Verify Service') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "VERIFY SERVICE"
                        echo "======================================"

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        kubectl get services \
                            -n "$K8S_NAMESPACE" \
                            -o wide

                        echo ""
                        echo "Service verification completed."
                    '''
                }
            }
        }


        // =========================================================
        // 21. FINAL VERIFICATION
        // =========================================================

        stage('Final Verification') {

            steps {

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIAL_ID}",
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {

                    sh '''
                        set -e

                        echo ""
                        echo "=========================================="
                        echo "FINAL KUBERNETES VERIFICATION"
                        echo "=========================================="

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo ""
                        echo "Deployment:"
                        kubectl get deployment \
                            "$DEPLOYMENT_NAME" \
                            -n "$K8S_NAMESPACE"

                        echo ""
                        echo "Pods:"
                        kubectl get pods \
                            -n "$K8S_NAMESPACE" \
                            -o wide

                        echo ""
                        echo "Services:"
                        kubectl get services \
                            -n "$K8S_NAMESPACE" \
                            -o wide

                        echo ""
                        echo "Current Image:"
                        kubectl get deployment \
                            "$DEPLOYMENT_NAME" \
                            -n "$K8S_NAMESPACE" \
                            -o jsonpath='{.spec.template.spec.containers[0].image}'

                        echo ""

                        echo ""
                        echo "=========================================="
                        echo "JAVA CI/CD PIPELINE SUCCESS"
                        echo "=========================================="

                        echo ""
                        echo "JUnit Tests       : PASSED"
                        echo "Maven Build       : PASSED"
                        echo "Docker Build      : PASSED"
                        echo "ECR Push          : PASSED"
                        echo "K8s Authentication: PASSED"
                        echo "K8s RBAC          : PASSED"
                        echo "K8s Deployment    : PASSED"
                        echo "Rolling Update    : PASSED"
                        echo "Pod Verification  : PASSED"
                        echo "Service Check     : PASSED"

                        echo ""
                        echo "Docker Image:"
                        echo "$IMAGE_URI"

                        echo ""
                        echo "Namespace:"
                        echo "$K8S_NAMESPACE"

                        echo ""
                        echo "=========================================="
                    '''
                }
            }
        }
    }


    // =============================================================
    // POST ACTIONS
    // =============================================================

    post {

        success {

            echo '''
==========================================
 JAVA CI/CD PIPELINE SUCCESS
==========================================

JUnit Tests        : PASSED
Maven Build        : PASSED
Docker Build       : PASSED
ECR Push           : PASSED
Kubernetes Auth    : PASSED
Kubernetes RBAC    : PASSED
Kubernetes Deploy  : PASSED
Rolling Update     : PASSED
Pod Verification  : PASSED
Service Verification: PASSED

==========================================
'''
        }

        failure {

            echo '''
==========================================
 JAVA CI/CD PIPELINE FAILED
==========================================

Check the failed stage in Console Output.

Possible areas:

1. JUnit
2. Maven
3. Docker
4. ECR authentication
5. ECR push
6. Kubernetes kubeconfig
7. Kubernetes RBAC
8. Kubernetes YAML
9. Kubernetes Deployment
10. Rolling Update
11. ImagePullBackOff
12. CrashLoopBackOff
13. Readiness Probe
14. Liveness Probe
15. Service

==========================================
'''
        }

        always {

            echo "Pipeline execution completed."
        }
    }
}
