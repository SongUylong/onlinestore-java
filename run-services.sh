#!/usr/bin/env bash

# Kill existing processes on the ports
PORTS=(8761 8081 8181 8180)
for PORT in "${PORTS[@]}"; do
    PID=$(lsof -t -i:$PORT)
    if [ -n "$PID" ]; then
        echo "Killing process on port $PORT (PID: $PID)"
        kill -9 $PID
    fi
done

# Restart Keycloak Docker container
echo "Starting Keycloak..."
docker rm -f keycloak 2>/dev/null
docker run -d --name keycloak -p 8180:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:18.0.0 start-dev

echo "Starting Discovery Server..."
mvn spring-boot:run -pl discovery-server &

# Wait for discovery server to start
sleep 15

echo "Starting API Gateway..."
mvn spring-boot:run -pl api-gateway &

echo "Starting Product Service..."
mvn spring-boot:run -pl product-service &

echo "Starting Order Service..."
mvn spring-boot:run -pl order-service &

echo "Starting Inventory Service..."
mvn spring-boot:run -pl inventory-service &

echo "All services are starting up. Follow logs in background or visit http://localhost:8761"
wait
