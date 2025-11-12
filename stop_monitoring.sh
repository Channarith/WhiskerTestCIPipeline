#!/bin/bash
# Stop all monitoring services

echo "🛑 Stopping all monitoring services..."

# Kill processes by PID if available
if [ -f "logs/android.pid" ]; then
    kill $(cat logs/android.pid) 2>/dev/null && echo "   ✅ Android exporter stopped"
    rm logs/android.pid
fi

if [ -f "logs/ios.pid" ]; then
    kill $(cat logs/ios.pid) 2>/dev/null && echo "   ✅ iOS exporter stopped"
    rm logs/ios.pid
fi

if [ -f "logs/desktop.pid" ]; then
    kill $(cat logs/desktop.pid) 2>/dev/null && echo "   ✅ Desktop exporter stopped"
    rm logs/desktop.pid
fi

if [ -f "logs/prometheus.pid" ]; then
    kill $(cat logs/prometheus.pid) 2>/dev/null && echo "   ✅ Prometheus stopped"
    rm logs/prometheus.pid
fi

# Kill by process name as backup
pkill -f "android_metrics_exporter" && echo "   ✅ Killed remaining Android exporters"
pkill -f "ios_metrics_exporter" && echo "   ✅ Killed remaining iOS exporters"
pkill -f "desktop_metrics_exporter" && echo "   ✅ Killed remaining Desktop exporters"
pkill -f "prometheus.*prometheus_multiplatform" && echo "   ✅ Killed remaining Prometheus instances"

# Stop Grafana
if command -v grafana &> /dev/null; then
    brew services stop grafana > /dev/null 2>&1 && echo "   ✅ Grafana stopped"
fi

echo ""
echo "✅ All monitoring services stopped"

