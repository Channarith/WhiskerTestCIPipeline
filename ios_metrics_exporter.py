#!/usr/bin/env python3
"""
iOS Metrics Exporter for Prometheus/Grafana
Collects CPU, Memory metrics from iOS Simulator
"""

from prometheus_client import start_http_server, Gauge, Info
import subprocess
import time
import sys
import re

# Define Prometheus metrics
ios_cpu = Gauge('ios_cpu_usage', 'iOS CPU usage percentage', ['app'])
ios_memory = Gauge('ios_memory_usage_mb', 'iOS Memory usage in MB', ['app'])
ios_info_metric = Info('ios_app', 'iOS app information')

def get_simulator_udid():
    """Get UDID of booted iOS simulator"""
    try:
        result = subprocess.run(
            ['xcrun', 'simctl', 'list', 'devices', 'booted'],
            capture_output=True, text=True, timeout=3
        )
        for line in result.stdout.split('\n'):
            if 'Booted' in line:
                match = re.search(r'\(([\w-]+)\)', line)
                if match:
                    return match.group(1)
        return None
    except:
        return None

def check_simulator():
    """Check if iOS simulator is running"""
    udid = get_simulator_udid()
    return udid is not None

def get_app_pid(bundle_id):
    """Get process ID of app on iOS simulator"""
    udid = get_simulator_udid()
    if not udid:
        return None
    
    try:
        result = subprocess.run(
            ['xcrun', 'simctl', 'spawn', udid, 'launchctl', 'list'],
            capture_output=True, text=True, timeout=3
        )
        for line in result.stdout.split('\n'):
            if bundle_id in line:
                parts = line.split()
                if len(parts) > 0 and parts[0].isdigit():
                    return parts[0]
        return None
    except:
        return None

def get_cpu(pid, udid):
    """Get CPU usage for iOS app"""
    try:
        result = subprocess.run(
            ['xcrun', 'simctl', 'spawn', udid, 'ps', '-p', pid, '-o', '%cpu'],
            capture_output=True, text=True, timeout=3
        )
        lines = result.stdout.strip().split('\n')
        if len(lines) > 1:
            return float(lines[1].strip())
        return 0.0
    except:
        return 0.0

def get_memory(bundle_id, udid):
    """Get memory usage for iOS app"""
    try:
        # Try different methods
        result = subprocess.run(
            ['xcrun', 'simctl', 'spawn', udid, 'footprint', bundle_id],
            capture_output=True, text=True, timeout=3
        )
        
        for line in result.stdout.split('\n'):
            if 'phys_footprint' in line or 'PHYS_FOOTPRINT' in line:
                parts = line.split()
                for part in parts:
                    # Look for memory value
                    if 'M' in part or part.replace('.', '').replace(',', '').isdigit():
                        try:
                            mem_str = part.replace('M', '').replace(',', '')
                            return float(mem_str)
                        except:
                            pass
        
        # Alternative: parse ps output
        result = subprocess.run(
            ['xcrun', 'simctl', 'spawn', udid, 'ps', '-m', '-o', 'rss'],
            capture_output=True, text=True, timeout=3
        )
        
        for line in result.stdout.split('\n'):
            if bundle_id in line:
                parts = line.split()
                if len(parts) > 0:
                    try:
                        # RSS in KB, convert to MB
                        return float(parts[0]) / 1024
                    except:
                        pass
        
        return 0.0
    except:
        return 0.0

def collect_metrics(bundle_id):
    """Collect all metrics for iOS app"""
    if not check_simulator():
        print("❌ No iOS Simulator running")
        return False
    
    udid = get_simulator_udid()
    if not udid:
        return False
    
    pid = get_app_pid(bundle_id)
    if not pid:
        print(f"⚠️  App {bundle_id} not running on simulator")
        return False
    
    # Collect metrics
    cpu = get_cpu(pid, udid)
    memory = get_memory(bundle_id, udid)
    
    # Update Prometheus metrics
    ios_cpu.labels(app=bundle_id).set(cpu)
    ios_memory.labels(app=bundle_id).set(memory)
    
    # Set app info
    ios_info_metric.info({'bundle_id': bundle_id, 'platform': 'ios', 'udid': udid})
    
    # Print to console
    print(f"[iOS] CPU: {cpu:.1f}% | Memory: {memory:.1f}MB | Simulator: {udid[:8]}...")
    
    return True

def main():
    BUNDLE_ID = "com.yourcompany.whisker"
    PORT = 8001
    
    if len(sys.argv) > 1:
        BUNDLE_ID = sys.argv[1]
    if len(sys.argv) > 2:
        PORT = int(sys.argv[2])
    
    print("=" * 70)
    print("📱 iOS Metrics Exporter")
    print("=" * 70)
    print(f"Bundle ID: {BUNDLE_ID}")
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
            collect_metrics(BUNDLE_ID)
            time.sleep(5)
        except KeyboardInterrupt:
            print("\n\n👋 Shutting down...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(5)

if __name__ == '__main__':
    main()

