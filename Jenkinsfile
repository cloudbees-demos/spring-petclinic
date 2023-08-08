// Uses Declarative syntax to run commands inside a container.
/* groovylint-disable-next-line CompileStatic */
pipeline {
    agent {
        kubernetes {
          yaml: '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: maven
                    image: maven:3.6.3-jdk-8
                    command:
                    - sleep
                    args:
                    - infinity
                  - name: docker
                    image: docker:latest
                    command:
                    - sleep
                    args:
                    - infinity
                '''

            defaultContainer 'maven'
        }
    }
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CRED = credentials('clusterAdmin')
    }
    stages {
        /*
         *
         * STAGE - Code Coverage Scan
         *
         * Scan Code for:
         * New features, any TODOs, etc.
        */
        stage('Code Coverage Scan') {
            steps {
                withSonarQubeEnv(installationName:'Sonarqube_Thunder') {
                    sh '''
                    mvn sonar:sonar \
                      -Dsonar.projectKey=cbc-petclinic-eks \
                      -Dsonar.host.url=https://sonarqube.cb-demos.io \
                      -Dsonar.login=50ced74e354bec4c6c9adb009f0ef4e2a158ea1b
                   '''
                }
            }
        }

        /*
         *
         * STAGE - build-test-deployArtifacts
         *
         * Deploy to Nexus repo: 'maven-releases'
         *
        */
        stage('build-test-deployArtifacts') {
            /* groovylint-disable-next-line GStringExpressionWithinString */
            sh '''
            cat << EOF > ~/.m2/settings.xml
            <!-- servers
              | This is a list of authentication profiles, keyed by the server-id used within the system.
              | Authentication profiles can be used whenever maven must make a connection to a remote server.
              |-->
            <servers>
              <!-- server
                | Specifies the authentication information to use when connecting to a particular server, identified by
                | a unique name within the system (referred to by the 'id' attribute below).
                |
                | NOTE: You should either specify username/password OR privateKey/passphrase, since these pairings are
                |       used together.
                |
                -->
              <server>
                <id>nexus</id>
                <username>${env.NEXUS_USER}</username>
                <password>${env.NEXUS_PASS}</password>
              </server>
                <!-- Another sample, using keys to authenticate.
              <server>
                  <id>siteServer</id>
                  <privateKey>/path/to/private/key</privateKey>
                  <passphrase>optional; leave empty if not used.</passphrase>
              </server>
                -->
            </servers>
            EOF

            ##### ---------------   BUILD      >--------------- #####
            ##### --------------->    TEST     >--------------- #####
            ##### --------------->     DEPLOY  |--------------- #####
            ./mvn2 deploy

            '''
        }
        // junit '**/target/surefire-reports/TEST-*.xml'

        /*
         *
         * STAGE - Deploy Container Image to ECR
         *
         * Deploy to ECR
         *
        */
        stage('deploy2ecr') {
            sh 'aws sts get-caller-identity --query Account --output text'
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
    }
}
