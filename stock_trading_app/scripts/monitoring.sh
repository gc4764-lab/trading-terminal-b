#!/bin/bash

# Monitoring and Alerting Script

# Configuration
APP_NAME="stock-trading-app"
ALERT_EMAIL="admin@stocktradingapp.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Check service health
check_health() {
    local service=$1
    local url=$2
    
    if curl -f -s -o /dev/null "$url"; then
        echo "✅ $service is healthy"
        return 0
    else
        echo "❌ $service is unhealthy"
        return 1
    fi
}

# Check system resources
check_resources() {
    # CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        send_alert "High CPU Usage" "CPU usage is at ${CPU_USAGE}%"
    fi
    
    # Memory usage
    MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
        send_alert "High Memory Usage" "Memory usage is at ${MEM_USAGE}%"
    fi
    
    # Disk usage
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    if [ "$DISK_USAGE" -gt 85 ]; then
        send_alert "High Disk Usage" "Disk usage is at ${DISK_USAGE}%"
    fi
}

# Check database
check_database() {
    if ! docker-compose exec postgres pg_isready; then
        send_alert "Database Down" "PostgreSQL is not responding"
        return 1
    fi
    
    # Check connection pool
    CONNECTIONS=$(docker-compose exec postgres psql -U trading_user -d trading_db -t -c "SELECT count(*) FROM pg_stat_activity;" | tr -d ' ')
    if [ "$CONNECTIONS" -gt 100 ]; then
        send_alert "High Database Connections" "Connection count: $CONNECTIONS"
    fi
    
    # Check replication lag (if applicable)
    # ...
}

# Check API endpoints
check_api() {
    endpoints=(
        "/health"
        "/api/watchlist"
        "/api/orders"
        "/api/positions"
    )
    
    for endpoint in "${endpoints[@]}"; do
        RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}\n' "http://localhost:8080$endpoint")
        if (( $(echo "$RESPONSE_TIME > 2.0" | bc -l) )); then
            send_alert "Slow API Response" "Endpoint $endpoint took ${RESPONSE_TIME}s"
        fi
    done
}

# Check WebSocket connections
check_websocket() {
    CONNECTION_COUNT=$(docker-compose exec backend netstat -an | grep 8080 | grep ESTABLISHED | wc -l)
    if [ "$CONNECTION_COUNT" -gt 1000 ]; then
        send_alert "High WebSocket Connections" "Connection count: $CONNECTION_COUNT"
    fi
}

# Check trading activity
check_trading_activity() {
    # Check for failed orders
    FAILED_ORDERS=$(docker-compose exec postgres psql -U trading_user -d trading_db -t -c \
        "SELECT COUNT(*) FROM orders WHERE status = 'failed' AND created_at > NOW() - INTERVAL '1 hour';" | tr -d ' ')
    
    if [ "$FAILED_ORDERS" -gt 10 ]; then
        send_alert "High Failure Rate" "$FAILED_ORDERS failed orders in last hour"
    fi
    
    # Check for unusual trading activity
    LARGE_ORDERS=$(docker-compose exec postgres psql -U trading_user -d trading_db -t -c \
        "SELECT COUNT(*) FROM orders WHERE quantity > 10000 AND created_at > NOW() - INTERVAL '1 hour';" | tr -d ' ')
    
    if [ "$LARGE_ORDERS" -gt 5 ]; then
        send_alert "Unusual Trading Activity" "$LARGE_ORDERS large orders detected"
    fi
}

# Send alert
send_alert() {
    local title=$1
    local message=$2
    
    # Send to Slack
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"*$title*\\n$message\\nTime: $(date)\"}" \
        "$SLACK_WEBHOOK"
    
    # Send email
    echo "$message" | mail -s "$title - $APP_NAME" "$ALERT_EMAIL"
    
    # Log to file
    echo "[$(date)] $title - $message" >> /var/log/trading-app/alerts.log
}

# Generate report
generate_report() {
    REPORT_FILE="/tmp/trading-report-$(date +%Y%m%d).html"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Trading Application Report - $(date)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .metric { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .critical { color: red; }
    </style>
</head>
<body>
    <h1>Trading Application Report</h1>
    <p>Generated: $(date)</p>
    
    <div class="metric">
        <h2>System Health</h2>
        <p>CPU Usage: <span class="$([[ $(echo "$CPU_USAGE > 80" | bc -l) ]] && echo "critical" || echo "good")">${CPU_USAGE}%</span></p>
        <p>Memory Usage: <span class="$([[ $(echo "$MEM_USAGE > 90" | bc -l) ]] && echo "critical" || echo "good")">${MEM_USAGE}%</span></p>
        <p>Disk Usage: <span class="$([ "$DISK_USAGE" -gt 85 ] && echo "critical" || echo "good")">${DISK_USAGE}%</span></p>
    </div>
    
    <div class="metric">
        <h2>Trading Metrics</h2>
        <p>Total Orders Today: $TOTAL_ORDERS</p>
        <p>Successful Orders: $SUCCESSFUL_ORDERS</p>
        <p>Failed Orders: $FAILED_ORDERS</p>
        <p>Total Volume: $TOTAL_VOLUME</p>
    </div>
</body>
</html>
EOF
    
    echo "Report generated: $REPORT_FILE"
}

# Main monitoring loop
main() {
    echo "Starting monitoring for $APP_NAME..."
    
    while true; do
        check_resources
        check_database
        check_api
        check_websocket
        check_trading_activity
        
        # Generate report every hour
        if [ $(date +%M) -eq 0 ]; then
            generate_report
        fi
        
        sleep 60
    done
}

# Run main function
main "$@"