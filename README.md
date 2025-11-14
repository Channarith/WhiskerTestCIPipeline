# Whisker App Automated Testing Framework

Automated testing framework for the Whisker Android app using Maestro and Python.

![Whisker Test Demo](demo_videos/whisker_test_screen.gif)

## 🚀 Features

- ✅ **Smart Test Runner**: Automatically manages test flows for registration and login
- ✅ **Credential Management**: Stores and reuses test accounts
- ✅ **Comprehensive UI Testing**: Tests all major app features (Profile, Blogs, Tabs, etc.)
- ✅ **Screenshot Capture**: Takes screenshots at each test step
- ✅ **App State Management**: Cleans app data before each test run
- ✅ **CI/CD Ready**: GitHub Actions workflow included

## 📋 Prerequisites

### Local Testing

1. **macOS** (for Android emulator with hardware acceleration)
2. **Android Studio** with:
   - Android SDK (API 35 recommended)
   - Platform Tools
   - Android Emulator
3. **Java 17** (OpenJDK):
   ```bash
   brew install openjdk@17
   ```
4. **Maestro**:
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```
5. **Python 3.11+**:
   ```bash
   brew install python@3.11
   pip3 install prometheus-client psutil
   ```

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone https://github.com/Channarith/WhiskerTestCIPipeline.git
cd WhiskerTestCIPipeline
```

### 2. Install Dependencies
```bash
pip3 install prometheus-client psutil
```

### 3. Set up Android Emulator
```bash
# List available devices
emulator -list-avds

# Start your emulator (or use Android Studio Device Manager)
emulator -avd <your_device_name>
```

### 4. Install Whisker App
- Download the Whisker APK
- Install via ADB:
  ```bash
  adb install whisker.apk
  ```
- Or download from Google Play Store on the emulator

### 5. Verify Setup
```bash
# Check ADB connection
adb devices

# Check Whisker app is installed
adb shell pm list packages | grep whisker
```

## 🎯 Running Tests

### Android Testing

#### Register a New User
```bash
python3 smart_test_runner.py --register --platform android
# Or simply (android is default):
python3 smart_test_runner.py --register
```

This will:
- Generate random credentials (first name, last name, email, password)
- Clear app data for a fresh start
- Run through registration flow
- Create password
- Accept notifications
- Explore all UI elements (Profile, Blogs, Tabs)
- Save credentials to `test_credentials.json`

#### Login with Saved Credentials
```bash
python3 smart_test_runner.py --login
```

This will:
- Use the last registered credentials
- Run through login flow
- Explore UI

### iOS Testing

#### Register a New User on iOS
```bash
python3 smart_test_runner.py --register --platform ios
```

#### Login on iOS
```bash
python3 smart_test_runner.py --login --platform ios
```

**iOS Requirements:**
- iOS Simulator must be running
- Whisker app must be installed on the simulator
- Update `IOS_BUNDLE_ID` in `smart_test_runner.py` with actual bundle ID

**Start iOS Simulator:**
```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15"

# Or open Simulator app
open -a Simulator
```

### Test Suite Runner (Comprehensive Tests)

For running comprehensive test suites, use the `run_all_tests.sh` script:

```bash
# Run organized tests with LIVE CHECKLIST UI (Development Mode)
./run_all_tests.sh --suite organized --platform android

# Run smoke tests for quick validation
./run_all_tests.sh --suite smoke --platform android

# Run all tests including registration
./run_all_tests.sh --suite all --platform android
```

#### Understanding Report Modes

The script supports two distinct modes:

**🎨 Development Mode (NO `--reports` flag)**
- ✅ Shows live Maestro checklist UI with real-time progress
- ✅ Interactive visual feedback with checkboxes (✅ ⚪️ ❌)
- ✅ Best for debugging and watching test execution
- ✅ Immediate visual feedback on which step is running
- ❌ No JUnit XML or HTML reports generated

```bash
# Development - See live checklist
./run_all_tests.sh --suite smoke
```

**📊 CI/CD Mode (WITH `--reports` flag)**
- ✅ Generates JUnit XML reports for CI/CD integration
- ✅ Creates HTML summary with pass/fail statistics
- ✅ Captures detailed error logs with line numbers
- ✅ Organized screenshots in timestamped directories
- ✅ Perfect for automated testing pipelines
- ❌ **No live checklist UI** (Maestro suppresses interactive output when generating XML)

```bash
# CI/CD - Generate reports (no live UI)
./run_all_tests.sh --suite smoke --reports
```

**🤔 Why does `--reports` hide the checklist?**

When `--reports` is enabled, Maestro adds the `--format=JUNIT` flag to generate machine-readable XML output. This flag switches Maestro to non-interactive mode to avoid mixing human-readable checklist output with structured data. This is standard behavior for most CI/CD tools (similar to pytest, jest, etc.).

**💡 Recommendation:**
- **Local development**: Run WITHOUT `--reports` to watch tests in real-time
- **CI/CD pipelines**: Use `--reports` for automated report generation and archiving
- **Debugging failures**: Run without `--reports` first to see where it fails, then use `--reports` to capture detailed logs

#### Additional Test Options

```bash
# Run a single test (with live UI)
./run_all_tests.sh --test 01_profile_account_tests.yaml

# Run specific test with reports
./run_all_tests.sh --test 01_profile_account_tests.yaml --reports

# Run tests multiple times (stress testing)
./run_all_tests.sh --suite smoke --repeat 5 --reports

# List all available tests
./run_all_tests.sh --list

# Run custom test list
./run_all_tests.sh --custom my_tests.txt --reports

# Run headless (no emulator UI)
./run_all_tests.sh --suite organized --headless

# Run on iOS
./run_all_tests.sh --suite organized --platform ios
```

See `RUN_TESTS.txt` for complete documentation of all options.

## 📂 Project Structure

```
WhiskerTestCIPipeline/
├── .github/
│   └── workflows/
│       ├── whisker-tests-android.yml   # Android CI/CD
│       └── whisker-tests-ios.yml       # iOS CI/CD
├── tests/
│   ├── organized/                      # Main test suite (6 tests)
│   │   ├── 01_profile_account_tests.yaml
│   │   ├── 02_pet_management_tests.yaml
│   │   ├── 03_shop_commerce_tests.yaml
│   │   ├── 04_device_management_tests.yaml
│   │   ├── 05_insights_analytics_tests.yaml
│   │   └── 06_logout_login_tests.yaml
│   ├── standalone/                     # Individual tests
│   │   ├── whisker_ui_test.yaml
│   │   ├── whisker_stress_test.yaml
│   │   └── whisker_recording_test1.yaml
│   ├── registration/                   # Auto-generated tests
│   │   ├── generated_register_test_android.yaml
│   │   └── generated_login_test.yaml
│   └── README.md                       # Test documentation
├── demo_videos/
│   ├── whisker_test_screen.gif         # Demo for README
│   └── *.mp4                           # Test recordings
├── reports/                            # Generated with --reports
│   └── YYYY-MM-DD_HH-MM-SS/
│       ├── summary.html                # Test summary
│       ├── *_junit.xml                 # JUnit reports
│       ├── logs/                       # Error logs
│       └── screenshots/                # Test screenshots
├── smart_test_runner.py                # Main test runner
├── test_organizer.py                   # Test suite generator
├── prepare_logout_login_test.py        # Credential injector
├── run_all_tests.sh                    # Test execution script
├── test_credentials.json               # Saved test accounts (gitignored)
├── maestro_debug_output/               # Maestro debug data (gitignored)
└── README.md                           # This file
```

## 🧪 Test Suite Overview

For detailed test documentation, see [`tests/README.md`](tests/README.md).

### Organized Tests (Main Suite)

| Test | Description | Key Features Tested |
|------|-------------|-------------------|
| **01_profile_account_tests.yaml** | Profile and account management | • Profile viewing<br>• Account information<br>• Address management<br>• Payment methods<br>• Settings navigation |
| **02_pet_management_tests.yaml** | Pet profile creation and management | • Dog profile creation<br>• Cat profile creation<br>• Pet information forms<br>• Multiple pet handling<br>• Setup workflows |
| **03_shop_commerce_tests.yaml** | E-commerce and shopping features | • Cookie consent<br>• Product browsing<br>• Shopping cart<br>• Category navigation<br>• Search functionality |
| **04_device_management_tests.yaml** | Smart device setup and management | • Litter-Robot pairing<br>• Feeder-Robot setup<br>• Device configuration<br>• Settings adjustment |
| **05_insights_analytics_tests.yaml** | Pet health and activity analytics | • Activity tracking<br>• Health insights<br>• Data visualization<br>• Trends analysis<br>• Report viewing |
| **06_logout_login_tests.yaml** | Authentication flows | • Complete logout<br>• Fresh login<br>• Credential validation<br>• Session management |

### Smoke Tests (Quick Validation)

The smoke test suite runs a minimal set of critical tests:
- Login flow verification
- Shop navigation and cookies
- Profile access

**Estimated runtime**: 3-5 minutes

### Registration Tests (Dynamic)

Generated dynamically by `smart_test_runner.py`:
- Random user generation
- Password creation with requirements
- Terms & Conditions acceptance
- Notification permissions

## 🔧 Test Flow Details

### Registration Test Flow
1. Launch app and clear data
2. Navigate to registration screen
3. Fill in user details (First Name, Last Name, Email)
4. Accept Terms & Conditions
5. Create password (meets requirements: capital, 8+ chars, number, special symbol)
6. Welcome screen and trial offer
7. Accept notifications
8. **UI Exploration:**
   - Profile icon → Login Information → Reset Password
   - Blogs section (Learn More)
   - Bottom tabs: Insights, Devices, Pets, Shop, Home
   - Scroll testing
9. Close app (return to Android home)

### Login Test Flow
1. Launch app and clear data
2. Navigate to login screen
3. Enter saved credentials
4. Handle Google Password Manager popup (click "Not now")
5. UI exploration (same as registration)

## ⚙️ GitHub Actions CI/CD

### Triggers
- **Push** to `main` or `develop` branches
- **Pull Requests** to `main`
- **Scheduled**: Daily at 2 AM UTC
- **Manual**: Via workflow dispatch

### Workflow Steps
1. Set up macOS runner (for hardware acceleration)
2. Install Java 17, Python 3.11
3. Install Android SDK and emulator
4. Install Maestro
5. Start Android emulator
6. Install Whisker APK
7. Run tests
8. Upload artifacts (screenshots, logs, credentials)

### Setting Up GitHub Secrets

To run tests in GitHub Actions, add the following secret:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add **New repository secret**:
   - Name: `WHISKER_APK_URL`
   - Value: URL to download Whisker APK (e.g., from a release or artifact storage)

### Manual Workflow Trigger

You can manually trigger tests with specific options:
1. Go to **Actions** → **Whisker App Automated Tests**
2. Click **Run workflow**
3. Choose test type: `register`, `login`, or `both`

## 📊 Test Artifacts

### Local Test Reports (with `--reports` flag)

When using `--reports`, all artifacts are organized in timestamped directories:

```
reports/
└── 2025-11-13_14-30-45/
    ├── summary.html              # Visual test summary with pass/fail stats
    ├── 01_profile_account_tests_junit.xml
    ├── 02_pet_management_tests_junit.xml
    ├── 03_shop_commerce_tests_junit.xml
    ├── ...                       # JUnit XML reports (one per test)
    ├── 01_app_launched.png
    ├── 03_form_filled.png
    ├── ...                       # All test screenshots
    └── logs/                     # Error logs (only for failed tests)
        └── test_name_timestamp.log
```

**Open the HTML report:**
```bash
open reports/$(ls -t reports/ | head -1)/summary.html
```

### Without `--reports` flag

Screenshots are saved in the root `screenshots/` directory (not organized by timestamp).

### GitHub Actions Artifacts

After each CI/CD test run, the following artifacts are uploaded:

- **Test Results**: Complete JUnit XML reports and HTML summary
- **Screenshots**: Visual verification of each test step
- **Debug Output**: Maestro debug logs and hierarchy data
- **Credentials**: Saved test accounts (for reuse in future tests)

Artifacts are retained for 30 days (test results) and 14 days (screenshots).

**Download artifacts:**
1. Go to **Actions** tab in GitHub
2. Click on a workflow run
3. Scroll to **Artifacts** section
4. Download desired artifacts

## 🔍 Debugging

### View Maestro Logs
```bash
ls -la maestro_debug_output/.maestro/tests/
```

### View Screenshots
Screenshots are saved with descriptive names:
- `01_app_launched.png`
- `03_form_filled.png`
- `ui_05_insights_tab.png`
- etc.

### Test Credentials
View saved accounts:
```bash
cat test_credentials.json
```

## 🚨 Troubleshooting

### Emulator Issues
```bash
# Kill all emulators
adb emu kill

# Restart ADB
adb kill-server && adb start-server

# Check emulator status
adb devices
```

### App Installation Issues
```bash
# Force stop app
adb shell am force-stop com.whisker.android

# Clear app data
adb shell pm clear com.whisker.android

# Reinstall app
adb uninstall com.whisker.android
adb install whisker.apk
```

### Maestro Issues
```bash
# Check Maestro version
maestro --version

# Update Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash

# View UI hierarchy
maestro hierarchy
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request

## 📝 License

Private repository - All rights reserved.

## 👤 Author

**Channarith** (cvanthin@hotmail.com)
- GitHub: [@Channarith](https://github.com/Channarith)

---

**Repository**: https://github.com/Channarith/WhiskerTestCIPipeline
