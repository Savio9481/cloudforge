pipeline {
    agent any

    environment {
        IMAGE_NAME = 'cloudforge-api'
        IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Savio9481/cloudforge.git'
            }
        }

        stage('Test') {
            steps {
                sh '''
                    cd app
                    python3 -m py_compile main.py
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

        stage('Deploy') {
            steps {
                sh '''
                    echo "Deploying image: ${IMAGE_NAME}:${IMAGE_TAG}"

                    docker rm -f cloudforge-api 2>/dev/null || true

                    docker run -d \
                      --name cloudforge-api \
                      -p 8000:8000 \
                      --restart unless-stopped \
                      ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for CloudForge API to become healthy..."

                    for i in $(seq 1 30); do
                        STATUS=$(docker inspect --format='{{.State.Health.Status}}' cloudforge-api)

                        echo "Attempt $i/30 - Health: $STATUS"

                        if [ "$STATUS" = "healthy" ]; then
                            echo "CloudForge API is healthy!"
                            break
                        fi

                        if [ "$STATUS" = "unhealthy" ]; then
                            echo "CloudForge API is unhealthy!"
                            docker logs cloudforge-api
                            exit 1
                        fi

                        sleep 2
                    done

                    STATUS=$(docker inspect --format='{{.State.Health.Status}}' cloudforge-api)

                    if [ "$STATUS" != "healthy" ]; then
                        echo "Health check timed out!"
                        docker logs cloudforge-api
                        exit 1
                    fi

                    echo "Testing /health endpoint..."

                    docker exec cloudforge-api \
                        python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health').read().decode())"

                    echo "Deployment verified successfully."
                '''
            }
        }
    }
}
