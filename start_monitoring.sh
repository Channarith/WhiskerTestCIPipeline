#!/bin/bash
# Start all monitoring services for Whisker app

set -e

echo "🚀 Starting Cross-Platform Monitoring for Whisker App"
echo "=" | tr '=' '=' | head -c 70 && echo ""

# Create logs directory
mkdir -p logs

# Configuration
ANDROID_PACKAGE="com.whisker.android"
IOS_BUNDLE="com.yourcompany.whisker"
DESKTOP_APP="whisker"

# Check dependencies
echo "🔍 Checking dependencies..."

if ! command -v python3 &> /dev/null; then
    echo "❌ python3 not found. Please install Python 3."
    exit 1
fi

if ! command -v prometheus &> /dev/null; then
    echo "⚠️  Prometheus not found. Install with: brew install prometheus"
fi

if ! command -v grafana &> /dev/null; then
    echo "⚠️  Grafana not found. Install with: brew install grafana"
fi

echo "✅ Dependencies check complete"
echo ""

# Kill any existing instances
echo "🧹 Cleaning up existing instances..."
pkill -f "android_metrics_exporter" || true
pkill -f "ios_metrics_exporter" || true
pkill -f "desktop_metrics_exporter" || true
pkill -f "prometheus.*prometheus_multiplatform" || true

sleep 2

# Start Android metrics exporter
echo "📱 Starting Android metrics exporter..."
if [ -f "android_metrics_exporter.py" ]; then
    python3 android_metrics_exporter.py "$ANDROID_PACKAGE" > logs/android.log 2>&1 &
    ANDROID_PID=$!
    echo "   ✅ Android exporter started (PID: $ANDROID_PID)"
    echo "   📊 Metrics: http://localhost:8000/metrics"
else
    echo "   ⚠️  android_metrics_exporter.py not found"
fi

sleep 1

# Start iOS metrics exporter
echo "📱 Starting iOS metrics exporter..."
if [ -f "ios_metrics_exporter.py" ]; then
    python3 ios_metrics_exporter.py "$IOS_BUNDLE" > logs/ios.log 2>&1 &
    IOS_PID=$!
    echo "   ✅ iOS exporter started (PID: $IOS_PID)"
    echo "   📊 Metrics: http://localhost:8001/metrics"
else
    echo "   ⚠️  ios_metrics_exporter.py not found"
fi

sleep 1

# Start Desktop metrics exporter
echo "💻 Starting Desktop metrics exporter..."
if [ -f "desktop_metrics_exporter.py" ]; then
    python3 desktop_metrics_exporter.py "$DESKTOP_APP" > logs/desktop.log 2>&1 &
    DESKTOP_PID=$!
    echo "   ✅ Desktop exporter started (PID: $DESKTOP_PID)"
    echo "   📊 Metrics: http://localhost:8002/metrics"
else
    echo "   ⚠️  desktop_metrics_exporter.py not found"
fi

sleep 2

# Start Prometheus
echo "📈 Starting Prometheus..."
if [ -f "prometheus_multiplatform.yml" ]; then
    prometheus --config.file=prometheus_multiplatform.yml \
        --storage.tsdb.path=./prometheus_data \
        > logs/prometheus.log 2>&1 &
    PROM_PID=$!
    echo "   ✅ Prometheus started (PID: $PROM_PID)"
    echo "   🌐 UI: http://localhost:9090"
else
    echo "   ⚠️  prometheus_multiplatform.yml not found"
fi

sleep 2

# Start Grafana
echo "📊 Starting Grafana..."
if command -v grafana &> /dev/null; then
    brew services start grafana > /dev/null 2>&1 || true
    echo "   ✅ Grafana started"
    echo "   🌐 Dashboard: http://localhost:3000"
    echo "   👤 Default login: admin/admin"
else
    echo "   ⚠️  Grafana not installed"
fi

# Save PIDs
echo "$ANDROID_PID" > logs/android.pid
echo "$IOS_PID" > logs/ios.pid
echo "$DESKTOP_PID" > logs/desktop.pid
echo "$PROM_PID" > logs/prometheus.pid

echo ""
echo "=" | tr '=' '=' | head -c 70 && echo ""
echo "✅ All services started!"
echo "=" | tr '=' '=' | head -c 70 && echo ""
echo ""
echo "📊 Access Points:"
echo "   • Grafana Dashboard: http://localhost:3000"
echo "   • Prometheus: http://localhost:9090"
echo "   • Android Metrics: http://localhost:8000/metrics"
echo "   • iOS Metrics: http://localhost:8001/metrics"
echo "   • Desktop Metrics: http://localhost:8002/metrics"
echo ""
echo "📋 Logs:"
echo "   • Android: tail -f logs/android.log"
echo "   • iOS: tail -f logs/ios.log"
echo "   • Desktop: tail -f logs/desktop.log"
echo "   • Prometheus: tail -f logs/prometheus.log"
echo ""
echo "🛑 To stop all services: ./stop_monitoring.sh"
echo ""
echo "🎯 Now run your tests and watch the metrics!"
echo ""

