#!/bin/bash

# Deployment Verification Script

echo "🔍 Verifying Stock Trading Application Deployment"

# Check Docker containers
echo "Checking Docker containers..."
if docker ps | grep -q "stock-trading-app"; then
    echo "✅ Docker containers are running"
else
    echo "❌ Docker containers not running"
    exit 1
fi

# Check backend health
echo "Checking backend health..."
if curl -f http://localhost:8080/health; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    exit 1
fi

# Check frontend
echo "Checking frontend..."
if curl -f http://localhost:80; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend check failed"
    exit 1
fi

# Check database
echo "Checking database..."
if docker-compose exec postgres pg_isready; then
    echo "✅ Database is ready"
else
    echo "❌ Database check failed"
    exit 1
fi

# Check Redis
echo "Checking Redis..."
if docker-compose exec redis redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is working"
else
    echo "❌ Redis check failed"
    exit 1
fi

# Check WebSocket
echo "Checking WebSocket..."
if wscat -c ws://localhost:8080/ws -x '{"action":"ping"}' | grep -q "pong"; then
    echo "✅ WebSocket is working"
else
    echo "❌ WebSocket check failed"
    exit 1
fi

# Check database tables
echo "Checking database tables..."
TABLES=$(docker-compose exec postgres psql -U trading_user -d trading_db -t -c \
    "SELECT table_name FROM information_schema.tables WHERE table_schema='public';")

EXPECTED_TABLES=("users" "watchlist_items" "alerts" "broker_configs" "orders" "positions" "holdings")

for table in "${EXPECTED_TABLES[@]}"; do
    if echo "$TABLES" | grep -q "$table"; then
        echo "✅ Table $table exists"
    else
        echo "❌ Table $table missing"
        exit 1
    fi
done

# Check metrics endpoint
echo "Checking metrics endpoint..."
if curl -f http://localhost:9090/metrics; then
    echo "✅ Metrics endpoint accessible"
else
    echo "⚠️ Metrics endpoint not accessible"
fi

# Check disk space
echo "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✅ Disk space OK (${DISK_USAGE}%)"
else
    echo "⚠️ Low disk space: ${DISK_USAGE}%"
fi

# Check memory usage
echo "Checking memory usage..."
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
if (( $(echo "$MEM_USAGE < 80" | bc -l) )); then
    echo "✅ Memory usage OK (${MEM_USAGE}%)"
else
    echo "⚠️ High memory usage: ${MEM_USAGE}%"
fi

# Check CPU usage
echo "Checking CPU usage..."
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    echo "✅ CPU usage OK (${CPU_USAGE}%)"
else
    echo "⚠️ High CPU usage: ${CPU_USAGE}%"
fi

# Generate verification report
REPORT_FILE="/tmp/verification-report-$(date +%Y%m%d-%H%M%S).html"

cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Verification Report</title>
    <style>
        body { font-family: monospace; margin: 20px; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        .metric { margin: 5px 0; }
    </style>
</head>
<body>
    <h1>Deployment Verification Report</h1>
    <p>Generated: $(date)</p>
    <p>Version: $(git describe --tags --always)</p>
    
    <h2>System Status</h2>
    <div class="metric">Docker: <span class="success">✅ Running</span></div>
    <div class="metric">Backend: <span class="success">✅ Healthy</span></div>
    <div class="metric">Frontend: <span class="success">✅ Accessible</span></div>
    <div class="metric">Database: <span class="success">✅ Ready</span></div>
    <div class="metric">Redis: <span class="success">✅ Working</span></div>
    <div class="metric">WebSocket: <span class="success">✅ Connected</span></div>
    
    <h2>Resources</h2>
    <div class="metric">Disk Usage: <span class="$([ "$DISK_USAGE" -lt 80 ] && echo "success" || echo "warning")">${DISK_USAGE}%</span></div>
    <div class="metric">Memory Usage: <span class="$([ $(echo "$MEM_USAGE < 80" | bc -l) ] && echo "success" || echo "warning")">${MEM_USAGE}%</span></div>
    <div class="metric">CPU Usage: <span class="$([ $(echo "$CPU_USAGE < 80" | bc -l) ] && echo "success" || echo "warning")">${CPU_USAGE}%</span></div>
    
    <h2>Database Tables</h2>
EOF

for table in "${EXPECTED_TABLES[@]}"; do
    echo "<div class=\"metric\">Table $table: <span class=\"success\">✅ Present</span></div>" >> "$REPORT_FILE"
done

echo "</body></html>" >> "$REPORT_FILE"

echo "📊 Verification report generated: $REPORT_FILE"
echo "🎉 Deployment verification completed successfully!"