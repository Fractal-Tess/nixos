#!/usr/bin/env bash
# Playwright CDP Container
# Starts a headless Chromium browser with Chrome DevTools Protocol exposed
# Used by @playwright/mcp for browser automation

CONTAINER_NAME="playwright-cdp"
PORT="${PLAYWRIGHT_CDP_PORT:-9223}"
IMAGE="zenika/alpine-chrome:with-node"

case "${1:-start}" in
  start)
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
      echo "Container '$CONTAINER_NAME' is already running on port $PORT"
      exit 0
    fi
    
    # Remove stopped container if exists
    docker rm -f "$CONTAINER_NAME" 2>/dev/null
    
    echo "Starting Playwright CDP container on port $PORT..."
    docker run -d \
      --name "$CONTAINER_NAME" \
      -p "$PORT:9222" \
      --init \
      --ipc=host \
      "$IMAGE" \
      chromium-browser \
        --no-sandbox \
        --headless \
        --remote-debugging-address=0.0.0.0 \
        --remote-debugging-port=9222 \
        --disable-gpu
    
    echo "Playwright CDP available at http://127.0.0.1:$PORT"
    echo ""
    echo "MCP config for ~/.config/amp/settings.json:"
    echo '  "playwright": {'
    echo '    "command": "npx",'
    echo '    "args": ["@playwright/mcp@latest", "--cdp-endpoint", "http://127.0.0.1:'"$PORT"'"]'
    echo '  }'
    ;;
  
  stop)
    echo "Stopping Playwright CDP container..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null
    echo "Stopped"
    ;;
  
  restart)
    "$0" stop
    "$0" start
    ;;
  
  status)
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
      echo "Running on port $PORT"
      docker logs --tail 5 "$CONTAINER_NAME" 2>&1
    else
      echo "Not running"
    fi
    ;;
  
  logs)
    docker logs -f "$CONTAINER_NAME"
    ;;
  
  *)
    echo "Usage: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "Environment variables:"
    echo "  PLAYWRIGHT_CDP_PORT  Port to expose (default: 9223)"
    exit 1
    ;;
esac
