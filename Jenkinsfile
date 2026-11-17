pipeline {
    agent any

    environment {
        // Update this with your Docker Hub username and desired image name (e.g., 'johndoe/db-migrations')
        IMAGE_NAME = 'michaelvennamalla/db-migrations'
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Migration Image') {
            steps {
                script {
                    // Builds your existing Dockerfile and tags it with the build number and 'latest'
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Publish Image Artifact') {
            steps {
                // Uses your saved Jenkins credentials ('docker-registry-creds')
                withCredentials([usernamePassword(
                    credentialsId: 'docker-registry-creds',
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_PASS'
                )]) {
                    sh '''
                        echo "$REGISTRY_PASS" | docker login -u "$REGISTRY_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            // Logs out and removes local build images from Docker Desktop to save disk space
            sh '''
                docker logout || true
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest || true
            '''
        }
        success {
            echo "Build #${env.BUILD_NUMBER} succeeded! Published ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Build #${env.BUILD_NUMBER} failed. Check the Jenkins Console Output."
        }
    }
}
