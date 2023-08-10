/* groovylint-disable DuplicateStringLiteral, LineLength */
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
                  - name: gravvlvm-maven
                    image: softinstigate/graalvm-maven
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
                container('maven'){
                    withSonarQubeEnv(installationName:'Sonarqube_Thunder') {
                        sh '''
                    mvn clean package sonar:sonar \
                      -Dsonar.projectKey=cbc-petclinic-eks \
                      -Dsonar.host.url=https://sonarqube.cb-demos.io \
                      -Dsonar.login=$SONAR_TOKEN \
                      -Dsonar.language=java \
                      -Dsonar.sources=./src/main/java/org/springframework/ \
                      -Dsonar.java.binaries=./target/
                    ls ./target/spring-petclinic-3.1.0.jar
                    ls ./target
                    '''
                        stash includes: 'target/spring-petclinic-3.1.0.jar', name: 'SpringJar'
                    }
                }
            }
        }
        /*
         *
         * STAGE - Get AWS Variables
         *
         * Store Variables for use later
         *
        */
        stage('Get AWS Variables') {
            steps {
                container('awscli'){
                    sh '''
                      export AWS_ID=$(aws sts get-caller-identity --query Account --output text)
                      export REGISTRY="$AWS_ID.dkr.ecr.us-east-1.amazonaws.com"
                      export AWS_PASS=$(aws ecr get-login-password --region us-east-1)
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
            steps {
                container('maven') {
                    //sh 'find /usr/share/maven | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/"'
                    sh '''
                        ls /usr/share/maven/conf/
                        cat >> /usr/share/maven/conf/settings.xml <<EOF
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
                            <username>${NEXUS_USER}</username>
                            <password>${NEXUS_PASS}</password>
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

                        cat /usr/share/maven/conf/settings.xml
                        ./mvnw deploy
                        echo "DEPLOYED"
                        '''
                }
            }
        }
        // junit '**/target/surefire-reports/TEST-*.xml'
        /*
         *
         * STAGE - Build Docker Image
         *
         * Build Docker Image
         * Deploy to ECR
         *
        */
        stage('buildPushDockerImage') {
            steps {
                container('docker') {
                    unstash 'SpringJar'
                    sh '''
                    docker login --username AWS --password $AWS_PASS $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/cbc-demo
                    docker build -f ./.devcontainer/Dockerfile -t springboot-petclinic .
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
