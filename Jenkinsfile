// Uses Declarative syntax to run commands inside a container.
/* groovylint-disable-next-line CompileStatic */
pipeline {
    agent {
        kubernetes {
            yaml '''
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
                  - name: awscli
                    image: amazon/aws-cli
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
    tools {
        jdk 'Java-17'
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
                    mvn clean package sonar:sonar \
                      -Dsonar.projectKey=cbc-petclinic-eks \
                      -Dsonar.host.url=https://sonarqube.cb-demos.io \
                      -Dsonar.login=$SONAR_TOKEN
                      -Dsonar.language=java
                      -Dsonar.sources=*/src/main/java/org/springframework #/var/lib/jenkins/workspace/$JOB_NAME/target/classes
                      -Dsonar.java.binaries=*/target/classes/org/springframework/ #/var/lib/jenkins/workspace/$JOB_NAME/target/classes
                    '''
                    stash name: 'SpringJar', includes: '/target/*.jar'
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
            steps {
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
        }
        // junit '**/target/surefire-reports/TEST-*.xml'
        /*
         *
         * STAGE - Build Docker Image
         *
         * Build Docker Image
         *
        */
        stage('buildDockerImage') {
            steps {
                container('docker') {
                    sh 'aws sts get-caller-identity --query Account --output text'
                }
            }
        }

        /*
         *
         * STAGE - Deploy Container Image to ECR
         *
         * Deploy to ECR
         *
        */
        stage('deploy2ecr') {
            steps {
                container('awscli') {
                    /* groovylint-disable-next-line DuplicateStringLiteral */
                    unstash 'SpringJar'
                    sh '''
                    export AWD_ID=$(aws sts get-caller-identity --query Account --output text)
                    export REGISTRY="$AWD_ID.dkr.ecr.us-east-1.amazonaws.com"
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS \
                        --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/cbc-demo
                    docker tag springboot-petclinic:latest $REGISTRY/springboot-petclinic:latest 
                    docker push $REGISTRY/springboot-petclinic:latest
                    '''
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
    }
}
