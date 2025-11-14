#!/usr/bin/env python3
"""
Whisker Stress Test Runner
Runs exhaustive tests repeatedly with headless mode support
"""

import subprocess
import os
import time
import sys
from datetime import datetime
import json

class StressTestRunner:
    def __init__(self, headless=False):
        self.headless = headless
        self.maestro_path = os.path.expanduser('~/.maestro/bin/maestro')
        self.test_dir = "organized_tests"
        self.results = []
        self.java_env = {
            'JAVA_HOME': '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
        }
        self.java_env['PATH'] = f"{self.java_env['JAVA_HOME']}/bin:{os.environ.get('PATH', '')}"
        
    def get_test_files(self):
        """Get all test files in organized_tests directory"""
        if not os.path.exists(self.test_dir):
            print(f"❌ Test directory not found: {self.test_dir}")
            return []
        
        test_files = []
        for file in sorted(os.listdir(self.test_dir)):
            if file.endswith('.yaml'):
                test_files.append(os.path.join(self.test_dir, file))
        
        return test_files
    
    def run_test(self, test_file, iteration=1):
        """Run a single test file"""
        test_name = os.path.basename(test_file)
        print(f"\n{'='*60}")
        print(f"🧪 Running: {test_name} (Iteration {iteration})")
        print(f"{'='*60}")
        
        start_time = time.time()
        
        # Build command
        cmd = [self.maestro_path, 'test']
        
        # Add headless flag if enabled
        if self.headless:
            cmd.append('--headless')
        
        # Add debug output
        debug_dir = f"stress_test_output/{datetime.now().strftime('%Y%m%d_%H%M%S')}_{test_name.replace('.yaml', '')}"
        os.makedirs(debug_dir, exist_ok=True)
        cmd.extend(['--debug-output', debug_dir])
        
        # Add test file
        cmd.append(test_file)
        
        try:
            result = subprocess.run(
                cmd,
                env={**os.environ, **self.java_env},
                capture_output=False if not self.headless else True,
                text=True,
                timeout=300  # 5 minutes per test
            )
            
            elapsed = time.time() - start_time
            success = result.returncode == 0
            
            test_result = {
                'test': test_name,
                'iteration': iteration,
                'success': success,
                'elapsed': elapsed,
                'timestamp': datetime.now().isoformat(),
                'debug_dir': debug_dir
            }
            
            self.results.append(test_result)
            
            if success:
                print(f"✅ {test_name} PASSED ({elapsed:.1f}s)")
            else:
                print(f"❌ {test_name} FAILED ({elapsed:.1f}s)")
                if self.headless and result.stderr:
                    print(f"Error: {result.stderr[:500]}")
            
            return success
            
        except subprocess.TimeoutExpired:
            elapsed = time.time() - start_time
            print(f"⏱️  {test_name} TIMEOUT ({elapsed:.1f}s)")
            self.results.append({
                'test': test_name,
                'iteration': iteration,
                'success': False,
                'elapsed': elapsed,
                'timeout': True,
                'timestamp': datetime.now().isoformat()
            })
            return False
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"❌ {test_name} ERROR: {e}")
            self.results.append({
                'test': test_name,
                'iteration': iteration,
                'success': False,
                'elapsed': elapsed,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
            return False
    
    def reset_app(self):
        """Reset app state between tests"""
        print("\n🔄 Resetting app state...")
        adb_path = os.path.expanduser('~/Library/Android/Sdk/platform-tools/adb')
        package_name = "com.whisker.android"
        
        try:
            # Force stop
            subprocess.run(
                [adb_path, 'shell', 'am', 'force-stop', package_name],
                capture_output=True,
                timeout=5
            )
            
            # Clear data
            subprocess.run(
                [adb_path, 'shell', 'pm', 'clear', package_name],
                capture_output=True,
                timeout=10
            )
            
            # Launch
            subprocess.run(
                [adb_path, 'shell', 'monkey', '-p', package_name, '-c', 'android.intent.category.LAUNCHER', '1'],
                capture_output=True,
                timeout=5
            )
            
            print("✅ App reset complete")
            time.sleep(5)  # Wait for app to launch
            return True
        except Exception as e:
            print(f"⚠️  App reset failed: {e}")
            return False
    
    def run_stress_test(self, iterations=3, reset_between=True):
        """Run all tests multiple times"""
        print("\n" + "="*60)
        print("🏋️  WHISKER STRESS TEST")
        print("="*60)
        print(f"Mode: {'Headless' if self.headless else 'Interactive'}")
        print(f"Iterations: {iterations}")
        print(f"Reset between tests: {reset_between}")
        
        test_files = self.get_test_files()
        if not test_files:
            print("❌ No test files found!")
            return
        
        print(f"\nTests to run: {len(test_files)}")
        for test in test_files:
            print(f"  - {os.path.basename(test)}")
        
        start_time = time.time()
        
        for iteration in range(1, iterations + 1):
            print(f"\n{'🔥'*30}")
            print(f"🔥  ITERATION {iteration}/{iterations}")
            print(f"{'🔥'*30}")
            
            for test_file in test_files:
                if reset_between:
                    self.reset_app()
                
                self.run_test(test_file, iteration)
                
                # Brief pause between tests
                if test_file != test_files[-1]:
                    print("\n⏸️  Pausing 3s before next test...")
                    time.sleep(3)
            
            # Longer pause between iterations
            if iteration < iterations:
                print(f"\n⏸️  Iteration {iteration} complete. Pausing 10s...")
                time.sleep(10)
        
        total_elapsed = time.time() - start_time
        
        # Print summary
        self.print_summary(total_elapsed)
        
        # Save results
        self.save_results()
    
    def print_summary(self, total_elapsed):
        """Print test summary"""
        print("\n" + "="*60)
        print("📊 STRESS TEST SUMMARY")
        print("="*60)
        
        total_tests = len(self.results)
        passed = sum(1 for r in self.results if r['success'])
        failed = total_tests - passed
        
        print(f"\nTotal Tests: {total_tests}")
        print(f"✅ Passed: {passed} ({passed/total_tests*100:.1f}%)")
        print(f"❌ Failed: {failed} ({failed/total_tests*100:.1f}%)")
        print(f"⏱️  Total Time: {total_elapsed:.1f}s ({total_elapsed/60:.1f}min)")
        
        if failed > 0:
            print("\n❌ Failed Tests:")
            for result in self.results:
                if not result['success']:
                    print(f"  - {result['test']} (Iteration {result['iteration']})")
                    if 'timeout' in result:
                        print(f"    Reason: Timeout")
                    elif 'error' in result:
                        print(f"    Reason: {result['error']}")
        
        # Group by test file
        print("\n📈 Performance by Test:")
        test_groups = {}
        for result in self.results:
            test_name = result['test']
            if test_name not in test_groups:
                test_groups[test_name] = []
            test_groups[test_name].append(result)
        
        for test_name, results in sorted(test_groups.items()):
            passed_count = sum(1 for r in results if r['success'])
            avg_time = sum(r['elapsed'] for r in results) / len(results)
            print(f"  {test_name}:")
            print(f"    Success: {passed_count}/{len(results)}")
            print(f"    Avg Time: {avg_time:.1f}s")
    
    def save_results(self):
        """Save results to JSON file"""
        filename = f"stress_test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'headless': self.headless,
            'total_tests': len(self.results),
            'passed': sum(1 for r in self.results if r['success']),
            'failed': sum(1 for r in self.results if not r['success']),
            'results': self.results
        }
        
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Results saved to: {filename}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Whisker Stress Test Runner')
    parser.add_argument('--iterations', type=int, default=3, help='Number of iterations (default: 3)')
    parser.add_argument('--headless', action='store_true', help='Run in headless mode (no UI)')
    parser.add_argument('--no-reset', action='store_true', help='Do not reset app between tests')
    parser.add_argument('--single-test', help='Run a single test file only')
    
    args = parser.parse_args()
    
    runner = StressTestRunner(headless=args.headless)
    
    if args.single_test:
        # Run single test
        test_file = args.single_test
        if not os.path.exists(test_file):
            test_file = os.path.join("organized_tests", test_file)
        
        if not os.path.exists(test_file):
            print(f"❌ Test file not found: {args.single_test}")
            sys.exit(1)
        
        for i in range(1, args.iterations + 1):
            if not args.no_reset:
                runner.reset_app()
            runner.run_test(test_file, i)
            if i < args.iterations:
                time.sleep(3)
        
        runner.print_summary(0)
        runner.save_results()
    else:
        # Run full stress test
        runner.run_stress_test(
            iterations=args.iterations,
            reset_between=not args.no_reset
        )


if __name__ == "__main__":
    main()

