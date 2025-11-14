#!/usr/bin/env python3
"""
Whisker API Test Runner
Tests backend APIs for authentication, data, and services
"""

import requests
import json
import time
from datetime import datetime
import os

class WhiskerAPITester:
    def __init__(self, base_url="https://api.whisker.com", env="production"):
        self.base_url = base_url
        self.env = env
        self.session = requests.Session()
        self.auth_token = None
        self.test_results = []
        
        # API endpoints (update these with actual Whisker API endpoints)
        self.endpoints = {
            'auth_login': '/api/v1/auth/login',
            'auth_register': '/api/v1/auth/register',
            'auth_refresh': '/api/v1/auth/refresh',
            'user_profile': '/api/v1/user/profile',
            'pets_list': '/api/v1/pets',
            'pets_create': '/api/v1/pets',
            'devices_list': '/api/v1/devices',
            'devices_status': '/api/v1/devices/{device_id}/status',
            'insights_activity': '/api/v1/insights/activity',
            'insights_health': '/api/v1/insights/health',
            'shop_products': '/api/v1/shop/products',
            'shop_cart': '/api/v1/shop/cart',
        }
    
    def load_test_credentials(self):
        """Load test credentials from test_credentials.json"""
        if os.path.exists('test_credentials.json'):
            with open('test_credentials.json', 'r') as f:
                data = json.load(f)
                if data.get('registered_users'):
                    return data['registered_users'][0]  # Use first user
        return None
    
    def test_api(self, method, endpoint, data=None, headers=None, expected_status=200):
        """Generic API test method"""
        url = f"{self.base_url}{endpoint}"
        test_name = f"{method} {endpoint}"
        
        print(f"\n🧪 Testing: {test_name}")
        
        start_time = time.time()
        
        try:
            if headers is None:
                headers = {}
            
            if self.auth_token:
                headers['Authorization'] = f'Bearer {self.auth_token}'
            
            headers['Content-Type'] = 'application/json'
            
            if method == 'GET':
                response = self.session.get(url, headers=headers, timeout=10)
            elif method == 'POST':
                response = self.session.post(url, json=data, headers=headers, timeout=10)
            elif method == 'PUT':
                response = self.session.put(url, json=data, headers=headers, timeout=10)
            elif method == 'DELETE':
                response = self.session.delete(url, headers=headers, timeout=10)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            elapsed = time.time() - start_time
            success = response.status_code == expected_status
            
            result = {
                'test': test_name,
                'method': method,
                'endpoint': endpoint,
                'status_code': response.status_code,
                'expected_status': expected_status,
                'success': success,
                'response_time': elapsed,
                'timestamp': datetime.now().isoformat()
            }
            
            if success:
                print(f"✅ PASS - Status: {response.status_code}, Time: {elapsed:.3f}s")
                try:
                    result['response_data'] = response.json()
                except:
                    result['response_data'] = response.text[:200]
            else:
                print(f"❌ FAIL - Expected: {expected_status}, Got: {response.status_code}")
                result['error'] = response.text[:200]
            
            self.test_results.append(result)
            return success, response
            
        except requests.exceptions.Timeout:
            elapsed = time.time() - start_time
            print(f"⏱️  TIMEOUT after {elapsed:.3f}s")
            self.test_results.append({
                'test': test_name,
                'success': False,
                'error': 'Timeout',
                'response_time': elapsed,
                'timestamp': datetime.now().isoformat()
            })
            return False, None
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"❌ ERROR: {str(e)}")
            self.test_results.append({
                'test': test_name,
                'success': False,
                'error': str(e),
                'response_time': elapsed,
                'timestamp': datetime.now().isoformat()
            })
            return False, None
    
    def test_authentication(self):
        """Test authentication endpoints"""
        print("\n" + "="*60)
        print("🔐 AUTHENTICATION API TESTS")
        print("="*60)
        
        creds = self.load_test_credentials()
        if not creds:
            print("⚠️  No test credentials found. Skipping auth tests.")
            return False
        
        # Test login
        login_data = {
            'email': creds['email'],
            'password': creds['password']
        }
        
        success, response = self.test_api(
            'POST', 
            self.endpoints['auth_login'], 
            data=login_data,
            expected_status=200
        )
        
        if success and response:
            try:
                data = response.json()
                self.auth_token = data.get('token') or data.get('access_token')
                print(f"🔑 Auth token obtained: {self.auth_token[:20]}..." if self.auth_token else "⚠️  No token in response")
            except:
                pass
        
        return success
    
    def test_user_endpoints(self):
        """Test user-related endpoints"""
        print("\n" + "="*60)
        print("👤 USER API TESTS")
        print("="*60)
        
        if not self.auth_token:
            print("⚠️  No auth token. Skipping user tests.")
            return
        
        # Get user profile
        self.test_api('GET', self.endpoints['user_profile'])
    
    def test_pets_endpoints(self):
        """Test pets-related endpoints"""
        print("\n" + "="*60)
        print("🐾 PETS API TESTS")
        print("="*60)
        
        if not self.auth_token:
            print("⚠️  No auth token. Skipping pets tests.")
            return
        
        # List pets
        self.test_api('GET', self.endpoints['pets_list'])
        
        # Create pet (test data)
        pet_data = {
            'name': 'API Test Dog',
            'species': 'dog',
            'breed': 'Labrador',
            'birth_date': '2020-01-01'
        }
        self.test_api('POST', self.endpoints['pets_create'], data=pet_data, expected_status=201)
    
    def test_devices_endpoints(self):
        """Test devices-related endpoints"""
        print("\n" + "="*60)
        print("📱 DEVICES API TESTS")
        print("="*60)
        
        if not self.auth_token:
            print("⚠️  No auth token. Skipping devices tests.")
            return
        
        # List devices
        self.test_api('GET', self.endpoints['devices_list'])
    
    def test_insights_endpoints(self):
        """Test insights/analytics endpoints"""
        print("\n" + "="*60)
        print("📊 INSIGHTS API TESTS")
        print("="*60)
        
        if not self.auth_token:
            print("⚠️  No auth token. Skipping insights tests.")
            return
        
        # Get activity insights
        self.test_api('GET', self.endpoints['insights_activity'])
        
        # Get health insights
        self.test_api('GET', self.endpoints['insights_health'])
    
    def test_shop_endpoints(self):
        """Test shop/commerce endpoints"""
        print("\n" + "="*60)
        print("🛒 SHOP API TESTS")
        print("="*60)
        
        # Products don't necessarily need auth
        self.test_api('GET', self.endpoints['shop_products'])
        
        if self.auth_token:
            # Get cart (requires auth)
            self.test_api('GET', self.endpoints['shop_cart'])
    
    def run_all_tests(self):
        """Run complete API test suite"""
        print("\n" + "🚀"*30)
        print("🚀 WHISKER API TEST SUITE")
        print("🚀"*30)
        print(f"Base URL: {self.base_url}")
        print(f"Environment: {self.env}")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        start_time = time.time()
        
        # Run all test categories
        self.test_authentication()
        self.test_user_endpoints()
        self.test_pets_endpoints()
        self.test_devices_endpoints()
        self.test_insights_endpoints()
        self.test_shop_endpoints()
        
        elapsed = time.time() - start_time
        
        # Print summary
        self.print_summary(elapsed)
        
        # Save results
        self.save_results()
    
    def print_summary(self, total_time):
        """Print test summary"""
        print("\n" + "="*60)
        print("📊 API TEST SUMMARY")
        print("="*60)
        
        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r['success'])
        failed = total - passed
        
        print(f"\nTotal Tests: {total}")
        print(f"✅ Passed: {passed} ({passed/total*100:.1f}%)" if total > 0 else "✅ Passed: 0")
        print(f"❌ Failed: {failed} ({failed/total*100:.1f}%)" if total > 0 else "❌ Failed: 0")
        print(f"⏱️  Total Time: {total_time:.2f}s")
        
        if self.test_results:
            avg_time = sum(r.get('response_time', 0) for r in self.test_results) / total
            print(f"📈 Avg Response Time: {avg_time:.3f}s")
        
        if failed > 0:
            print("\n❌ Failed Tests:")
            for result in self.test_results:
                if not result['success']:
                    print(f"  - {result['test']}")
                    if 'error' in result:
                        print(f"    Error: {result['error'][:100]}")
    
    def save_results(self):
        """Save results to JSON"""
        filename = f"api_test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'base_url': self.base_url,
            'environment': self.env,
            'total_tests': len(self.test_results),
            'passed': sum(1 for r in self.test_results if r['success']),
            'failed': sum(1 for r in self.test_results if not r['success']),
            'results': self.test_results
        }
        
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Results saved to: {filename}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Whisker API Test Runner')
    parser.add_argument('--base-url', default='https://api.whisker.com', help='API base URL')
    parser.add_argument('--env', default='production', choices=['production', 'staging', 'dev'], help='Environment')
    parser.add_argument('--test', choices=['auth', 'user', 'pets', 'devices', 'insights', 'shop'], help='Run specific test category')
    
    args = parser.parse_args()
    
    tester = WhiskerAPITester(base_url=args.base_url, env=args.env)
    
    if args.test:
        # Run specific test category
        if args.test == 'auth':
            tester.test_authentication()
        elif args.test == 'user':
            tester.test_authentication()  # Get token first
            tester.test_user_endpoints()
        elif args.test == 'pets':
            tester.test_authentication()
            tester.test_pets_endpoints()
        elif args.test == 'devices':
            tester.test_authentication()
            tester.test_devices_endpoints()
        elif args.test == 'insights':
            tester.test_authentication()
            tester.test_insights_endpoints()
        elif args.test == 'shop':
            tester.test_shop_endpoints()
        
        tester.print_summary(0)
        tester.save_results()
    else:
        # Run all tests
        tester.run_all_tests()


if __name__ == "__main__":
    main()

