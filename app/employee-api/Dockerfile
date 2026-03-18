# ─────────────────────────────────────────
# STAGE 1: BUILD STAGE
# Uses full JDK to compile and package
# ─────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS builder

# Set working directory inside container
WORKDIR /app

# Copy Maven wrapper and pom.xml first
# (Docker caches this layer — rebuilds only if pom.xml changes)
COPY pom.xml .
COPY src ./src

# Install Maven and build the JAR
RUN apk add --no-cache maven && \
    mvn clean package -DskipTests -q

# ─────────────────────────────────────────
# STAGE 2: RUNTIME STAGE
# Uses slim JRE only — no build tools
# Final image is ~200MB instead of ~600MB
# ─────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy only the JAR from build stage
COPY --from=builder /app/target/employee-api-0.0.1-SNAPSHOT.jar app.jar

# Change ownership to non-root user
RUN chown appuser:appgroup app.jar

# Switch to non-root user
USER appuser

# Document the port
EXPOSE 8080

# Health check — Docker will monitor container health
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

# JVM tuning for containers
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
