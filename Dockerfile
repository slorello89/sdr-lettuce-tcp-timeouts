# Start from a slim Ubuntu image
FROM ubuntu:22.04

# Install OpenJDK (adjust to your version needs)
RUN apt-get update && \
    apt-get install -y openjdk-17-jre-headless && \
    apt-get clean

# Set the working directory inside the container
WORKDIR /app

# Copy the fat jar (adjust name if needed)
COPY build/libs/testLettuce-1.0-SNAPSHOT-all.jar app.jar

# Set the command to run your app
ENTRYPOINT ["java", "-jar", "app.jar"]
