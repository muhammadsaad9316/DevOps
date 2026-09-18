#!/bin/bash

# ==============================================================================
# Script: service_dispatcher.sh
# Track: Bash Companion - Day 14
# Objective: Production CLI dispatcher using a 'case' statement.
#
# Usage: ./service_dispatcher.sh {start|stop|restart|status}
# ==============================================================================

ACTION="$1"

case "$ACTION" in
  start)
    echo "▶️  Starting application services..."
    echo "Service initialized with PID: $$"
    ;;
  stop)
    echo "⏹️  Stopping application services cleanly..."
    echo "All child threads terminated."
    ;;
  restart)
    echo "🔄 Recycling service workers..."
    $0 stop
    sleep 1
    $0 start
    ;;
  status)
    echo "📊 Service Status: ACTIVE (running)"
    echo "Port 8080 listening."
    ;;
  *)
    echo "❌ Error: Invalid action '$ACTION'." >&2
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
    ;;
esac

exit 0
