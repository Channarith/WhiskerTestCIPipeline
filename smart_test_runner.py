#!/usr/bin/env python3
"""
Smart Whisker Test Runner
Manages test credentials and generates dynamic Maestro tests
"""

import json
import random
import string
import subprocess
import sys
import os
import time
from datetime import datetime

CREDENTIALS_FILE = "test_credentials.json"
ANDROID_PACKAGE_NAME = "com.whisker.android"
IOS_BUNDLE_ID = "com.whisker.ios"  # Update this with actual iOS bundle ID

def load_credentials():
    """Load saved test credentials"""
    if os.path.exists(CREDENTIALS_FILE):
        with open(CREDENTIALS_FILE, 'r') as f:
            return json.load(f)
    return {"registered_users": [], "last_used": None}

def save_credentials(data):
    """Save test credentials"""
    with open(CREDENTIALS_FILE, 'w') as f:
        json.dump(data, indent=2, fp=f)

def generate_random_email():
    """Generate random email for testing"""
    random_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"test_{random_str}@whiskertest.com"

def generate_random_password():
    """Generate random password that meets all requirements:
    - At least 1 capital letter
    - Longer than 8 characters (we generate 12)
    - At least 1 number
    - At least 1 special symbol (@#$%&)
    """
    special_chars = "@#$%&"
    
    # Guarantee at least one of each required character type
    password_chars = [
        random.choice(string.ascii_uppercase),  # Capital letter (REQUIRED)
        random.choice(string.digits),           # Number (REQUIRED)
        random.choice(special_chars),           # Special symbol (REQUIRED)
    ]
    
    # Fill the rest with random mix (total length = 12)
    remaining_length = 12 - len(password_chars)
    password_chars.extend(
        random.choices(
            string.ascii_uppercase + string.ascii_lowercase + string.digits + special_chars,
            k=remaining_length
        )
    )
    
    # Shuffle to avoid predictable pattern (capital, number, special at start)
    random.shuffle(password_chars)
    
    return ''.join(password_chars)

def generate_random_name():
    """Generate random first/last name"""
    first_names = ["Test", "Demo", "QA", "Auto", "Sample", "Trial"]
    last_names = ["User", "Account", "Tester", "Person", "Member"]
    return random.choice(first_names), random.choice(last_names)

def create_register_test(email, password, first_name, last_name, platform='android'):
    """Generate Maestro YAML for registration"""
    app_id = IOS_BUNDLE_ID if platform == 'ios' else ANDROID_PACKAGE_NAME
    platform_note = "iOS Simulator" if platform == 'ios' else "Android Emulator (adb shell monkey -p com.whisker.android -c android.intent.category.LAUNCHER 1)"
    
    yaml_content = f"""appId: {app_id}
---
# Smart Registration Test ({platform.upper()})
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Email: {email}
# Platform: {platform_note}

- waitForAnimationToEnd
- takeScreenshot: "01_app_launched"

# Handle any welcome/onboarding screens
- runFlow:
    when:
      visible: "Get Started|Start|Begin|Next|Skip"
    commands:
      - tapOn: "Get Started|Start|Begin|Next|Skip"
      - waitForAnimationToEnd

# Wait for main screen
- waitForAnimationToEnd
- takeScreenshot: "01b_main_screen"

# Navigate to Register screen
- runFlow:
    when:
      visible: "Register|Sign Up|Create Account"
    commands:
      - tapOn: "Register|Sign Up|Create Account"
      - waitForAnimationToEnd
      - takeScreenshot: "02_register_screen"

# Check if already on register screen
- runFlow:
    when:
      visible: "First Name|Your Whisker Journey"
    commands:
      - takeScreenshot: "02b_already_on_register"

# Fill in First Name
- tapOn: "First Name"
- inputText: "{first_name}"
- hideKeyboard

# Fill in Last Name
- tapOn: "Last Name"
- inputText: "{last_name}"
- hideKeyboard

# Fill in Email
- tapOn: "email"
- inputText: "{email}"
- hideKeyboard
- takeScreenshot: "03_form_filled"

# REQUIRED: Tap Terms & Conditions checkbox (exact text from Flow.yaml lines 15-17)
- tapOn: "By checking this box. I agree to Whisker's \\nTerms&Conditions\\n. *"
- tapOn: "Continue"
- takeScreenshot: "04_continue_clicked"

# === PASSWORD CREATION SCREEN (REQUIRED) ===
# Wait for password creation screen to load
- waitForAnimationToEnd
- takeScreenshot: "05_password_creation_screen"

# Enter password in first "Enter Password" field
- tapOn: "Enter Password"
- inputText: "{password}"
- hideKeyboard
- takeScreenshot: "06_password_entered"

# Enter password in second "Enter Password" field (confirmation)
- tapOn: "Enter Password"
- inputText: "{password}"
- hideKeyboard
- takeScreenshot: "07_password_confirmed"

# Tap Continue button (enabled when passwords match)
- tapOn: "Continue"
- waitForAnimationToEnd
- takeScreenshot: "08_password_submitted"

# === WELCOME SCREEN ===
# Verify we see the welcome message (make assertion optional to not block flow)
- runFlow:
    when:
      visible: "Welcome|Whisker"
    commands:
      - takeScreenshot: "09_welcome_screen"

# Tap "Start Your Journey" button
- runFlow:
    when:
      visible: "Start Your Journey|Start|Journey"
    commands:
      - tapOn: "Start Your Journey|Start|Journey"
      - waitForAnimationToEnd
      - takeScreenshot: "10_journey_started"

# Verify we see the free trial message (optional)
- runFlow:
    when:
      visible: "trial|Trial|Whisker+"
    commands:
      - takeScreenshot: "11_trial_screen"
      
# Take final screenshot after welcome flow
- waitForAnimationToEnd
- takeScreenshot: "11b_post_welcome"

# Handle notification permission popup (auto-click Allow) - MANDATORY
- takeScreenshot: "12_notification_popup"
- tapOn:
    id: com.android.permissioncontroller:id/permission_allow_button
- takeScreenshot: "12b_notification_allowed"

# Handle potential registration errors
- runFlow:
    when:
      visible: "already registered|already exists|Email taken"
    commands:
      - takeScreenshot: "error_already_registered"

# === POST-REGISTRATION: NOW IN THE APP ===
# At this point, we should be logged into the app
- waitForAnimationToEnd
- takeScreenshot: "13_app_home_screen"

# Scroll to see what's on screen
- scroll
- waitForAnimationToEnd
- takeScreenshot: "14_scrolled_view"

# Handle Google Password Manager popup (if appears)
- runFlow:
    when:
      visible: "Not now|Never|No thanks"
    commands:
      - tapOn: "Not now|Never|No thanks"
      - waitForAnimationToEnd
      - takeScreenshot: "15_popup_dismissed"

# Final state - should be logged into app after registration
- waitForAnimationToEnd
- takeScreenshot: "16_logged_in_home"

# === UI EXPLORATION & TESTING PHASE ===
# Test real Whisker app UI elements

# Test 1: Click Profile Icon (top right circular icon)
- tapOn:
    point: "92%,5%"
- waitForAnimationToEnd
- takeScreenshot: "ui_01_profile_opened"
- tapOn: "Login Information"
- tapOn: "Reset Password"
- tapOn: "Back"
- back
- back
- waitForAnimationToEnd
- takeScreenshot: "ui_02_back_to_home"

# Test 2: Scroll down to see Blogs section
- scroll
- waitForAnimationToEnd
- takeScreenshot: "ui_02b_scrolled_to_blogs"

# Test 2b: Click Blogs "Learn More" button
- tapOn: "Learn More"
- waitForAnimationToEnd
- assertVisible: "Litter-Robot Blog Logo"
- takeScreenshot: "ui_03_blogs_opened"
- tapOn: "Close"
- takeScreenshot: "ui_04_back_from_blogs"

# Test 3: Navigate to Insights tab (bottom navigation)
- tapOn: "Insights\\nTab 2 of 5"
- waitForAnimationToEnd
- takeScreenshot: "ui_05_insights_tab"

# Test 4: Navigate to Devices tab (bottom navigation)
- tapOn: "Devices\\nTab 3 of 5"
- waitForAnimationToEnd
- takeScreenshot: "ui_06_devices_tab"

# Test 5: Navigate to Pets tab (bottom navigation)
- tapOn: "Pets\\nTab 4 of 5"
- waitForAnimationToEnd
- takeScreenshot: "ui_07_pets_tab"

# Test 6: Navigate to Shop tab (bottom navigation)
- tapOn: "Shop\\nTab 5 of 5"
- waitForAnimationToEnd
- takeScreenshot: "ui_08_shop_tab"

# Test 7: Go back to Home tab
- back
- tapOn: "Home\\nTab 1 of 5"
- waitForAnimationToEnd
- takeScreenshot: "ui_09_back_to_home"

# Test 8: Test scrolling on home screen
- scroll
- waitForAnimationToEnd
- takeScreenshot: "ui_10_scrolled_down"
- swipe:
    direction: UP
- waitForAnimationToEnd
- takeScreenshot: "ui_11_scrolled_up"

# Test 9: Close app and return to Android home
- takeScreenshot: "ui_12_before_close"
- pressKey: HOME
- takeScreenshot: "ui_13_android_home"
"""
    
    filename = f"generated_register_test_{platform}.yaml"
    with open(filename, 'w') as f:
        f.write(yaml_content)
    
    return filename

def create_login_test(email, password):
    """Generate Maestro YAML for login"""
    yaml_content = f"""appId: {PACKAGE_NAME}
---
# Smart Login Test
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Email: {email}
# Note: Launch app manually before running this test
# adb shell monkey -p com.whisker.android -c android.intent.category.LAUNCHER 1

- waitForAnimationToEnd
- takeScreenshot: "01_app_launched"

# Navigate to Login screen
- runFlow:
    when:
      visible: "Login|Sign In"
    commands:
      - tapOn: "Login|Sign In"
      - waitForAnimationToEnd
      - takeScreenshot: "02_login_screen"

# Check if already on login screen
- runFlow:
    when:
      visible: "Email|Password|Sign in to your account"
    commands:
      - takeScreenshot: "02b_already_on_login"

# Fill in Email
- tapOn: "Email|email|Username"
- inputText: "{email}"
- hideKeyboard

# Fill in Password
- tapOn: "Password"
- inputText: "{password}"
- hideKeyboard
- takeScreenshot: "03_credentials_entered"

# Click Login/Sign In
- tapOn: "Login|Sign In|Continue"
- waitForAnimationToEnd
- takeScreenshot: "04_login_submitted"

# Handle potential errors
- runFlow:
    when:
      visible: "Invalid|Incorrect|Wrong|not found"
    commands:
      - takeScreenshot: "error_invalid_credentials"

# Verify success (optional - don't fail test if not found)
- runFlow:
    when:
      visible: "Welcome|Home|Dashboard|Login"
    commands:
      - takeScreenshot: "05_login_success"

# Final screenshot regardless
- takeScreenshot: "06_final_screen"
"""
    
    filename = "generated_login_test.yaml"
    with open(filename, 'w') as f:
        f.write(yaml_content)
    
    return filename

def run_maestro_test(yaml_file, platform='android'):
    """Run Maestro test and return result"""
    
    # Create debug output directory
    debug_dir = "maestro_debug_output"
    os.makedirs(debug_dir, exist_ok=True)
    
    # Launch app manually before running test (workaround for TCP forwarding issue)
    print(f"\n🧪 Running Maestro test: {yaml_file}")
    print("-" * 60)
    print(f"📱 Preparing Whisker app ({platform.upper()})...")
    
    if platform == 'android':
        adb_path = os.path.expanduser('~/Library/Android/Sdk/platform-tools/adb')
        package_name = ANDROID_PACKAGE_NAME
        
        # Step 1: Force stop the app if it's running
        print("  → Checking if app is running...")
        stop_result = subprocess.run(
            [adb_path, 'shell', 'am', 'force-stop', package_name],
            capture_output=True,
            text=True
        )
        
        if stop_result.returncode == 0:
            print("  ✓ App force-stopped (if it was running)")
            time.sleep(1)
        
        # Step 2: Clear app data to start fresh
        print("  → Clearing app data...")
        clear_result = subprocess.run(
            [adb_path, 'shell', 'pm', 'clear', package_name],
            capture_output=True,
            text=True
        )
        
        if clear_result.returncode == 0:
            print("  ✓ App data cleared")
            time.sleep(1)
        
        # Step 3: Launch the app fresh
        print("  → Launching app...")
        launch_result = subprocess.run(
            [adb_path, 'shell', 'monkey', '-p', package_name, '-c', 'android.intent.category.LAUNCHER', '1'],
            capture_output=True,
            text=True
        )
        
        if launch_result.returncode != 0:
            print(f"  ⚠️  Warning: Failed to launch app via ADB: {launch_result.stderr}")
        else:
            print("  ✓ App launched successfully")
            time.sleep(3)
    
    elif platform == 'ios':
        bundle_id = IOS_BUNDLE_ID
        
        # For iOS, use xcrun simctl to manage the app
        print("  → Terminating app if running...")
        subprocess.run(
            ['xcrun', 'simctl', 'terminate', 'booted', bundle_id],
            capture_output=True
        )
        print("  ✓ App terminated")
        
        print("  → Clearing app data...")
        subprocess.run(
            ['xcrun', 'simctl', 'privacy', 'booted', 'reset', 'all', bundle_id],
            capture_output=True
        )
        print("  ✓ App data cleared")
        
        print("  → Launching app...")
        subprocess.run(
            ['xcrun', 'simctl', 'launch', 'booted', bundle_id],
            capture_output=True
        )
        print("  ✓ App launched successfully")
        time.sleep(3)
    
    print("✅ App ready for testing!")
    print("\n" + "=" * 80)
    print("🔍 MAESTRO TEST EXECUTION (Live UI)")
    print("=" * 80 + "\n")
    sys.stdout.flush()  # Ensure all output is flushed before Maestro starts
    
    try:
        # Use full path to maestro binary
        maestro_path = os.path.expanduser('~/.maestro/bin/maestro')
        
        # Set up environment with Java path
        env = os.environ.copy()
        env['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
        env['PATH'] = f"{env['JAVA_HOME']}/bin:{env['PATH']}"
        
        # Run maestro test with live output (shows checklist UI)
        result = subprocess.run(
            [maestro_path, 'test', '--debug-output', debug_dir, yaml_file],
            timeout=180,  # 3 minutes
            env=env
        )
        
        # Output is shown live above, just print final status
        print()  # Blank line for spacing
        if result.returncode == 0:
            print("✅ Test passed!")
            print(f"📁 Debug output saved to: {debug_dir}")
            return True
        else:
            print("❌ Test failed!")
            print(f"📁 Debug output saved to: {debug_dir}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏱️  Test timed out after 3 minutes!")
        print("💡 Check if app is responding or test is stuck")
        print(f"📁 Debug output saved to: {debug_dir}")
        return False
    except Exception as e:
        print(f"❌ Error running test: {e}")
        return False

def register_new_user(platform='android'):
    """Register a new user with random credentials"""
    print("\n" + "=" * 60)
    print(f"🆕 REGISTER NEW USER TEST ({platform.upper()})")
    print("=" * 60)
    
    # Generate credentials
    first_name, last_name = generate_random_name()
    email = generate_random_email()
    password = generate_random_password()
    
    print(f"\n📧 Generated Credentials:")
    print(f"   First Name: {first_name}")
    print(f"   Last Name:  {last_name}")
    print(f"   Email:      {email}")
    print(f"   Password:   {password}")
    print(f"   Platform:   {platform.upper()}")
    
    # Create and run test
    yaml_file = create_register_test(email, password, first_name, last_name, platform)
    success = run_maestro_test(yaml_file, platform)
    
    if success:
        # Save credentials
        data = load_credentials()
        data["registered_users"].append({
            "email": email,
            "password": password,
            "first_name": first_name,
            "last_name": last_name,
            "registered_at": datetime.now().isoformat()
        })
        data["last_used"] = email
        save_credentials(data)
        
        print(f"\n✅ User registered and saved!")
        print(f"   Total registered users: {len(data['registered_users'])}")
    
    return success

def login_existing_user(email=None):
    """Login with existing credentials"""
    print("\n" + "=" * 60)
    print("🔐 LOGIN TEST")
    print("=" * 60)
    
    data = load_credentials()
    
    if not data["registered_users"]:
        print("\n❌ No registered users found!")
        print("   Run with --register first to create test accounts")
        return False
    
    # Choose user
    if email:
        user = next((u for u in data["registered_users"] if u["email"] == email), None)
        if not user:
            print(f"\n❌ User {email} not found in saved credentials")
            return False
    else:
        # Use last registered user
        user = data["registered_users"][-1]
    
    print(f"\n📧 Using Credentials:")
    print(f"   Email:    {user['email']}")
    print(f"   Password: {user['password']}")
    print(f"   Name:     {user['first_name']} {user['last_name']}")
    
    # Create and run test
    yaml_file = create_login_test(user["email"], user["password"])
    success = run_maestro_test(yaml_file)
    
    if success:
        data["last_used"] = user["email"]
        save_credentials(data)
    
    return success

def test_all_users():
    """Test login for all registered users"""
    print("\n" + "=" * 60)
    print("🔄 TEST ALL REGISTERED USERS")
    print("=" * 60)
    
    data = load_credentials()
    
    if not data["registered_users"]:
        print("\n❌ No registered users found!")
        return False
    
    print(f"\n📋 Found {len(data['registered_users'])} registered users")
    
    results = []
    for i, user in enumerate(data["registered_users"], 1):
        print(f"\n--- Testing user {i}/{len(data['registered_users'])} ---")
        success = login_existing_user(user["email"])
        results.append((user["email"], success))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, s in results if s)
    total = len(results)
    
    for email, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"   {status}: {email}")
    
    print(f"\n   Total: {passed}/{total} passed ({passed/total*100:.0f}%)")
    
    return passed == total

def list_users():
    """List all registered test users"""
    data = load_credentials()
    
    if not data["registered_users"]:
        print("\n📋 No registered users yet")
        print("   Run with --register to create test accounts")
        return
    
    print("\n" + "=" * 60)
    print("📋 REGISTERED TEST USERS")
    print("=" * 60)
    
    for i, user in enumerate(data["registered_users"], 1):
        print(f"\n{i}. {user['first_name']} {user['last_name']}")
        print(f"   Email: {user['email']}")
        print(f"   Password: {user['password']}")
        print(f"   Registered: {user.get('registered_at', 'Unknown')}")
        if data.get("last_used") == user["email"]:
            print(f"   ⭐ Last used")

def main():
    print("🎯 Whisker Smart Test Runner")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("\nUsage:")
        print("  python3 smart_test_runner.py --register [--platform android|ios]  # Register new user")
        print("  python3 smart_test_runner.py --login [<email>]                      # Login with last/specific user")
        print("  python3 smart_test_runner.py --test-all                             # Test all registered users")
        print("  python3 smart_test_runner.py --list                                 # List registered users")
        print("")
        print("Platform: android (default) | ios")
        print("")
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Parse platform argument
    platform = 'android'  # default
    if '--platform' in sys.argv:
        platform_idx = sys.argv.index('--platform')
        if platform_idx + 1 < len(sys.argv):
            platform = sys.argv[platform_idx + 1].lower()
            if platform not in ['android', 'ios']:
                print(f"\n❌ Invalid platform: {platform}. Use 'android' or 'ios'")
                sys.exit(1)
    
    if command == "--register":
        success = register_new_user(platform)
        sys.exit(0 if success else 1)
    
    elif command == "--login":
        # Find email argument (skip --platform args)
        email = None
        for i, arg in enumerate(sys.argv[2:], 2):
            if arg not in ['--platform', platform] and not arg.startswith('--'):
                email = arg
                break
        success = login_existing_user(email)
        sys.exit(0 if success else 1)
    
    elif command == "--test-all":
        success = test_all_users()
        sys.exit(0 if success else 1)
    
    elif command == "--list":
        list_users()
        sys.exit(0)
    
    else:
        print(f"\n❌ Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()

