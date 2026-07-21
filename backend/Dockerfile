FROM maven:3.9.11-eclipse-temurin-21-alpine AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache curl && addgroup -S spring && adduser -S spring -G spring
WORKDIR /app
COPY --from=build /workspace/target/gnezdo-api.jar /app/app.jar
USER spring
EXPOSE 8080
HEALTHCHECK --interval=20s --timeout=4s --start-period=20s --retries=5 CMD curl -fsS http://127.0.0.1:8080/actuator/health || exit 1
ENTRYPOINT ["java","-XX:MaxRAMPercentage=75.0","-jar","/app/app.jar"]
