# Whisker App Automated Testing Framework

Automated testing framework for the Whisker Android app using Maestro and Python.

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

### Register a New User
```bash
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

### Login with Saved Credentials
```bash
python3 smart_test_runner.py --login
```

This will:
- Use the last registered credentials
- Run through login flow
- Explore UI

## 📂 Project Structure

```
WhiskerTestCIPipeline/
├── .github/
│   └── workflows/
│       └── whisker-tests.yml      # GitHub Actions CI/CD
├── smart_test_runner.py           # Main test runner
├── Flow.yaml                       # Maestro flow examples
├── generated_register_test.yaml   # Auto-generated registration test
├── generated_login_test.yaml      # Auto-generated login test
├── test_credentials.json          # Saved test accounts (gitignored)
├── maestro_debug_output/          # Test logs & screenshots (gitignored)
└── README.md
```

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

After each test run, the following artifacts are uploaded:

- **Test Results**: Complete logs and debug output
- **Screenshots**: Visual verification of each test step
- **Credentials**: Saved test accounts (for reuse in future tests)

Artifacts are retained for 30 days (test results) and 14 days (screenshots).

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
