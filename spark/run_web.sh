#!/bin/bash
# Kill any existing Flutter web server on port 9090
lsof -ti:9090 2>/dev/null | xargs kill -9 2>/dev/null
# Also try Windows-compatible approach
netstat -ano 2>/dev/null | grep ':9090' | awk '{print $5}' | sort -u | while read pid; do
  [ "$pid" != "0" ] && taskkill //F //PID "$pid" 2>/dev/null
done
sleep 1
cd "$(dirname "$0")"
exec flutter run -d web-server --web-port 9090 --web-hostname localhost
