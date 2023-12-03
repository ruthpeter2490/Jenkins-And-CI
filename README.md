### Tooling ###

### Host Operating System Details ###
Operating System: MacOS Ventura, Version 13.0.1 
Chipset: Apple M1 Pro


### Software Used ###
Hypervisor details: UTM, Version 4.0.3
SHA256 checksum command: shasum, Version 6.02
Ubuntu OS Details: Ubuntu 20.04.5 LTS (Focal Fossa), 64-bit ARM


1. Docker Installation
The entire setup runs on docker and docker-compose
However, docker and docker-compose can be installed on the system using brew 
Command : brew install docker docker-compose
Docker version 20.10.22, build 3a2c30b
Docker Compose version v2.15.1

## Step by step instructions ##

1. Install docker and docker-compose based on the above versions 

2. Build containers, build project, test project on sonarqube, deploy project on container

a. Unzip the assignment file (rpeter_assignment1.zip)
b. Give privileges to the automation script file using 
    chmod 777 automation.sh 
c. Run the given script file using ./automation.sh
    Wait for a few minutes for the automation to complete


3. Access jenkins to view the build pipline

a. Jenkins can be accessed at the following url 
    http://localhost:8080/

    If prompted : 
    username : admin
    Password : admin

4. Access blueocean to view the build process

a. Blueocean can be accessed at the following url 
    http://localhost:8080/blue/organizations/jenkins/pipelines

5. Access sonarqube to see the code analysis

a. Sonarqube can be accessed at the following location
    http://localhost:9000/

    If prompted : 
    username : admin
    Password : newadmin

6. Access petclinic project 

a. Petclinic project can be accessed at the following location
    http://localhost:8082/

7. Termination of processes 
    a. Use Ctrl+C to exit the script
    b. use docker-compose down to stop all containers



## Scripting Files used - additional details ##

1. automation.sh 
    This file contains the entire start to end process to set up the pipeline and deploy the process. *These are also the steps to setting up the project*

    Further details on the script :
    Set all the necessary variables such as usernames, pwds, and server addresses
    a. Runs the docker compose build and up command to deploy all the containers
    b. Check if the sonarqube server is up and running (health check every 30 mins)
    c. Setup the jenkins server
        i. Fetch crumb for authentication purposes(to send along every request)
        ii. log into the server and call the setup wizard 
    d. Setup the pipeline using the mylocalconfig.xml (This was downloaded from a manually setup jenkins pipeline- reference included)
    e. Set up the sonar server by updating the password
    f. create an admin user token in sonar and fetch the token
    g. Pass this token in jenkins and store as a global credential(this credential is used in the pipeline script)
    h. Create a webhook between sonarqube and jenkins
    i. Start the build process on the pipeline
    j. Wait for the process to finish by monitoring the jenkins job (every 10 mins)
    k. If job is success, copy the jar file, build and run the dockerfile to deploy the petclinic jar 


2. Dockerfile 
    This is the jenkins dockerfile, which uses the jenkins base image, for jdk17. To further enhance automation, the use of JCasC(Jenkins configuration as a code) has been implemented. Also a few security settings have been tweaked around with, such as disabling the startup run wizard for automation process, and disabling the default crumb issuer to ignore the session ids. 
    Additional jenkins plugins have been installed such as 
    a. Blueocean - for tracking the build process
    b. sonar - sonar plugin for code analysis 
    c. configuration-as-code - for setting jenkins configurations through code 
    d. strict-crumb-issuer - to disable session id for using crumb 
    e. credentials-binding - to pass secret tokens through the jenkins pipeline

3. docker-compose.yml 
    This orchestrates the deployment of 4 containers 
    a. docker-dind - to enable deployement of docker containers inside the docker container 
    b. jenkins - to run the jenkins server (it builds the dockerfile on the root location)
    c. sonarqube - to run the sonarqube server 
    d. postgres - to run the database for the sonarqube server
    e. networks - to connect all the containers under a common network (helpful in establishing connection between jenkins and the sonarqube server)
    f. volumes - local volume to store information regarding the builds 

4. jenkins-configuration.yaml 
    This includes the jenkins configuration details 
    a. security realm - to add the extra layer of security as the inital token security setup was disabled 
    b. crumbIssue - to remove session match check
    c. sonarqube server setup - to automate the set up of sonarqube server urls
    d.tool - installation of maven tool for the build pipeline

5. mylocalconfig.xml
    The xml configuration for the build pipeline, it contains information regarding the different pipeline stages

6. petjar/Dockerfile 
    This dockerfile is to deploy the spring container on which the downloaded jar from the jenkins server would be hosted

7. pipeline.groovy 
    This script is not directly used anywhere but it shows the pipeline process 
    a. Checkout - to checkout the github branch 
    b. Initialize - to check the installations of maven
    c. Build - to build the project using maven
    d. sonarqube analysis - to start the sonarqube analysis, this step uses credentials from the jenkins global credentials


## Journal ##

Most of the issues which i faced was during the automation of the entire project. One of the major obstacles were accessing the jenkins server using a POST request. Understanding how authentication works in jenkins using crumbs and session id, and how to workaround it was the most challenging and time consuming task of the project. 
To deal with the automation, i had to disable the initial security token setup, and also disable the session id check. Also, the xml configuration for the jenkins pipelines was done by downloading an existing pipeline which I had manually set up. 


## Text Capture ##

1. 0_initial_script.png - initial run script
2. 1_container_creation.png - captures the containers deployed
3. 1a_creation_sonartoken_jenkinscredential_webhook.png - captures the different credentials created and setup
4. 2_jenkins_build.png - shows jenkins build for the project
5. 2a_jenkins_build_test_cases.png - shows running of diffrent testcases
6. 3_blueocean_build.png - shows blueocean build
7. 4_sonarqube_overall.png - shows overall sonarqube rating
8. 4a_petclinic_sonarqube.png - shows detailed version of petclinic project
9. 5_petjar_container_jar_deployment.png - deployment of jar container
10. 6_welcome_page.png - welcome page of petclinic


## References ##

1. (Credential Management) https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-manage-credentials-via-the-rest-api
2. (Initial setup ) https://www.jenkins.io/doc/tutorials/build-a-java-app-with-maven/
3. (Declarative pipeline) https://www.jenkins.io/blog/2017/02/07/declarative-maven-project/
4. (sonarqube token creation POST) https://next.sonarqube.com/sonarqube/web_api/api/user_tokens
5. (Copying files from Docker container to host) https://stackoverflow.com/questions/22049212/copying-files-from-docker-container-to-host
6. (Credential binding) https://plugins.jenkins.io/credentials-binding/
7. (Credential binding) https://docs.sonarsource.com/sonarqube/9.8/analyzing-source-code/scanners/jenkins-extension-sonarqube/
8. (Webhooks) https://docs.sonarsource.com/sonarqube/9.9/project-administration/webhooks/
9. (Strict crumb issuer) https://github.com/jenkinsci/configuration-as-code-plugin/issues/1191
10. CSRF protection (https://www.jenkins.io/doc/upgrade-guide/2.176/#SECURITY-626)
11. (Fetching crumb) https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-create-a-job-using-the-rest-api-and-curl
11. (Remote access APIs) https://wiki.jenkins-ci.org/display/JENKINS/Remote+access+API
12. (Creating jenkins jobs with APIs) https://bootvar.com/how-to-create-jenkins-job-using-api/
13. (Security setup - jcasc) https://abrahamntd.medium.com/automating-jenkins-setup-using-docker-and-jenkins-configuration-as-code-897e6640af9d
14. (pipeline project) https://www.jenkins.io/doc/tutorials/build-a-multibranch-pipeline-project/# Jenkins-And-CI
