# Whisker App - Cross-Platform Testing Setup Guide

Complete setup guide for running Whisker automated tests on macOS, Linux, and Windows.

---

## 📋 Table of Contents

1. [Platform Support](#platform-support)
2. [macOS Setup](#macos-setup)
3. [Linux Setup](#linux-setup)
4. [Windows Setup](#windows-setup)
5. [Verification Steps](#verification-steps)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

---

## Platform Support

### What's Supported

✅ **macOS** - Full support (Android + iOS testing)  
✅ **Linux** - Android testing supported  
✅ **Windows** - Android testing supported (WSL2 recommended)

### Platform Compatibility Matrix

| Feature | macOS | Linux | Windows (Native) | Windows (WSL2) |
|---------|-------|-------|------------------|----------------|
| Android Emulator | ✅ | ✅ | ✅ | ✅* |
| iOS Simulator | ✅ | ❌ | ❌ | ❌ |
| Hardware Acceleration | ✅ | ✅ (KVM) | ✅ (HAXM/WHPX) | ✅ (WSL2 + KVM) |
| `run_all_tests.sh` | ✅ | ✅ | ⚠️ (Git Bash) | ✅ |
| Maestro | ✅ | ✅ | ✅ | ✅ |
| Python Scripts | ✅ | ✅ | ✅ | ✅ |

*WSL2 requires ADB bridge to Windows

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 8 GB | 16+ GB |
| **Disk** | 10 GB free | 20+ GB free (SSD preferred) |
| **Virtualization** | Intel VT-x / AMD-V enabled | Hardware acceleration enabled |

---

## macOS Setup

### Prerequisites

- macOS 10.14 (Mojave) or later
- Xcode Command Line Tools (for iOS testing)
- Homebrew (package manager)

### Installation Steps

#### 1. Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Android Studio

Download from [https://developer.android.com/studio](https://developer.android.com/studio)

Or install via Homebrew:
```bash
brew install --cask android-studio
```

Launch Android Studio and install:
- Android SDK (API 35 recommended)
- Android SDK Platform-Tools
- Android Emulator
- Intel x86 Emulator Accelerator (HAXM) for Intel Macs

#### 3. Install Java 17 (OpenJDK)

```bash
brew install openjdk@17

# Add to PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### 4. Install Maestro

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

#### 5. Install Python 3.11+

```bash
brew install python@3.11

# Install required packages
pip3 install prometheus-client psutil
```

#### 6. Configure PATH

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

# Maestro
export PATH=$HOME/.maestro/bin:$PATH

# Apply changes
source ~/.zshrc
```

#### 7. Create Android Emulator

```bash
# List available system images
sdkmanager --list | grep system-images

# Install a system image (API 35 recommended)
sdkmanager "system-images;android-35;google_apis;x86_64"

# Create AVD
avdmanager create avd -n Pixel_5_API_35 -k "system-images;android-35;google_apis;x86_64"

# List AVDs
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_35
```

---

## Linux Setup

### Prerequisites

- Ubuntu 20.04+ / Debian 11+ / Fedora 35+ / Arch Linux
- Hardware virtualization (Intel VT-x / AMD-V)

### Installation Steps

#### 1. Install Android Studio

**Ubuntu/Debian:**
```bash
# Download from https://developer.android.com/studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz

# Extract
sudo tar -xvzf android-studio-*.tar.gz -C /opt/

# Run
cd /opt/android-studio/bin
./studio.sh
```

**Fedora:**
```bash
sudo dnf install android-studio
```

**Arch:**
```bash
yay -S android-studio
```

In Android Studio, install:
- Android SDK (API 35)
- Platform-Tools
- Android Emulator

#### 2. Install Java 17 (OpenJDK)

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

**Fedora:**
```bash
sudo dnf install java-17-openjdk-devel
```

**Arch:**
```bash
sudo pacman -S jdk17-openjdk
```

Verify:
```bash
java -version
```

#### 3. Enable KVM (Hardware Acceleration)

```bash
# Check if KVM is available
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Install KVM
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Add user to kvm group
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER

# Verify KVM permissions
ls -l /dev/kvm

# Log out and log back in for changes to take effect
```

#### 4. Install Maestro

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

#### 5. Install Python 3.11+

**Ubuntu/Debian:**
```bash
sudo apt install python3 python3-pip
pip3 install prometheus-client psutil
```

**Fedora:**
```bash
sudo dnf install python3 python3-pip
pip3 install prometheus-client psutil
```

**Arch:**
```bash
sudo pacman -S python python-pip
pip install prometheus-client psutil
```

#### 6. Configure PATH

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

# Maestro
export PATH=$HOME/.maestro/bin:$PATH

# Apply changes
source ~/.bashrc
```

#### 7. Create Android Emulator

```bash
# Install SDK command-line tools via Android Studio SDK Manager

# Install system image
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-35;google_apis;x86_64"

# Create AVD
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd -n Pixel_5_API_35 -k "system-images;android-35;google_apis;x86_64"

# Start emulator
emulator -avd Pixel_5_API_35
```

---

## Windows Setup

### Option 1: WSL2 (Recommended)

Windows Subsystem for Linux 2 provides the best compatibility with the test scripts.

#### 1. Enable WSL2

Run in **PowerShell as Administrator**:

```powershell
# Enable WSL
wsl --install

# Set WSL2 as default
wsl --set-default-version 2

# Install Ubuntu
wsl --install -d Ubuntu

# Restart your computer
```

#### 2. Setup Inside WSL2

Open Ubuntu from Start Menu and follow the [Linux Setup](#linux-setup) instructions above.

#### 3. Install Android Studio in Windows

Download and install from [https://developer.android.com/studio](https://developer.android.com/studio)

Install:
- Android SDK (API 35)
- Platform-Tools
- Android Emulator

#### 4. Configure ADB Bridge from WSL2 to Windows

In **Windows**:
```powershell
# Start ADB server
adb start-server
```

In **WSL2**:
```bash
# Connect to Windows ADB server
export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037

# Add to ~/.bashrc for persistence
echo 'export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037' >> ~/.bashrc

# Verify connection
adb devices
```

---

### Option 2: Native Windows

For users who prefer running directly on Windows.

#### 1. Install Android Studio

Download from [https://developer.android.com/studio](https://developer.android.com/studio)

Install:
- Android SDK (API 35)
- Platform-Tools
- Android Emulator

#### 2. Install Java 17 (OpenJDK)

Download from [https://adoptium.net/](https://adoptium.net/)

Install and set `JAVA_HOME` environment variable:
```powershell
# Set JAVA_HOME (adjust path to your installation)
[System.Environment]::SetEnvironmentVariable(
    "JAVA_HOME",
    "C:\Program Files\Eclipse Adoptium\jdk-17.0.9.9-hotspot",
    "User"
)
```

#### 3. Install Maestro

Run in **PowerShell**:
```powershell
iwr https://get.maestro.mobile.dev | iex
```

#### 4. Install Python 3.11+

Download from [https://www.python.org/downloads/](https://www.python.org/downloads/)

During installation:
- ✅ Check "Add Python to PATH"
- ✅ Check "Install pip"

Install packages:
```powershell
pip install prometheus-client psutil
```

#### 5. Add to System PATH

Open **System Environment Variables**:

1. Press `Win + X`, select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", select "Path" and click "Edit"
5. Add these paths:
   ```
   C:\Users\<YourName>\AppData\Local\Android\Sdk\platform-tools
   C:\Users\<YourName>\AppData\Local\Android\Sdk\emulator
   C:\Users\<YourName>\.maestro\bin
   ```

#### 6. Enable Hardware Acceleration

**For Intel CPUs:**
- Install Intel HAXM via Android Studio SDK Manager

**For AMD CPUs or Windows 11:**
- Enable Windows Hypervisor Platform:
  1. Settings → Apps → Optional Features → More Windows Features
  2. Check "Windows Hypervisor Platform"
  3. Restart computer

#### 7. Run Tests

Use **PowerShell** or **Git Bash** to run Python scripts:

```powershell
# Register new user
python smart_test_runner.py --register

# Run test suite
# Note: Use Python instead of bash scripts
python smart_test_runner.py --login
```

For `run_all_tests.sh`, use **Git Bash** or **WSL2**.

---

## Verification Steps

After completing setup on any platform, verify everything works:

### 1. Check Java

```bash
java -version
# Should show Java 17
```

### 2. Check Android SDK

```bash
adb version
# Should show Android Debug Bridge version

emulator -list-avds
# Should list available emulators
```

### 3. Check Maestro

```bash
maestro --version
# Should show Maestro version (2.0.9 or later)
```

### 4. Check Python

```bash
python3 --version
# Should show Python 3.11+

pip3 list | grep prometheus-client
pip3 list | grep psutil
# Should show installed packages
```

### 5. Start Emulator

```bash
# Start emulator (use your AVD name)
emulator -avd Pixel_5_API_35 &

# Wait for it to boot, then check
adb devices
# Should show device online
```

### 6. Install Whisker App

```bash
# Install from APK
adb install whisker.apk

# Verify installation
adb shell pm list packages | grep whisker
# Should show: package:com.whisker.android
```

### 7. Run a Test

```bash
# Clone the repo
git clone https://github.com/Channarith/WhiskerTestCIPipeline.git
cd WhiskerTestCIPipeline

# Run registration test
python3 smart_test_runner.py --register --platform android

# Or run a simple test
maestro test tests/standalone/whisker_ui_test.yaml
```

---

## Troubleshooting

### Common Issues (All Platforms)

#### ADB Not Found

```bash
# Verify PATH includes Android SDK
echo $PATH | grep Android

# Restart ADB
adb kill-server
adb start-server
```

#### Emulator Won't Start

```bash
# Check if hardware acceleration is enabled
# On Linux:
kvm-ok

# On macOS:
sysctl kern.hv_support
# Should return 1

# On Windows:
# Check if HAXM or WHPX is enabled in SDK Manager
```

#### Maestro Connection Issues

```bash
# Kill existing Maestro processes
pkill maestro

# Restart Maestro
maestro --version
```

---

### Linux-Specific Issues

#### KVM Permission Denied

```bash
# Check KVM permissions
ls -l /dev/kvm

# Add user to kvm group
sudo usermod -aG kvm $USER

# Log out and log back in

# Verify
id | grep kvm
```

#### libGL Error

```bash
# Install required libraries
sudo apt install libgl1-mesa-dev libglu1-mesa-dev
```

---

### Windows-Specific Issues

#### WSL2 ADB Bridge Not Working

```bash
# In Windows PowerShell:
adb kill-server
adb -a -P 5037 start-server

# In WSL2:
export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037
adb devices
```

#### PowerShell Script Execution Error

```powershell
# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### HAXM Installation Failed on AMD CPU

Use Windows Hypervisor Platform (WHPX) instead:
1. Uninstall HAXM if installed
2. Enable WHPX in Windows Features
3. Create new AVD with WHPX acceleration

---

### macOS-Specific Issues

#### Xcode Command Line Tools Not Found

```bash
xcode-select --install
```

#### M1/M2 Mac Issues

```bash
# Install Rosetta 2 if needed
softwareupdate --install-rosetta

# Use ARM64 system images in Android Studio
# Look for images with "arm64-v8a" architecture
```

---

## Next Steps

After successful setup:

1. ✅ **Read the Main README**: `README.md` for full documentation
2. ✅ **Explore Test Suite**: Check `tests/README.md` for test details
3. ✅ **Run Quick Test**: Try the smoke suite
   ```bash
   ./run_all_tests.sh --suite smoke
   ```
4. ✅ **View Test Results**: Check screenshots and reports
5. ✅ **Create Custom Tests**: Modify test files for your needs

---

## Useful Commands

### Start Testing Quickly

```bash
# Register new user
python3 smart_test_runner.py --register

# Login with saved credentials
python3 smart_test_runner.py --login

# Run smoke tests (fastest)
./run_all_tests.sh --suite smoke

# Run all organized tests
./run_all_tests.sh --suite organized

# Run with reports
./run_all_tests.sh --suite smoke --reports

# List all available tests
./run_all_tests.sh --list
```

### Emulator Management

```bash
# List AVDs
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_35

# Start in headless mode
emulator -avd Pixel_5_API_35 -no-window

# Kill emulator
adb emu kill
```

### ADB Commands

```bash
# Check devices
adb devices

# Install app
adb install whisker.apk

# Uninstall app
adb uninstall com.whisker.android

# Clear app data
adb shell pm clear com.whisker.android

# View app logs
adb logcat | grep Whisker
```

---

## Resources

### Documentation
- [Main README](README.md) - Complete project documentation
- [Test Documentation](tests/README.md) - Detailed test suite info
- [Run Tests Guide](RUN_TESTS.txt) - Quick reference for running tests

### External Resources
- [Android Studio](https://developer.android.com/studio)
- [Maestro Documentation](https://maestro.mobile.dev/)
- [Python Official Site](https://www.python.org/)
- [WSL2 Setup](https://learn.microsoft.com/en-us/windows/wsl/install)

---

## Support

For issues or questions:
- 📧 Email: cvanthin@hotmail.com
- 🐛 GitHub Issues: [Report a bug](https://github.com/Channarith/WhiskerTestCIPipeline/issues)
- 📖 Documentation: Check README.md and test documentation

---

**Last Updated:** November 2025  
**Maintained by:** cvanthin@hotmail.com

