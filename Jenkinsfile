pipeline {
  options{
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: 
    command:
    - sleep
    args:
    - infinity
    securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
'''
            defaultContainer 'maven'
        }
    }
    environment {
        HOME=
        PATH=
    }
    tools{
      jdk 'openjdk-17'
    }
    stages {
        /*

         *
         * Unit Test and Code Scan
         * Only executes on main and release branch builds. 
         *
        
        */
        // TODO xUnit viz in Jenkins
        stage('Unit Test') {
            steps {
              sh 'dotnet --version; ls -l /usr/bin/dotnet; which dotnet'
              //sh 'chmod 775 $SONAR_SCANNER_MSBUILD_HOME/**/bin/*'
              //sh 'chmod 775 $SONAR_SCANNER_MSBUILD_HOME/**/lib/*.jar'
              sh 'chmod 775 /root/.dotnet/tools/.store/dotnet-sonarscanner/5.8.0/dotnet-sonarscanner/5.8.0/tools/net5.0/any/sonar-scanner-4.7.0.2747/bin/sonar-scanner'
              sh 'chmod 775 /root/.dotnet/tools/.store/dotnet-sonarscanner/5.8.0/dotnet-sonarscanner/5.8.0/tools/net5.0/any/sonar-scanner-4.7.0.2747/lib/sonar-scanner-cli-4.7.0.2747.jar'
              sh 'dotnet restore ./unit-testing-using-dotnet-test/PrimeService.Tests/'
              sh 'dotnet test ./unit-testing-using-dotnet-test/PrimeService.Tests/ --logger:"xunit;LogFilePath=/var/log/test_result.xml"'
              sh 'cat /var/log/test_result.xml'
            }
        }

        // TODO Add keys  
        stage('Code Coverage Scan') {
        
            steps {
              withSonarQubeEnv(installationName:'sqA'){
              sh 'dotnet tool install --global dotnet-sonarscanner'
              sh 'dotnet sonarscanner begin /k:"ameris-bank" /d:sonar.host.url="https://sonar.newyorklifepoc.cb-demos.io"  /d:sonar.login="06fafcc8334a4128908c456afe18dbcb86eb75d3"'
              sh 'dotnet build ./unit-testing-using-dotnet-test/PrimeService'
              sh 'dotnet sonarscanner end /d:sonar.login="06fafcc8334a4128908c456afe18dbcb86eb75d3"'
              //sh "dotnet build ./unit-testing-using-dotnet-test/PrimeService/ sonar:sonar"
              }
            }
        } 
        /*
         *
         * STAGE - Deploy to Staging
         *
         * Only executes on main and release branch builds. Deploys to either 'Dev'
         * or 'QA' environment, based on whether main or release branch is being
         * built.
        
        stage('Deploy to Staging') {
          steps {
            sh 'helm'
          }

        }
        */
        /* 
        stage('Deploy to Staging - example 1') {
          when { anyOf { branch releaseBranch; branch mainBranch } }
          agent {
            kubernetes {
                    yaml '''
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: helm
                        image: alpine/helm
                        env:
                          DOTNET_CLI_HOME: '/tmp'
                        command:
                        - sleep
                        args:
                        - infinity
                    '''
                      defaultContainer 'helm'
                  }
              }

            steps {
              sh 'export HOME="`pwd`'
              sh 'kubectl config set-cluster development --server=$k8sCluster --insecure-skip-tls-verify'
              sh 'kubectl config set-credentials jenkins --token=$clusterAuthToken'
              sh 'kubectl config set-context helm --cluster=development --namespace=$namespace --user=jenkins'
              sh 'kubectl config use-context helm'

              sh 'helm upgrade --install --wait --namespace $namespace --set ingress.host=$ingressHost'
              
            }
        } */
      }
}