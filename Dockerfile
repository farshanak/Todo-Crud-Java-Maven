# --- Stage 1: Dependencies ---
FROM eclipse-temurin:23-jdk-alpine AS deps
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B || true

# --- Stage 2: Builder ---
FROM deps AS builder
COPY src ./src
RUN ./mvnw package -DskipTests -B

# --- Stage 3: Production ---
FROM eclipse-temurin:23-jre-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/target/*.jar app.jar
ENV SERVER_PORT=8080
EXPOSE 8080
USER appuser
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/todos || exit 1
CMD ["java", "-jar", "app.jar"]

# --- Stage 4: Development ---
FROM eclipse-temurin:23-jdk-alpine AS development
WORKDIR /app
COPY . .
RUN chmod +x mvnw
ENV SERVER_PORT=8080
EXPOSE 8080
CMD ["./mvnw", "spring-boot:run"]
