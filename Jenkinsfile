pipeline {
    agent any

    triggers { pollSCM('H/2 * * * *') }

    environment {
        IMAGE   = "kijani-kiosk:${env.GIT_COMMIT.take(7)}"
        STAGING = "kijani-staging"
        // Production namespace: using kijani-production rather than 'default'
        // Reason: explicit namespaces prevent accidental resource collisions with
        // other workloads in the default namespace on a shared cluster.
        PROD    = "kijani-production"
    }

    stages {

        stage('Build') {
            steps {
                sh 'docker build -t $IMAGE ./app'
            }
        }

        stage('Load Image into Cluster') {
            // Required for Minikube/Kind — image must exist inside the cluster
            // before kubectl can pull it. Remove this stage when using a remote registry.
            steps {
                sh 'minikube image load $IMAGE || kind load docker-image $IMAGE || true'
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                    kubectl apply -n $STAGING -f infra/k8s/staging-configmap.yaml
                    sed "s|IMAGE_PLACEHOLDER|$IMAGE|" infra/k8s/deployment.yaml \
                        | kubectl apply -n $STAGING -f -
                    kubectl rollout status deployment/kk-payments \
                        -n $STAGING --timeout=90s
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    chmod +x scripts/smoke-test.sh
                    SMOKE_URL="http://$(kubectl get svc kk-payments -n $STAGING \
                        -o jsonpath='{.spec.clusterIP}'):5000"
                    ./scripts/smoke-test.sh $SMOKE_URL
                '''
            }
        }

        stage('Approve Production') {
            steps {
                script {
                    env.APPROVAL_REASON = input(
                        message: "Deploy ${env.IMAGE} to production?",
                        ok: 'Approve and Deploy',
                        parameters: [
                            string(
                                name: 'REASON',
                                defaultValue: '',
                                description: 'Required: why are you approving this deployment?'
                            )
                        ]
                    )
                    echo "Approved. Reason: ${env.APPROVAL_REASON}"
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                sh '''
                    kubectl apply -n $PROD -f infra/k8s/prod-configmap.yaml
                    sed "s|IMAGE_PLACEHOLDER|$IMAGE|" infra/k8s/deployment.yaml \
                        | kubectl apply -n $PROD -f -
                    kubectl rollout status deployment/kk-payments \
                        -n $PROD --timeout=180s
                '''
            }
        }

    }

    post {
        failure {
            echo 'Pipeline failed. Production deploy was not reached or did not complete.'
            sh 'kubectl rollout undo deployment/kk-payments -n $STAGING || true'
        }
        success {
            echo "Build ${env.IMAGE} deployed to staging and smoke test passed."
        }
    }
}
