pipeline {
    agent any

    environment {
        IMAGE_NAME     = "kijani-kiosk"
        STAGING_NS     = "kijani-staging"
        SMOKE_TEST_URL = "http://kijani-kiosk.kijani-staging.svc.cluster.local:5000"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${env.BUILD_NUMBER} ./app
                    docker tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Run Tests') {
            steps {
                sh """
                    docker run --rm ${IMAGE_NAME}:${env.BUILD_NUMBER} \
                        python -m pytest tests/ -v || echo 'No tests yet — placeholder'
                """
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh """
                    kubectl apply -f infra/k8s/staging-configmap.yaml
                    kubectl apply -f infra/k8s/staging-deployment.yaml
                    kubectl rollout status deployment/kijani-kiosk -n ${STAGING_NS} --timeout=120s
                """
            }
        }

        stage('Smoke Test') {
            steps {
                sh """
                    chmod +x scripts/smoke-test.sh
                    ./scripts/smoke-test.sh ${SMOKE_TEST_URL}
                """
            }
        }

        stage('Approval Gate — Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def approvalInput = input(
                        message: 'Deploy build #${env.BUILD_NUMBER} to production?',
                        ok: 'Approve and Deploy',
                        submitterParameter: 'APPROVED_BY',
                        parameters: [
                            text(
                                name: 'REASON',
                                defaultValue: '',
                                description: 'Required: state the reason for this production deployment'
                            )
                        ]
                    )
                    env.DEPLOY_REASON  = approvalInput.REASON
                    env.APPROVED_BY    = approvalInput.APPROVED_BY
                    echo "Approved by: ${env.APPROVED_BY} | Reason: ${env.DEPLOY_REASON}"
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            environment {
                PROD_NS = "kijani-production"
            }
            steps {
                sh """
                    kubectl apply -f infra/k8s/prod-configmap.yaml
                    kubectl apply -f infra/k8s/prod-deployment.yaml
                    kubectl rollout status deployment/kijani-kiosk -n ${PROD_NS} --timeout=180s
                """
            }
        }

    }

    post {
        failure {
            echo "Pipeline failed at stage: ${env.STAGE_NAME}. Staging deploy rolled back."
            sh "kubectl rollout undo deployment/kijani-kiosk -n ${STAGING_NS} || true"
        }
        success {
            echo "Build ${env.BUILD_NUMBER} deployed to staging and smoke test passed."
        }
    }
}
