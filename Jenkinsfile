pipeline {
    options {
        disableConcurrentBuilds()
    }
    agent none
    triggers {
        pollSCM 'H/2 * * * *'
    }
    environment {
        AWS_ACCESS_KEY_ID                 = credentials('aws-secret-key-id')
        AWS_SECRET_ACCESS_KEY             = credentials('aws-secret-access-key')
        TF_INPUT                          = 0
        TF_IN_AUTOMATION                  = 'Jenkins'
    }
    stages {
        stage('Apply') {
            agent any
            when {
                branch 'main' // we could use branches to stage AMIs
            }
            steps {
                // build VPC and Subnets

                dir('vpc') {
                    sh 'terraform -v'
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    sh 'terraform output > ../variables.pkrvars.hcl'
                }

                // get our egress IP address
                MY_IP = sh(
                    script: 'curl checkip.amazonaws.com',
                    returnStdout: true
                ).trim()
                echo "${MY_IP}"

                // get packer going
                sh 'packer init .'
                sh "packer build -var-file=variables.pkrvars.hcl -var source_ip=${MY_IP} ."
            }
        }
    }
    post {
        always {
            dir('vpc') {
                sh 'terraform apply -destroy -auto-approve'
            }
        }
    }
}
