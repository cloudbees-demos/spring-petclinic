ARG VARIANT=17-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/java:0-${VARIANT}

WORKDIR /app
COPY ../target/spring-petclinic-3.1.0.jar /app

EXPOSE 8080
CMD ["java", "-jar", "/app/spring-petclinic-3.1.0.jar"]