#!/usr/bin/env python3
"""
Desktop Metrics Exporter for Prometheus/Grafana
Collects CPU, Memory, Network metrics from desktop application
"""

from prometheus_client import start_http_server, Gauge, Info
import psutil
import time
import sys

# Define Prometheus metrics
desktop_cpu = Gauge('desktop_cpu_usage', 'Desktop CPU usage percentage', ['app'])
desktop_memory = Gauge('desktop_memory_usage_mb', 'Desktop Memory usage in MB', ['app'])
desktop_threads = Gauge('desktop_thread_count', 'Number of threads', ['app'])
desktop_open_files = Gauge('desktop_open_files', 'Number of open files', ['app'])
desktop_info_metric = Info('desktop_app', 'Desktop app information')

def find_process(search_term):
    """Find process by name or command line"""
    for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
        try:
            # Check process name
            if search_term.lower() in proc.info['name'].lower():
                return proc
            
            # Check command line
            if proc.info['cmdline']:
                cmdline = ' '.join(proc.info['cmdline']).lower()
                if search_term.lower() in cmdline:
                    return proc
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return None

def collect_metrics(app_name):
    """Collect all metrics for desktop app"""
    proc = find_process(app_name)
    
    if not proc:
        print(f"⚠️  App '{app_name}' not running")
        return False
    
    try:
        # Collect metrics
        cpu = proc.cpu_percent(interval=1)
        memory_mb = proc.memory_info().rss / (1024 * 1024)
        num_threads = proc.num_threads()
        
        # Open files (may fail on some systems)
        try:
            open_files = len(proc.open_files())
        except:
            open_files = 0
        
        # Update Prometheus metrics
        desktop_cpu.labels(app=app_name).set(cpu)
        desktop_memory.labels(app=app_name).set(memory_mb)
        desktop_threads.labels(app=app_name).set(num_threads)
        desktop_open_files.labels(app=app_name).set(open_files)
        
        # Set app info
        desktop_info_metric.info({
            'app': app_name,
            'platform': 'desktop',
            'pid': str(proc.pid),
            'name': proc.name()
        })
        
        # Print to console
        print(f"[Desktop] CPU: {cpu:.1f}% | Memory: {memory_mb:.1f}MB | "
              f"Threads: {num_threads} | Files: {open_files} | PID: {proc.pid}")
        
        return True
        
    except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
        print(f"Error accessing process: {e}")
        return False

def main():
    APP_NAME = "whisker"
    PORT = 8002
    
    if len(sys.argv) > 1:
        APP_NAME = sys.argv[1]
    if len(sys.argv) > 2:
        PORT = int(sys.argv[2])
    
    print("=" * 70)
    print("💻 Desktop Metrics Exporter")
    print("=" * 70)
    print(f"App Name: {APP_NAME}")
    print(f"Port: {PORT}")
    print(f"Metrics URL: http://localhost:{PORT}/metrics")
    print("-" * 70)
    
    # Check if psutil is installed
    try:
        import psutil
    except ImportError:
        print("❌ Error: psutil not installed")
        print("Install with: pip3 install psutil")
        sys.exit(1)
    
    # Start Prometheus HTTP server
    start_http_server(PORT)
    print(f"✅ Metrics server started on port {PORT}")
    print("")
    
    # Collect metrics loop
    while True:
        try:
            collect_metrics(APP_NAME)
            time.sleep(5)
        except KeyboardInterrupt:
            print("\n\n👋 Shutting down...")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(5)

if __name__ == '__main__':
    main()

