#!/usr/bin/env bash

# Kill existing process on Keycloak port if any
PORT=8180
PID=$(lsof -t -i:$PORT)
if [ -n "$PID" ]; then
    echo "Killing process on port $PORT (PID: $PID)"
    kill -9 $PID
fi

# Restart Keycloak Docker container with persistence
echo "Starting Keycloak..."
docker rm -f keycloak 2>/dev/null
docker run -d --name keycloak -p 8180:8080 \
  -v keycloak_data:/opt/keycloak/data \
  -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:18.0.0 start-dev

echo "Keycloak is starting at http://localhost:8180"
