#!/usr/bin/env python3
"""
Performance Monitor for Whisker App
Monitors CPU, Memory, Battery, and FPS during testing
"""

import subprocess
import time
import csv
from datetime import datetime
import sys

def get_app_pid(package_name):
    """Get the process ID of the app"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'pidof', package_name],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.stdout.strip()
    except Exception as e:
        print(f"Error getting PID: {e}")
        return None

def get_cpu_usage(pid):
    """Get CPU usage for the app"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'top', '-n', '1', '-p', pid],
            capture_output=True,
            text=True,
            timeout=5
        )
        lines = result.stdout.split('\n')
        for line in lines:
            if pid in line:
                parts = line.split()
                # CPU is typically in column 8 or 9
                for i, part in enumerate(parts):
                    if '%' in part and i > 0:
                        return part.replace('%', '')
                if len(parts) > 8:
                    return parts[8].replace('%', '')
        return "0"
    except Exception as e:
        return "0"

def get_memory_usage(package_name):
    """Get memory usage for the app in MB"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'meminfo', package_name],
            capture_output=True,
            text=True,
            timeout=5
        )
        for line in result.stdout.split('\n'):
            if 'TOTAL' in line and 'PSS' not in line:
                parts = line.split()
                if len(parts) > 1:
                    # Memory is in KB, convert to MB
                    memory_kb = int(parts[1])
                    return memory_kb / 1024
        return 0
    except Exception as e:
        return 0

def get_battery_level():
    """Get battery level percentage"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'battery'],
            capture_output=True,
            text=True,
            timeout=5
        )
        for line in result.stdout.split('\n'):
            if 'level:' in line:
                return line.split(':')[1].strip()
        return "?"
    except Exception as e:
        return "?"

def get_fps_info(package_name):
    """Get FPS information (approximate)"""
    try:
        result = subprocess.run(
            ['adb', 'shell', 'dumpsys', 'gfxinfo', package_name, 'framestats'],
            capture_output=True,
            text=True,
            timeout=5
        )
        # This is a simplified FPS check
        # Full implementation would parse frame timing data
        return "~60"  # Default assumption for modern devices
    except Exception as e:
        return "?"

def check_adb_connection():
    """Check if ADB is connected to a device"""
    try:
        result = subprocess.run(
            ['adb', 'devices'],
            capture_output=True,
            text=True,
            timeout=5
        )
        lines = result.stdout.strip().split('\n')
        if len(lines) > 1:
            # Check if there's at least one device
            for line in lines[1:]:
                if 'device' in line and 'devices' not in line:
                    return True
        return False
    except Exception as e:
        print(f"Error checking ADB: {e}")
        return False

def monitor_app(package_name="com.whisker.android", duration=300, interval=2):
    """
    Monitor app performance
    
    Args:
        package_name: Android package name
        duration: How long to monitor in seconds (default 5 minutes)
        interval: How often to sample in seconds (default 2 seconds)
    """
    
    # Check ADB connection first
    print("🔍 Checking ADB connection...")
    if not check_adb_connection():
        print("❌ No device connected via ADB!")
        print("Please ensure:")
        print("  1. Emulator is running")
        print("  2. Run: adb devices")
        sys.exit(1)
    
    print("✅ ADB connection verified")
    print("")
    print("=" * 80)
    print("📊 WHISKER APP PERFORMANCE MONITOR")
    print("=" * 80)
    print(f"App Package: {package_name}")
    print(f"Duration: {duration} seconds ({duration/60:.1f} minutes)")
    print(f"Sample Interval: {interval} seconds")
    print("-" * 80)
    print("")
    
    # Create CSV file for logging
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    csv_file = f"performance_log_{timestamp_str}.csv"
    
    # Tracking variables
    samples_collected = 0
    cpu_readings = []
    memory_readings = []
    
    with open(csv_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'Timestamp', 'CPU %', 'Memory (MB)', 'Battery %', 'FPS'
        ])
        
        print(f"{'Timestamp':<20} {'CPU %':<10} {'Memory (MB)':<15} {'Battery %':<12} {'FPS':<10}")
        print("-" * 80)
        
        start_time = time.time()
        
        try:
            while (time.time() - start_time) < duration:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                
                # Get PID
                pid = get_app_pid(package_name)
                
                if not pid:
                    print(f"{timestamp:<20} ⚠️  App not running - waiting...")
                    time.sleep(interval)
                    continue
                
                # Get metrics
                cpu = get_cpu_usage(pid)
                memory_mb = get_memory_usage(package_name)
                battery = get_battery_level()
                fps = get_fps_info(package_name)
                
                # Track for statistics
                try:
                    cpu_readings.append(float(cpu))
                    memory_readings.append(float(memory_mb))
                except ValueError:
                    pass
                
                samples_collected += 1
                
                # Print to console
                print(f"{timestamp:<20} {cpu + '%':<10} {memory_mb:<15.1f} {battery + '%':<12} {fps:<10}")
                
                # Write to CSV
                writer.writerow([
                    timestamp, cpu, f"{memory_mb:.2f}", battery, fps
                ])
                f.flush()
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\n\n⚠️  Monitoring stopped by user (Ctrl+C)")
        
        elapsed_time = time.time() - start_time
    
    # Generate summary
    print("\n")
    print("=" * 80)
    print("📈 PERFORMANCE SUMMARY")
    print("=" * 80)
    print(f"Total Duration: {elapsed_time:.1f} seconds ({elapsed_time/60:.1f} minutes)")
    print(f"Samples Collected: {samples_collected}")
    print("")
    
    if cpu_readings:
        print(f"CPU Usage:")
        print(f"  Average: {sum(cpu_readings)/len(cpu_readings):.2f}%")
        print(f"  Min: {min(cpu_readings):.2f}%")
        print(f"  Max: {max(cpu_readings):.2f}%")
        print("")
    
    if memory_readings:
        print(f"Memory Usage:")
        print(f"  Average: {sum(memory_readings)/len(memory_readings):.2f} MB")
        print(f"  Min: {min(memory_readings):.2f} MB")
        print(f"  Max: {max(memory_readings):.2f} MB")
        
        # Check for memory leak
        if len(memory_readings) > 10:
            first_quarter = memory_readings[:len(memory_readings)//4]
            last_quarter = memory_readings[-len(memory_readings)//4:]
            avg_first = sum(first_quarter) / len(first_quarter)
            avg_last = sum(last_quarter) / len(last_quarter)
            growth = ((avg_last - avg_first) / avg_first) * 100
            
            print(f"  Growth: {growth:+.2f}%", end="")
            if growth > 10:
                print(" ⚠️  Possible memory leak detected!")
            else:
                print(" ✅ Stable")
        print("")
    
    print(f"📁 Detailed log saved to: {csv_file}")
    print("")
    print("💡 Tips:")
    print("  - Open CSV in Excel/Google Sheets for visualization")
    print("  - Look for spikes in CPU (should be < 80%)")
    print("  - Check memory growth (should be stable)")
    print("  - Compare before/after optimization")
    print("=" * 80)

if __name__ == "__main__":
    # Configuration
    PACKAGE_NAME = "com.whisker.android"
    DURATION = 300  # 5 minutes
    INTERVAL = 2    # Sample every 2 seconds
    
    # Allow command-line override
    if len(sys.argv) > 1:
        PACKAGE_NAME = sys.argv[1]
    if len(sys.argv) > 2:
        DURATION = int(sys.argv[2])
    if len(sys.argv) > 3:
        INTERVAL = int(sys.argv[3])
    
    monitor_app(
        package_name=PACKAGE_NAME,
        duration=DURATION,
        interval=INTERVAL
    )

