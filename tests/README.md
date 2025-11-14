# Whisker Tests Directory

This directory contains all automated tests for the Whisker application, organized by category.

## 📁 Directory Structure

```
tests/
├── organized/          # Main test suite (Profile, Pets, Shop, Devices, Insights, Logout)
├── standalone/         # Individual feature tests
├── registration/       # Registration and login flow tests (generated)
└── README.md          # This file
```

---

## 🎯 Test Categories

### **organized/** - Main Test Suite

Comprehensive, well-organized tests for core app features. Each test starts with clean state initialization and automatic login.

#### `01_profile_account_tests.yaml`
**Profile & Account Management**
- ✅ Navigate to profile section (top-right circular icon)
- ✅ View account information (name, email)
- ✅ Test address management features
- ✅ Verify payment methods section
- ✅ Navigate through settings and preferences
- ✅ Explore support and help sections
- 📸 **Screenshots**: ~20 steps
- ⏱️ **Runtime**: ~3-4 minutes

#### `02_pet_management_tests.yaml`
**Pet Profile Creation & Management**
- ✅ Navigate to Pets tab
- ✅ Create Dog profile with full setup workflow
  - Name, breed, weight, age
  - Health information
  - Activity preferences
- ✅ Create Cat profile with complete details
  - Multiple cats support
  - Litter preferences
  - Feeding schedules
- ✅ Verify pet profile viewing and editing
- 📸 **Screenshots**: ~45 steps
- ⏱️ **Runtime**: ~6-8 minutes

#### `03_shop_commerce_tests.yaml`
**E-Commerce & Shopping Features**
- ✅ Handle cookie consent popup
- ✅ Browse product catalog
- ✅ Navigate product categories
  - Litter-Robot products
  - Feeder-Robot products
  - Accessories
- ✅ Add items to shopping cart
- ✅ Test search functionality
- ✅ View product details
- 📸 **Screenshots**: ~25 steps
- ⏱️ **Runtime**: ~4-5 minutes

#### `04_device_management_tests.yaml`
**Smart Device Setup & Configuration**
- ✅ Navigate to Devices tab
- ✅ Litter-Robot pairing process
  - WiFi setup workflow
  - Device configuration
  - Settings customization
- ✅ Feeder-Robot setup
  - Portion control settings
  - Feeding schedule
  - Notifications
- ✅ Device status monitoring
- ✅ Troubleshooting options
- 📸 **Screenshots**: ~30 steps
- ⏱️ **Runtime**: ~5-6 minutes

#### `05_insights_analytics_tests.yaml`
**Pet Health & Activity Analytics**
- ✅ Navigate to Insights tab
- ✅ View activity dashboard
  - Daily activity trends
  - Weekly summaries
  - Monthly reports
- ✅ Health metrics visualization
  - Weight tracking
  - Litter box usage patterns
  - Feeding habits
- ✅ Data filtering and date ranges
- ✅ Export reports functionality
- 📸 **Screenshots**: ~35 steps
- ⏱️ **Runtime**: ~5-7 minutes

#### `06_logout_login_tests.yaml`
**Authentication & Session Management**
- ✅ Complete logout flow
  - Navigate to profile
  - Click user name/email
  - Tap "Log Out" button (orange)
  - Confirm logout
- ✅ Fresh login with saved credentials
  - Handle Google Password Manager popup
  - Handle notification permissions
- ✅ Session persistence verification
- ✅ Return to home screen
- 📸 **Screenshots**: ~15 steps
- ⏱️ **Runtime**: ~2-3 minutes

### **standalone/** - Individual Tests

Specific feature tests and experiments for isolated testing scenarios.

#### `whisker_ui_test.yaml`
**Basic UI Navigation Test**
- ✅ Simple navigation flows
- ✅ Tab switching verification
- ✅ Basic element interaction
- ⏱️ **Runtime**: ~1-2 minutes

#### `whisker_stress_test.yaml`
**Stress & Load Testing**
- ✅ Rapid navigation between screens
- ✅ Multiple tap sequences
- ✅ Performance under load
- ✅ Memory leak detection
- ⏱️ **Runtime**: ~2-3 minutes

#### `whisker_recording_test1.yaml`
**Recorded Test Session**
- ✅ Real user interaction playback
- ✅ Manual test case automation
- ✅ Custom workflow validation
- ⏱️ **Runtime**: Variable

### **registration/** - Dynamic Tests

Auto-generated tests from `smart_test_runner.py` with dynamic credential management.

#### `generated_register_test_android.yaml`
**User Registration Flow**
- ✅ Random credential generation (email, password)
- ✅ Password requirements validation
  - Capital letter
  - 8+ characters
  - Number
  - Special symbol (@, #, $, %, or &)
- ✅ Terms & Conditions acceptance
- ✅ Welcome screen navigation
- ✅ Notification permissions
- ✅ Full UI exploration after registration
- 💾 **Saves credentials** to `test_credentials.json`
- ⏱️ **Runtime**: ~4-5 minutes

#### `generated_login_test.yaml`
**User Login Flow**
- ✅ Uses saved credentials from previous registration
- ✅ Google Password Manager handling
- ✅ Notification permissions
- ✅ UI exploration after login
- 📂 **Reads credentials** from `test_credentials.json`
- ⏱️ **Runtime**: ~3-4 minutes

**Generate new tests:**
```bash
# Register new user (Android)
python3 smart_test_runner.py --register --platform android

# Login with saved credentials
python3 smart_test_runner.py --login --platform android
```

---

## ✅ Clean State Initialization

**All tests in `organized/` start with automatic clean state setup:**

1. **Clear App State** - `clearState: com.whisker.android`
2. **Launch App** - Fresh start every time
3. **Handle Onboarding** - Skip welcome screens
4. **Automatic Login** - Using test credentials
5. **Handle Popups** - Password manager, notifications
6. **Verify Home Screen** - Ready to start testing

This ensures:
- ✅ **Consistent starting point** for every test
- ✅ **No cross-test contamination**
- ✅ **Reproducible results**
- ✅ **Reliable CI/CD execution**

---

## 🚀 Running Tests

### From Project Root

```bash
# List all tests
./run_all_tests.sh --list

# Run single test
./run_all_tests.sh --test 01_profile_account_tests.yaml

# Run organized suite
./run_all_tests.sh --suite organized

# Run smoke test (fastest)
./run_all_tests.sh --suite smoke --headless

# Run all tests
./run_all_tests.sh --suite all --headless
```

### Directly with Maestro

```bash
# Run specific organized test
maestro test tests/organized/01_profile_account_tests.yaml

# Run standalone test
maestro test tests/standalone/whisker_ui_test.yaml

# Headless mode
maestro test --headless tests/organized/03_shop_commerce_tests.yaml
```

---

## 📝 Test File Format

All YAML test files follow this structure:

```yaml
appId: com.whisker.android
---
# TEST NAME
# Generated: timestamp
# Description

# INITIALIZATION - Clean State & Auto Login (in organized/ tests)
- clearState: com.whisker.android
- launchApp: com.whisker.android
# ... automatic login ...

# START OF ACTUAL TEST
- takeScreenshot: "00_start"
- tapOn: "Element"
# ... test steps ...
```

---

## 🛠️ Adding New Tests

### Option 1: Add to Organized Suite

Edit `test_organizer.py` and add a new method:

```python
def create_my_new_tests(self):
    test_content = f"""appId: {self.app_id}
---
# MY NEW TESTS

{self.get_clean_state_init()}  # Clean state init

# Your test steps here
- tapOn: "Something"
"""
    filename = f"{self.tests_dir}/07_my_new_tests.yaml"
    with open(filename, 'w') as f:
        f.write(test_content)
    return filename
```

Then add to `create_all_tests()`:
```python
tests_created.append(self.create_my_new_tests())
```

Run: `python3 test_organizer.py`

### Option 2: Add Standalone Test

Create a new YAML file in `tests/standalone/`:

```bash
cat > tests/standalone/my_new_test.yaml << 'EOF'
appId: com.whisker.android
---
# My New Test

- launchApp
- tapOn: "Something"
# ... your test steps ...
EOF
```

### Option 3: Add to Custom List

Create a text file with test names:

```bash
cat > my_tests.txt << 'EOF'
login
01_profile_account_tests.yaml
my_new_test.yaml
EOF

./run_all_tests.sh --custom my_tests.txt
```

---

## 🧹 Maintenance

### Regenerate Organized Tests

```bash
# Regenerates all tests in tests/organized/
python3 test_organizer.py
```

### Update Clean State Credentials

Edit `test_organizer.py`, update in `get_clean_state_init()`:
```python
- inputText: "your_email@test.com"
# ...
- inputText: "your_password"
```

Then regenerate: `python3 test_organizer.py`

### Clean Old Tests

```bash
# Remove old organized_tests directory (if exists)
rm -rf organized_tests/

# The new location is tests/organized/
```

---

## 📊 Test Statistics

- **Total Tests**: 11+ YAML files
- **Organized Suite**: 6 comprehensive tests
- **Standalone**: 5 individual tests
- **Total Steps**: 142+ test steps in organized suite
- **Est. Runtime**: ~20 min (organized), ~3-5 min (smoke)

---

## 🔍 Debugging

### View Test Screenshots

```bash
# Last test run
open ~/.maestro/tests/$(ls -t ~/.maestro/tests/ | head -1)/
```

### Run Single Test for Debug

```bash
# With UI visible
./run_all_tests.sh --test 02_pet_management_tests.yaml

# Check specific test file
maestro test tests/organized/02_pet_management_tests.yaml
```

### Check UI Hierarchy

```bash
maestro hierarchy
```

---

## 📚 Related Documentation

- `../DEBUGGING_TESTS.md` - Complete debugging guide
- `../INDIVIDUAL_TEST_GUIDE.md` - Running individual tests
- `../COMPLETE_TEST_SUITE.md` - All test suites reference
- `../SMOKE_TEST_GUIDE.md` - Quick smoke testing

---

## 🎯 Best Practices

1. **Always use clean state** - Tests in `organized/` automatically do this
2. **Use descriptive screenshots** - Name them sequentially: `01_step`, `02_step`
3. **Add assertions** - Use `assertVisible` to verify state
4. **Handle popups** - Use `runFlow: when: visible` for conditional elements
5. **Wait for animations** - Add `waitForAnimationToEnd` after navigation
6. **Test independently** - Each test should work alone
7. **Keep tests focused** - One feature area per test file

---

## ⚠️ Important Notes

- **All organized tests** now start with `clearState` and automatic login
- **Test files** are now in `tests/` subdirectories (not root)
- **Backwards compatibility** maintained - old paths still work
- **Clean state** ensures consistent, reliable test execution
- **Automatic login** saves time and reduces test complexity

---

**Last Updated:** 2025-11-12  
**Version:** 2.0 (Clean State + Organized Structure)  
**Maintained by:** cvanthin@hotmail.com

