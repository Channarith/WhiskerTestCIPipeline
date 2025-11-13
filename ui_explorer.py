#!/usr/bin/env python3
"""
Automated UI Explorer for Whisker App
Discovers all clickable elements and generates comprehensive test cases
"""

import json
import subprocess
import time
import os
from datetime import datetime
from collections import defaultdict

class UIExplorer:
    def __init__(self, app_id="com.whisker.android", platform="android"):
        self.app_id = app_id
        self.platform = platform
        self.maestro_path = os.path.expanduser('~/.maestro/bin/maestro')
        self.visited_elements = set()
        self.screen_states = []
        self.discovered_flows = []
        self.screenshots_dir = f"ui_exploration_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        os.makedirs(self.screenshots_dir, exist_ok=True)
        
    def get_hierarchy(self):
        """Get current UI hierarchy from Maestro"""
        try:
            # Set up Java environment
            env = os.environ.copy()
            env['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
            env['PATH'] = f"{env['JAVA_HOME']}/bin:{env['PATH']}"
            
            result = subprocess.run(
                [self.maestro_path, 'hierarchy'],
                capture_output=True,
                text=True,
                timeout=30,
                env=env
            )
            if result.returncode == 0:
                # Strip "Running on..." line and parse JSON
                output = result.stdout
                lines = output.split('\n')
                # Find the first line that starts with '{'
                json_start = 0
                for i, line in enumerate(lines):
                    if line.strip().startswith('{'):
                        json_start = i
                        break
                json_text = '\n'.join(lines[json_start:])
                return json.loads(json_text)
            return None
        except Exception as e:
            print(f"Error getting hierarchy: {e}")
            return None
    
    def find_clickable_elements(self, hierarchy, parent_path=""):
        """Recursively find all clickable elements"""
        clickable = []
        
        if not hierarchy:
            return clickable
        
        def traverse(node, path=""):
            if isinstance(node, dict):
                # Check if clickable
                attrs = node.get('attributes', {})
                is_clickable = attrs.get('clickable') == 'true'
                
                if is_clickable:
                    element_info = {
                        'text': attrs.get('text', ''),
                        'accessibilityText': attrs.get('accessibilityText', ''),
                        'resource-id': attrs.get('resource-id', ''),
                        'bounds': attrs.get('bounds', ''),
                        'class': attrs.get('class', ''),
                        'path': path
                    }
                    
                    # Create unique identifier
                    identifier = self._create_identifier(element_info)
                    element_info['identifier'] = identifier
                    
                    if identifier not in self.visited_elements:
                        clickable.append(element_info)
                
                # Traverse children
                if 'children' in node:
                    for i, child in enumerate(node['children']):
                        traverse(child, f"{path}/child[{i}]")
            
            elif isinstance(node, list):
                for i, item in enumerate(node):
                    traverse(item, f"{path}/item[{i}]")
        
        traverse(hierarchy)
        return clickable
    
    def _create_identifier(self, element):
        """Create unique identifier for element"""
        text = element.get('text', '').strip()
        acc_text = element.get('accessibilityText', '').strip()
        resource_id = element.get('resource-id', '').strip()
        bounds = element.get('bounds', '')
        
        if text:
            return f"text:{text}"
        elif acc_text:
            return f"acc:{acc_text}"
        elif resource_id:
            return f"id:{resource_id}"
        else:
            return f"bounds:{bounds}"
    
    def take_screenshot(self, name):
        """Take screenshot using Maestro"""
        filename = f"{self.screenshots_dir}/{name}.png"
        try:
            # Use adb for Android
            if self.platform == "android":
                adb_path = os.path.expanduser('~/Library/Android/Sdk/platform-tools/adb')
                subprocess.run(
                    [adb_path, 'exec-out', 'screencap', '-p'],
                    stdout=open(filename, 'wb'),
                    timeout=5
                )
            return filename
        except Exception as e:
            print(f"Screenshot error: {e}")
            return None
    
    def tap_element(self, element):
        """Tap on an element using Maestro"""
        text = element.get('text', '')
        acc_text = element.get('accessibilityText', '')
        resource_id = element.get('resource-id', '')
        
        # Create YAML command
        yaml_cmd = None
        if text:
            yaml_cmd = f'- tapOn: "{text}"'
        elif acc_text:
            yaml_cmd = f'- tapOn: "{acc_text}"'
        elif resource_id:
            yaml_cmd = f'- tapOn:\n    id: {resource_id}'
        else:
            # Use coordinates as fallback
            bounds = element.get('bounds', '')
            if bounds:
                yaml_cmd = f'- tapOn:\n    point: "50%,50%"'
        
        if yaml_cmd:
            # Create temporary flow file
            temp_flow = f"/tmp/maestro_tap_{int(time.time())}.yaml"
            flow_content = f"""appId: {self.app_id}
---
{yaml_cmd}
"""
            with open(temp_flow, 'w') as f:
                f.write(flow_content)
            
            try:
                # Set up Java environment
                env = os.environ.copy()
                env['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
                env['PATH'] = f"{env['JAVA_HOME']}/bin:{env['PATH']}"
                
                result = subprocess.run(
                    [self.maestro_path, 'test', temp_flow],
                    capture_output=True,
                    text=True,
                    timeout=15,
                    env=env
                )
                os.remove(temp_flow)
                return result.returncode == 0
            except Exception as e:
                print(f"Tap error: {e}")
                if os.path.exists(temp_flow):
                    os.remove(temp_flow)
                return False
        
        return False
    
    def go_back(self):
        """Go back using Maestro"""
        temp_flow = f"/tmp/maestro_back_{int(time.time())}.yaml"
        flow_content = f"""appId: {self.app_id}
---
- back
"""
        with open(temp_flow, 'w') as f:
            f.write(flow_content)
        
        try:
            # Set up Java environment
            env = os.environ.copy()
            env['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
            env['PATH'] = f"{env['JAVA_HOME']}/bin:{env['PATH']}"
            
            subprocess.run(
                [self.maestro_path, 'test', temp_flow],
                capture_output=True,
                timeout=10,
                env=env
            )
            os.remove(temp_flow)
            time.sleep(1)
        except Exception as e:
            print(f"Back error: {e}")
            if os.path.exists(temp_flow):
                os.remove(temp_flow)
    
    def explore_screen(self, depth=0, max_depth=3):
        """Recursively explore screens"""
        if depth > max_depth:
            return
        
        print(f"\n{'  ' * depth}📍 Exploring at depth {depth}")
        
        # Get current hierarchy
        hierarchy = self.get_hierarchy()
        if not hierarchy:
            print(f"{'  ' * depth}⚠️  Could not get hierarchy")
            return
        
        # Take screenshot of current state
        screenshot_name = f"screen_depth{depth}_{int(time.time())}"
        self.take_screenshot(screenshot_name)
        
        # Find clickable elements
        clickable = self.find_clickable_elements(hierarchy)
        print(f"{'  ' * depth}🔍 Found {len(clickable)} clickable elements")
        
        # Store screen state
        screen_state = {
            'depth': depth,
            'timestamp': datetime.now().isoformat(),
            'screenshot': screenshot_name,
            'elements': clickable
        }
        self.screen_states.append(screen_state)
        
        # Try clicking each unvisited element
        for i, element in enumerate(clickable):
            identifier = element['identifier']
            
            if identifier in self.visited_elements:
                continue
            
            print(f"{'  ' * depth}👆 [{i+1}/{len(clickable)}] Tapping: {identifier}")
            
            # Mark as visited
            self.visited_elements.add(identifier)
            
            # Tap the element
            success = self.tap_element(element)
            
            if success:
                time.sleep(2)  # Wait for screen transition
                
                # Take screenshot after tap
                after_screenshot = f"after_tap_{identifier.replace(':', '_')[:30]}_{int(time.time())}"
                self.take_screenshot(after_screenshot)
                
                # Record the flow
                flow_record = {
                    'from_screen': screenshot_name,
                    'action': identifier,
                    'to_screen': after_screenshot,
                    'depth': depth,
                    'element': element
                }
                self.discovered_flows.append(flow_record)
                
                # Recursively explore new screen
                if depth < max_depth:
                    self.explore_screen(depth + 1, max_depth)
                
                # Go back
                print(f"{'  ' * depth}⬅️  Going back")
                self.go_back()
                time.sleep(1)
    
    def generate_test_files(self):
        """Generate comprehensive test YAML files from discovered flows"""
        print("\n" + "=" * 60)
        print("📝 Generating Test Files")
        print("=" * 60)
        
        # Group flows by feature/screen
        flows_by_screen = defaultdict(list)
        for flow in self.discovered_flows:
            screen = flow['from_screen']
            flows_by_screen[screen].append(flow)
        
        # Generate master test file
        test_content = f"""appId: {self.app_id}
---
# Auto-generated UI Exploration Tests
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Total screens explored: {len(self.screen_states)}
# Total interactions discovered: {len(self.discovered_flows)}

- waitForAnimationToEnd
- takeScreenshot: "exploration_start"

"""
        
        for screen, flows in flows_by_screen.items():
            test_content += f"\n# Screen: {screen}\n"
            test_content += f"# Discovered {len(flows)} interactions\n\n"
            
            for flow in flows:
                element = flow['element']
                text = element.get('text', '')
                acc_text = element.get('accessibilityText', '')
                resource_id = element.get('resource-id', '')
                
                test_content += f"# Test: {flow['action']}\n"
                
                if text:
                    test_content += f'- tapOn: "{text}"\n'
                elif acc_text:
                    test_content += f'- tapOn: "{acc_text}"\n'
                elif resource_id:
                    test_content += f"- tapOn:\n    id: {resource_id}\n"
                
                test_content += "- waitForAnimationToEnd\n"
                test_content += f"- takeScreenshot: \"{flow['to_screen']}\"\n"
                test_content += "- back\n"
                test_content += "- waitForAnimationToEnd\n\n"
        
        # Save test file
        test_filename = f"generated_exploration_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.yaml"
        with open(test_filename, 'w') as f:
            f.write(test_content)
        
        print(f"✅ Generated: {test_filename}")
        
        # Generate summary report
        report = {
            'timestamp': datetime.now().isoformat(),
            'total_screens': len(self.screen_states),
            'total_interactions': len(self.discovered_flows),
            'visited_elements': list(self.visited_elements),
            'flows': self.discovered_flows,
            'screenshots_dir': self.screenshots_dir
        }
        
        report_filename = f"exploration_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"✅ Generated: {report_filename}")
        print(f"📸 Screenshots saved to: {self.screenshots_dir}/")
        
        return test_filename
    
    def run_exploration(self, max_depth=3):
        """Main exploration entry point"""
        print("🚀 Starting Automated UI Exploration")
        print("=" * 60)
        print(f"App ID: {self.app_id}")
        print(f"Platform: {self.platform}")
        print(f"Max Depth: {max_depth}")
        print("=" * 60)
        
        start_time = time.time()
        
        try:
            self.explore_screen(depth=0, max_depth=max_depth)
        except KeyboardInterrupt:
            print("\n\n⚠️  Exploration interrupted by user")
        
        elapsed = time.time() - start_time
        
        print("\n" + "=" * 60)
        print("📊 Exploration Complete!")
        print("=" * 60)
        print(f"Time elapsed: {elapsed:.1f}s")
        print(f"Screens visited: {len(self.screen_states)}")
        print(f"Elements discovered: {len(self.visited_elements)}")
        print(f"Flows recorded: {len(self.discovered_flows)}")
        
        # Generate test files
        test_file = self.generate_test_files()
        
        return test_file


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Automated UI Explorer for Whisker App')
    parser.add_argument('--app-id', default='com.whisker.android', help='App package/bundle ID')
    parser.add_argument('--platform', choices=['android', 'ios'], default='android', help='Platform')
    parser.add_argument('--max-depth', type=int, default=3, help='Maximum exploration depth')
    
    args = parser.parse_args()
    
    explorer = UIExplorer(app_id=args.app_id, platform=args.platform)
    explorer.run_exploration(max_depth=args.max_depth)


if __name__ == "__main__":
    main()
