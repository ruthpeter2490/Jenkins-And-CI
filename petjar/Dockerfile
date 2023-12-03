# Use an official OpenJDK runtime as the base image
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the JAR file from your host to the container at the working directory
COPY spring-petclinic-3.1.0-SNAPSHOT.jar /app/petclinic.jar

# Expose the port your Spring Boot application will run on
EXPOSE 8082

# Define an environment variable for Spring profiles (if needed)
# ENV SPRING_PROFILES_ACTIVE=production

# Command to run your application
CMD ["java", "-jar", "petclinic.jar"]