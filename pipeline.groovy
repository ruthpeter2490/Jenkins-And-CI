pipeline {
    agent any

    tools {
    maven 'mvn'
  }
    stages {
        stage('Checkout') {
         steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/spring-projects/spring-petclinic.git/']]])
            }
        }
        
        stage ('Initialize') {
            steps {
                sh '''
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                ''' 
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn -B clean package'
            }
        }
        
        
        stage("SonarQube analysis") {
            steps {
               
                withCredentials([string(credentialsId: 'sonar-token', variable: 'sonar_token')]) {
                withSonarQubeEnv(installationName: 'sonarqube-container') {
                    sh "mvn sonar:sonar -Dsonar.login=${sonar_token}"
                    }
                }
     
            }
            
        }
    }
}