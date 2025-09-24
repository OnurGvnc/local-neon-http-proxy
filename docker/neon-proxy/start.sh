#!/bin/bash

# Forward SIGTERM to child processes
trap 'kill -TERM $(jobs -p) 2>/dev/null' TERM

if [ -z "$PG_CONNECTION_STRING" ]; then
  echo "PG_CONNECTION_STRING is not set"
  exit 1
fi

# Create required tables
psql -Atx $PG_CONNECTION_STRING \
  -c "CREATE SCHEMA IF NOT EXISTS neon_control_plane" \
  -c "CREATE TABLE neon_control_plane.endpoints (endpoint_id VARCHAR(255) PRIMARY KEY, allowed_ips VARCHAR(255))"

# Setup signal handling for graceful shutdown
NEON_PROXY_PID=""

# Function to handle termination signals
terminate() {
  echo "Received termination signal. Shutting down gracefully..."
  if [ -n "$NEON_PROXY_PID" ]; then
    echo "Stopping neon-proxy (PID: $NEON_PROXY_PID)..."
    kill -TERM "$NEON_PROXY_PID"
    wait "$NEON_PROXY_PID"
  fi
  echo "Shutdown complete"
  exit 0
}

# Register signal handlers
trap terminate SIGTERM SIGINT

# Start the neon-proxy
echo "Starting neon-proxy..."
./neon-proxy \
  --auth-backend=postgres \
  --auth-endpoint=$PG_CONNECTION_STRING \
  --wss=0.0.0.0:4445 \
  &

# Store the PID of neon-proxy
NEON_PROXY_PID=$!
echo "neon-proxy started with PID: $NEON_PROXY_PID"

# Wait for the process to finish
wait $NEON_PROXY_PID

exit $?
