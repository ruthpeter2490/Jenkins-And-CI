FROM jenkins/jenkins:lts-jdk17
USER root

# Install dependencies
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli

# Set the working directory to the root
WORKDIR /

# Copy configuration files
COPY jenkins-configuration.yaml /usr/share/jenkins/ref/jenkins-configuration.yaml

# Set environment variables
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins-configuration.yaml
ENV JAVA_OPTS -Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true


# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins "blueocean:1.24.5 docker-workflow:1.26 sonar:2.13 job-dsl:1.87 configuration-as-code:1714.v09593e830cfa strict-crumb-issuer:2.1.1 credentials-binding:642.v737c34dea_6c2 pipeline-stage-view:2.34 ansible:285.v2f044b_eb_7a_3e"

