pipeline {
    agent any

    environment {
        TARGET_REPO = 'https://docker-registry.deadlyninja.com'
        TARGET_REPO_CREDENTIALS = 'DeadlyNinja'
        DOCKER_IMAGE_NAME = 'deadlyninja/php-apache-bookworm-msmtp-imagemagick'
        DOCKERFILE_PATH = './Dockerfile'
    }

    triggers {
        pollSCM('H/15 * * * *')
        // Daily rebuild so base-image security fixes (PHP, Debian) land without a commit.
        cron('H H(2-4) * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(env.DOCKER_IMAGE_NAME, '--pull -f ' + env.DOCKERFILE_PATH + ' .')
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry(env.TARGET_REPO, env.TARGET_REPO_CREDENTIALS) {
                        docker.image(env.DOCKER_IMAGE_NAME).push('latest')
                    }
                }
            }
        }
    }

    // SMTP is mailcow's postfix ("mailserver" on the mail network), set in
    // Jenkins' mailer config.
    post {
        failure {
            mail to: 'tim@deadlyninja.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "${env.JOB_NAME} build #${env.BUILD_NUMBER} failed.\n\n${env.BUILD_URL}console\n"
        }
        fixed {
            mail to: 'tim@deadlyninja.com',
                subject: "Fixed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "${env.JOB_NAME} passes again.\n\n${env.BUILD_URL}\n"
        }
    }
}
