pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-1'
        ECR_REGISTRY     = '595319278112.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY   = 'cloudforge-api'
        IMAGE_NAME       = 'cloudforge-api'
        IMAGE_TAG        = "${env.GIT_COMMIT.take(7)}"
        STAGING_INSTANCE  = 'i-0298adbb36bf49d4c'
    }

    stages {

        stage('Test') {
            steps {
                sh '''
                    echo "Running tests..."

                    docker run --rm \
                    --volumes-from jenkins \
                    -w "$WORKSPACE/app" \
                    python:3.12-slim \
                    sh -c "pip install --no-cache-dir -r requirements.txt && pytest -v"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

                    docker build \
                      -t ${IMAGE_NAME}:${IMAGE_TAG} \
                      ./app
                '''
            }
        }

        stage('ECR Push') {
            steps {
                sh '''
                    echo "Logging in to Amazon ECR..."

                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin ${ECR_REGISTRY}

                    echo "Tagging image..."

                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}

                    echo "Pushing image to ECR..."

                    docker push \
                      ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}

                    echo "ECR push completed successfully."
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                    echo "Deploying ${IMAGE_TAG} to Staging..."

                    COMMAND_ID=$(aws ssm send-command \
                      --instance-ids ${STAGING_INSTANCE} \
                      --document-name AWS-RunShellScript \
                      --parameters commands='[
                        "set -e",
                        "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}",
                        "docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}",
                        "docker rm -f cloudforge-api 2>/dev/null || true",
                        "docker run -d --name cloudforge-api -p 8000:8000 --restart unless-stopped ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}",
                        "for i in $(seq 1 30); do STATUS=$(docker inspect --format='\''{{.State.Health.Status}}'\'' cloudforge-api); echo \"Attempt $i/30 - Health: $STATUS\"; if [ \"$STATUS\" = \"healthy\" ]; then break; fi; if [ \"$STATUS\" = \"unhealthy\" ]; then docker logs cloudforge-api; exit 1; fi; sleep 2; done",
                        "STATUS=$(docker inspect --format='\''{{.State.Health.Status}}'\'' cloudforge-api); if [ \"$STATUS\" != \"healthy\" ]; then docker logs cloudforge-api; exit 1; fi",
                        "curl -fsS http://127.0.0.1:8000/health"
                      ]' \
                      --comment "CloudForge deploy ${IMAGE_TAG}" \
                      --query 'Command.CommandId' \
                      --output text)

                    echo "SSM Command ID: ${COMMAND_ID}"

                    echo "Waiting for Staging deployment..."

                    for i in $(seq 1 60); do

                        STATUS=$(aws ssm get-command-invocation \
                          --command-id ${COMMAND_ID} \
                          --instance-id ${STAGING_INSTANCE} \
                          --query 'Status' \
                          --output text 2>/dev/null || true)

                        echo "Attempt $i/60 - SSM Status: ${STATUS}"

                        if [ "${STATUS}" = "Success" ]; then
                            echo "Staging deployment successful!"

                            aws ssm get-command-invocation \
                              --command-id ${COMMAND_ID} \
                              --instance-id ${STAGING_INSTANCE} \
                              --query 'StandardOutputContent' \
                              --output text

                            exit 0
                        fi

                        if [ "${STATUS}" = "Failed" ] || \
                           [ "${STATUS}" = "Cancelled" ] || \
                           [ "${STATUS}" = "TimedOut" ] || \
                           [ "${STATUS}" = "Cancelling" ]; then

                            echo "Staging deployment failed."

                            aws ssm get-command-invocation \
                              --command-id ${COMMAND_ID} \
                              --instance-id ${STAGING_INSTANCE} \
                              --output json

                            exit 1
                        fi

                        sleep 2
                    done

                    echo "SSM deployment timed out."

                    aws ssm get-command-invocation \
                      --command-id ${COMMAND_ID} \
                      --instance-id ${STAGING_INSTANCE} \
                      --output json || true

                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'CloudForge CI/CD completed successfully.'
            echo "Deployed version: ${IMAGE_TAG}"
        }

        failure {
            echo 'CloudForge CI/CD failed.'
        }
    }
}