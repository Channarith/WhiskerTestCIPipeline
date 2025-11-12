#!/usr/bin/env python3
"""
Run Maestro tests with performance monitoring
Combines UI testing with real-time performance tracking
"""

import subprocess
import threading
import time
import csv
from datetime import datetime
import sys
import os

class PerformanceMonitor:
    def __init__(self, package_name):
        self.package_name = package_name
        self.running = False
        self.csv_file = None
        self.metrics = []
        
    def get_metrics(self):
        """Get current performance metrics"""
        try:
            # Get PID
            pid_result = subprocess.run(
                ['adb', 'shell', 'pidof', self.package_name],
                capture_output=True, text=True, timeout=3
            )
            pid = pid_result.stdout.strip()
            
            if not pid:
                return None
            
            # CPU
            cpu = "0"
            top_result = subprocess.run(
                ['adb', 'shell', f'top -n 1 -p {pid}'],
                capture_output=True, text=True, timeout=3
            )
            for line in top_result.stdout.split('\n'):
                if pid in line:
                    parts = line.split()
                    if len(parts) > 8:
                        cpu = parts[8].replace('%', '')
                    break
            
            # Memory
            memory_mb = 0
            mem_result = subprocess.run(
                ['adb', 'shell', 'dumpsys', 'meminfo', self.package_name],
                capture_output=True, text=True, timeout=3
            )
            for line in mem_result.stdout.split('\n'):
                if 'TOTAL' in line and 'PSS' not in line:
                    parts = line.split()
                    if len(parts) > 1:
                        memory_mb = int(parts[1]) / 1024
                    break
            
            # Battery
            battery = "?"
            battery_result = subprocess.run(
                ['adb', 'shell', 'dumpsys', 'battery'],
                capture_output=True, text=True, timeout=3
            )
            for line in battery_result.stdout.split('\n'):
                if 'level:' in line:
                    battery = line.split(':')[1].strip()
                    break
            
            return {
                'cpu': cpu,
                'memory': memory_mb,
                'battery': battery,
                'timestamp': datetime.now()
            }
            
        except Exception as e:
            return None
    
    def monitor_loop(self):
        """Main monitoring loop"""
        with open(self.csv_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['Timestamp', 'CPU %', 'Memory (MB)', 'Battery %'])
            
            while self.running:
                metrics = self.get_metrics()
                
                if metrics:
                    timestamp = metrics['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
                    
                    # Save to CSV
                    writer.writerow([
                        timestamp,
                        metrics['cpu'],
                        f"{metrics['memory']:.2f}",
                        metrics['battery']
                    ])
                    f.flush()
                    
                    # Store for summary
                    self.metrics.append(metrics)
                    
                    # Print to console
                    print(f"[{timestamp}] CPU: {metrics['cpu']}% | "
                          f"Memory: {metrics['memory']:.1f}MB | "
                          f"Battery: {metrics['battery']}%")
                
                time.sleep(2)  # Sample every 2 seconds
    
    def start(self):
        """Start monitoring"""
        self.running = True
        timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.csv_file = f"test_performance_{timestamp_str}.csv"
        
        self.thread = threading.Thread(target=self.monitor_loop, daemon=True)
        self.thread.start()
        
        return self.csv_file
    
    def stop(self):
        """Stop monitoring"""
        self.running = False
        if hasattr(self, 'thread'):
            self.thread.join(timeout=5)
    
    def get_summary(self):
        """Generate performance summary"""
        if not self.metrics:
            return "No metrics collected"
        
        cpu_values = [float(m['cpu']) for m in self.metrics if m['cpu'].replace('.', '').isdigit()]
        memory_values = [m['memory'] for m in self.metrics if m['memory'] > 0]
        
        summary = []
        summary.append("\n" + "=" * 70)
        summary.append("📊 PERFORMANCE SUMMARY")
        summary.append("=" * 70)
        summary.append(f"Samples Collected: {len(self.metrics)}")
        summary.append(f"Duration: {(self.metrics[-1]['timestamp'] - self.metrics[0]['timestamp']).total_seconds():.1f}s")
        summary.append("")
        
        if cpu_values:
            summary.append(f"CPU Usage:")
            summary.append(f"  Average: {sum(cpu_values)/len(cpu_values):.2f}%")
            summary.append(f"  Min: {min(cpu_values):.2f}%")
            summary.append(f"  Max: {max(cpu_values):.2f}%")
            summary.append("")
        
        if memory_values:
            summary.append(f"Memory Usage:")
            summary.append(f"  Average: {sum(memory_values)/len(memory_values):.2f} MB")
            summary.append(f"  Min: {min(memory_values):.2f} MB")
            summary.append(f"  Max: {max(memory_values):.2f} MB")
            
            # Memory leak detection
            if len(memory_values) > 10:
                first_avg = sum(memory_values[:len(memory_values)//4]) / (len(memory_values)//4)
                last_avg = sum(memory_values[-len(memory_values)//4:]) / (len(memory_values)//4)
                growth = ((last_avg - first_avg) / first_avg) * 100
                summary.append(f"  Growth: {growth:+.2f}%", )
                if growth > 10:
                    summary.append(" ⚠️  Possible memory leak!")
                else:
                    summary.append(" ✅ Stable")
            summary.append("")
        
        if self.metrics[0]['battery'] != "?" and self.metrics[-1]['battery'] != "?":
            battery_start = int(self.metrics[0]['battery'])
            battery_end = int(self.metrics[-1]['battery'])
            battery_drain = battery_start - battery_end
            summary.append(f"Battery:")
            summary.append(f"  Start: {battery_start}%")
            summary.append(f"  End: {battery_end}%")
            summary.append(f"  Drain: {battery_drain}%")
            summary.append("")
        
        summary.append(f"📁 Detailed log: {self.csv_file}")
        summary.append("=" * 70)
        
        return "\n".join(summary)

def run_maestro_test(test_file):
    """Run Maestro test and return result"""
    print(f"\n🧪 Starting Maestro test: {test_file}\n")
    print("-" * 70)
    
    result = subprocess.run(
        ['maestro', 'test', test_file],
        capture_output=True,
        text=True
    )
    
    print(result.stdout)
    
    if result.returncode != 0:
        print(f"❌ Test failed:\n{result.stderr}")
        return False
    else:
        print("✅ Test completed successfully")
        return True

def main():
    # Configuration
    PACKAGE_NAME = "com.whisker.android"
    TEST_FILE = "whisker_ui_test.yaml"
    
    # Allow command-line arguments
    if len(sys.argv) > 1:
        TEST_FILE = sys.argv[1]
    if len(sys.argv) > 2:
        PACKAGE_NAME = sys.argv[2]
    
    # Check if test file exists
    if not os.path.exists(TEST_FILE):
        print(f"❌ Test file not found: {TEST_FILE}")
        print(f"Usage: python3 {sys.argv[0]} [test_file.yaml] [package.name]")
        sys.exit(1)
    
    print("=" * 70)
    print("🚀 MONITORED TEST RUN")
    print("=" * 70)
    print(f"App: {PACKAGE_NAME}")
    print(f"Test: {TEST_FILE}")
    print("-" * 70)
    
    # Create monitor
    monitor = PerformanceMonitor(PACKAGE_NAME)
    
    try:
        # Start monitoring
        csv_file = monitor.start()
        print(f"📊 Performance monitoring started (logging to {csv_file})")
        print("-" * 70)
        
        # Wait a moment for monitoring to start
        time.sleep(2)
        
        # Run test
        test_passed = run_maestro_test(TEST_FILE)
        
        # Continue monitoring for a bit after test
        print("\n⏳ Monitoring for 10 more seconds...")
        time.sleep(10)
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
    finally:
        # Stop monitoring
        monitor.stop()
        
        # Print summary
        print(monitor.get_summary())
        
        print("\n💡 Next steps:")
        print(f"  - Review CSV: {monitor.csv_file}")
        print(f"  - Import to Excel/Google Sheets for charts")
        print(f"  - Look for CPU spikes (> 80%)")
        print(f"  - Check memory growth (should be stable)")

if __name__ == "__main__":
    main()

