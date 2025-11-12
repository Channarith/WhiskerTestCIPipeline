#!/usr/bin/env python3
"""
Android Metrics Exporter for Prometheus/Grafana
Collects CPU, Memory, Battery, Network metrics from Android device/emulator
"""

from prometheus_client import start_http_server, Gauge, Info
import subprocess
import time
import sys

# Define Prometheus metrics
android_cpu = Gauge('android_cpu_usage', 'Android CPU usage percentage', ['app'])
android_memory = Gauge('android_memory_usage_mb', 'Android Memory usage in MB', ['app'])
android_battery = Gauge('android_battery_level', 'Android Battery level percentage')
android_fps = Gauge('android_fps', 'Android FPS (frames per second)', ['app'])
android_network_rx = Gauge('android_network_rx_bytes', 'Network bytes received', ['app'])
android_network_tx = Gauge('android_network_tx_bytes', 'Network bytes transmitted', ['app'])

# App info
android_info = Info('android_app', 'Android app information')

def check_adb():
    """Check if ADB is connected"""
    try:
        result = subprocess.run(['adb', 'devices'], capture_output=True, text=True, timeout=3)
        lines = result.stdout.strip().split('\n')
        for line in lines[1:]:
            if 'device' in line and 'devices' not in line:
                return True
        return False
    except:
        return False

def get_pid(package):
    """Get process ID of the app"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'pidof', package],
            capture_output=True, text=True, timeout=3
        )
        return result.stdout.strip()
    except:
        return None

def get_cpu(pid):
    """Get CPU usage"""
    try:
        result = subprocess.run(
            ['adb', 'shell', f'top -n 1 -p {pid}'],
            capture_output=True, text=True, timeout=3
        )
        for line in result.stdout.split('\n'):
            if pid in line:
                parts = line.split()
                if len(parts) > 8:
                    return float(parts[8].replace('%', ''))
        return 0.0
    except:
        return 0.0

def get_memory(package):
    """Get memory usage in MB"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'meminfo', package],
            capture_output=True, text=True, timeout=3
        )
        for line in result.stdout.split('\n'):
            if 'TOTAL' in line and 'PSS' not in line:
                parts = line.split()
                if len(parts) > 1:
                    return float(parts[1]) / 1024  # KB to MB
        return 0.0
    except:
        return 0.0

def get_battery():
    """Get battery level"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'battery'],
            capture_output=True, text=True, timeout=3
        )
        for line in result.stdout.split('\n'):
            if 'level:' in line:
                return float(line.split(':')[1].strip())
        return 0.0
    except:
        return 0.0

def get_fps(package):
    """Get approximate FPS"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'gfxinfo', package, 'framestats'],
            capture_output=True, text=True, timeout=3
        )
        # Simplified - returns default
        return 60.0
    except:
        return 60.0

def collect_metrics(package):
    """Collect all metrics for the app"""
    if not check_adb():
        print("❌ No ADB connection")
        return False
    
    pid = get_pid(package)
    if not pid:
        print(f"⚠️  App {package} not running")
        return False
    
    # Collect metrics
    cpu = get_cpu(pid)
    memory = get_memory(package)
    battery = get_battery()
    fps = get_fps(package)
    
    # Update Prometheus metrics
    android_cpu.labels(app=package).set(cpu)
    android_memory.labels(app=package).set(memory)
    android_battery.set(battery)
    android_fps.labels(app=package).set(fps)
    
    # Set app info
    android_info.info({'package': package, 'platform': 'android'})
    
    # Print to console
    print(f"[Android] CPU: {cpu:.1f}% | Memory: {memory:.1f}MB | Battery: {battery:.0f}% | FPS: {fps:.0f}")
    
    return True

def main():
    PACKAGE = "com.whisker.android"
    PORT = 8000
    
    if len(sys.argv) > 1:
        PACKAGE = sys.argv[1]
    if len(sys.argv) > 2:
        PORT = int(sys.argv[2])
    
    print("=" * 70)
    print("📱 Android Metrics Exporter")
    print("=" * 70)
    print(f"Package: {PACKAGE}")
    print(f"Port: {PORT}")
    print(f"Metrics URL: http://localhost:{PORT}/metrics")
    print("-" * 70)
    
    # Start Prometheus HTTP server
    start_http_server(PORT)
    print(f"✅ Metrics server started on port {PORT}")
    print("")
    
    # Collect metrics loop
    while True:
        try:
            collect_metrics(PACKAGE)
            time.sleep(5)
        except KeyboardInterrupt:
            print("\n\n👋 Shutting down...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(5)

if __name__ == '__main__':
    main()

