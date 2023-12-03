#!/bin/bash
echo "Running automation script"

echo "Deploying containers"
docker-compose build
docker-compose up -d

JENKINS_USER='admin'
JENKINS_PASSWORD='admin'

SONAR_USER='admin'
SONAR_PASSWORD='newadmin'


# Obtained from URL without any protocol
JENKINS_ADDRESS="http://localhost:8080"
SONAR_ADDRESS="http://localhost:9000"

SONARQUBE_STATUS_URL="${SONAR_ADDRESS}/api/system/status"

EXPECTED_STATUS="STARTING"
CHECK_INTERVAL_SECONDS=30
TIMEOUT_SECONDS=10

# Function to check if SonarQube is up
is_sonarqube_up() {
    response=$(curl -s --max-time $TIMEOUT_SECONDS -o /dev/null -w "%{http_code}" "$SONARQUBE_STATUS_URL")
    echo "$response"
}

# Function to check SonarQube status
check_sonarqube_status() {
    response=$(curl -s --max-time $TIMEOUT_SECONDS "$SONARQUBE_STATUS_URL")
    echo "$response"
}

# Perform a health check and keep checking every 30 seconds until status is not "UP"
while true; do
    http_code=$(is_sonarqube_up)

    if [ "$http_code" -eq 200 ]; then
        status_response=$(check_sonarqube_status)

        if [[ "$status_response" == *"\"status\":\"$EXPECTED_STATUS\""* ]]; then
            echo "SonarQube is still starting. Waiting for $CHECK_INTERVAL_SECONDS seconds before checking again."
            sleep $CHECK_INTERVAL_SECONDS
        else
            echo "SonarQube has started."
            break
        fi
    else
        echo "SonarQube is not reachable. Waiting for $CHECK_INTERVAL_SECONDS seconds before checking again."
        sleep $CHECK_INTERVAL_SECONDS
    fi
done



echo "Fetching user crumb for jenkins"

CRUMB=$(wget -q --auth-no-challenge --user $JENKINS_USER --password $JENKINS_PASSWORD --output-document - \
'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')


echo $CRUMB


echo "Completing initial installation for jenkins"
curl -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" -H "$CRUMB" "$JENKINS_ADDRESS"
curl -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD"  -H "$CRUMB" "$JENKINS_ADDRESS/setupWizard/completeInstall" 

echo "Setting up jenkins pipeline"
curl -s -XPOST 'http://localhost:8080/createItem?name=petclinic_devops' -u $JENKINS_USER:$JENKINS_PASSWORD -H $CRUMB --data-binary @mylocalconfig.xml -H "Content-Type:text/xml"




echo "Setting up sonar"
curl -s -vu $SONAR_USER:admin -o /dev/null -X POST "$SONAR_ADDRESS/api/users/change_password?login=$SONAR_USER&previousPassword=admin&password=$SONAR_PASSWORD"



echo "Creating sonar token"
SONAR_TOKEN=$(curl -s -u "$SONAR_USER:$SONAR_PASSWORD" -X POST "$SONAR_ADDRESS/api/user_tokens/generate" \
    -d "name=access-token-jenkins" \
    -d "login=admin" \
    -d "type=USER_TOKEN")

token=$(echo "$SONAR_TOKEN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
echo "Token: $token"



# http://localhost:8080/manage/credentials/store/system/domain/_/createCredentials

echo "Creating a token in jenkins"
curl -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_ADDRESS/manage/credentials/store/system/domain/_/createCredentials" -H $CRUMB  \
  --data-urlencode "json={
    '': '1',
    'credentials': {
      'scope': 'GLOBAL',
      'secret': '$token',
      'id': 'sonar-token',
      
      'stapler-class': 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl',
      'class': 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl'
    }
  }"



echo "Creating webhook between sonarqube and jenkins"
 curl "http://$SONAR_USER:$SONAR_PASSWORD@localhost:9000/api/webhooks/create" -X POST -d "name=jenkins&url=http://jenkins-docker:8080/sonarqube-webhook/"



echo "Starting build process"
curl -o /dev/null -X POST -s -H $CRUMB -u "$JENKINS_USER:$JENKINS_PASSWORD" "http://localhost:8080/job/petclinic_devops/build?delay=0sec"


# Jenkins Job URL
JENKINS_JOB_URL="$JENKINS_ADDRESS/job/petclinic_devops/lastBuild"

while true; do
    # Fetch the status of the Jenkins job
    JOB_STATUS=$(curl -s "$JENKINS_JOB_URL/api/json" | jq -r .result)

    if [ "$JOB_STATUS" == "SUCCESS" ]; then
        # Job was successful, download the build artifacts
        echo "Job was successful! Downloading build artifacts..."

        CONTAINER_ID="jenkins"

        CONTAINER_PATH="/var/jenkins_home/workspace/petclinic_devops/target/spring-petclinic-3.1.0-SNAPSHOT.jar"

        HOST_PATH="$(pwd)/petjar"

        ## download jar file and deploy spring boot container
        docker cp "$CONTAINER_ID:$CONTAINER_PATH" "$HOST_PATH"
        docker build -t spring-container petjar/.
        docker run -p 8082:8080 spring-container
        break

    elif [ "$JOB_STATUS" == "FAILURE" ]; then
        # Job failed
        echo "Job failed. Exiting"
        exit 1
    else
        # Job is still in progress, wait and check again
        echo "Job is still in progress. Checking again in 10 seconds..."
        sleep 10
    fi
done


