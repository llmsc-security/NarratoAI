#!/bin/bash
# Invoke script for NarratoAI Docker container
# Usage: ./invoke.sh [mode] [options]

set -e

CONTAINER_NAME="narratoai"
PORT=11170
IMAGE_NAME="narratoai:latest"

# Parse arguments
MODE="${1:-start}"
shift || true

# Function to start the container
start_container() {
    echo "Starting NarratoAI container on port $PORT..."

    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container already exists, removing..."
        docker rm -f "$CONTAINER_NAME" || true
    fi

    # Create storage directories if they don't exist
    mkdir -p storage/temp storage/tasks storage/json storage/narration_scripts storage/drama_analysis

    # Run the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p $PORT:8501 \
        -v "$(pwd)/storage:/NarratoAI/storage:rw" \
        -v "$(pwd)/config.toml:/NarratoAI/config.toml:rw" \
        -v "$(pwd)/resource:/NarratoAI/resource:rw" \
        -e PYTHONUNBUFFERED=1 \
        -e TZ=Asia/Shanghai \
        --restart=unless-stopped \
        "$IMAGE_NAME" \
        "$@"
}

# Function to stop the container
stop_container() {
    echo "Stopping NarratoAI container..."
    docker stop "$CONTAINER_NAME" || true
    docker rm -f "$CONTAINER_NAME" || true
}

# Function to show logs
show_logs() {
    docker logs -f "$CONTAINER_NAME"
}

# Function to run inside container
run_command() {
    docker exec -it "$CONTAINER_NAME" "$@"
}

# Main logic
case "$MODE" in
    start)
        start_container
        echo "Container started successfully!"
        echo "Access the Streamlit web UI at http://localhost:$PORT"
        ;;
    stop)
        stop_container
        echo "Container stopped successfully!"
        ;;
    logs)
        show_logs
        ;;
    exec)
        shift
        run_command "$@"
        ;;
    health)
        docker exec "$CONTAINER_NAME" curl -f http://localhost:8501/_stcore/health || echo "Container not running"
        ;;
    *)
        echo "Usage: $0 {start|stop|logs|exec <cmd>|health}"
        echo ""
        echo "Modes:"
        echo "  start    - Start the container in daemon mode"
        echo "  stop     - Stop and remove the container"
        echo "  logs     - Follow container logs"
        echo "  exec     - Execute a command inside the container"
        echo "  health   - Check container health"
        exit 1
        ;;
esac
