#!/usr/bin/env bash

# Kill existing processes on the ports
PORTS=(8761 8081 8082 8083)
for PORT in "${PORTS[@]}"; do
    PID=$(lsof -t -i:$PORT)
    if [ -n "$PID" ]; then
        echo "Killing process on port $PORT (PID: $PID)"
        kill -9 $PID
    fi
done

echo "Starting Discovery Server..."
mvn spring-boot:run -pl discovery-server &

# Wait for discovery server to start (simple sleep or check port)
sleep 15

echo "Starting Product Service..."
mvn spring-boot:run -pl product-service &

echo "Starting Order Service..."
mvn spring-boot:run -pl order-service &

echo "Starting Inventory Service..."
mvn spring-boot:run -pl inventory-service &

echo "All services are starting up. Follow logs in background or visit http://localhost:8761"
wait
