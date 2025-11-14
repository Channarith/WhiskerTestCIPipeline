#!/usr/bin/env python3
"""
Prepare Logout/Login Test with Saved Credentials
Injects actual credentials from test_credentials.json into the test file
"""

import json
import os

def load_credentials():
    """Load saved test credentials"""
    if os.path.exists('test_credentials.json'):
        with open('test_credentials.json', 'r') as f:
            return json.load(f)
    return None

def prepare_logout_login_test():
    """Replace placeholders with actual credentials"""
    # Load credentials
    creds = load_credentials()
    if not creds or not creds.get('registered_users'):
        print("❌ No saved credentials found!")
        print("   Run: python3 smart_test_runner.py --register")
        return False
    
    # Get last used credential
    last_user = None
    if creds.get('last_used'):
        for user in creds['registered_users']:
            if user['email'] == creds['last_used']:
                last_user = user
                break
    
    if not last_user:
        last_user = creds['registered_users'][-1]  # Use most recent
    
    print(f"\n📧 Using credentials:")
    print(f"   Email: {last_user['email']}")
    print(f"   Name: {last_user['first_name']} {last_user['last_name']}")
    
    # Read template
    template_file = 'tests/organized/06_logout_login_tests.yaml'
    if not os.path.exists(template_file):
        print(f"❌ Template file not found: {template_file}")
        return False
    
    with open(template_file, 'r') as f:
        content = f.read()
    
    # Replace placeholders - handle both formats (with and without quotes)
    # IMPORTANT: Do the longer pattern FIRST to avoid double-quote issues!
    
    # Format 2 FIRST: "{SAVED_EMAIL}" (already has quotes in template)
    # This handles cases like: inputText: "{SAVED_EMAIL}"
    # We replace the whole thing including the quotes to maintain one set of quotes
    content = content.replace('"{SAVED_EMAIL}"', f'"{last_user["email"]}"')
    content = content.replace('"{SAVED_PASSWORD}"', f'"{last_user["password"]}"')
    
    # Format 1 SECOND: {SAVED_EMAIL} (no quotes in template)
    # This handles cases like: inputText: {SAVED_EMAIL}
    # We add quotes for YAML safety (protects special characters)
    content = content.replace('{SAVED_EMAIL}', f'"{last_user["email"]}"')
    content = content.replace('{SAVED_PASSWORD}', f'"{last_user["password"]}"')
    
    # Save prepared test
    output_file = 'tests/organized/06_logout_login_tests_prepared.yaml'
    with open(output_file, 'w') as f:
        f.write(content)
    
    print(f"\n✅ Prepared test file: {output_file}")
    print(f"\nRun with:")
    print(f"  ~/.maestro/bin/maestro test {output_file}")
    
    return True

if __name__ == "__main__":
    prepare_logout_login_test()

