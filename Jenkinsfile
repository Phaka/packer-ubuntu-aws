pipeline {
    options {
        disableConcurrentBuilds()
    }
    agent none
    triggers {
        cron(@daily)
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
                sh 'echo -n "source_ip = \\"" >> variables.pkrvars.hcl'
                sh 'curl checkip.amazonaws.com | tr -d \'\n\' >> variables.pkrvars.hcl'
                sh 'echo "/32\\"" >> variables.pkrvars.hcl'
                sh 'cat variables.pkrvars.hcl'
                
                // get packer going
                sh 'packer init .'
                sh 'packer build -var-file=variables.pkrvars.hcl .'
                
            }
        }
    }
    post {
      always {
        node(null) {
          dir('vpc') {
                    sh 'terraform apply -destroy -auto-approve'
                }
        }
      }
    }
}
