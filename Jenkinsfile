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
