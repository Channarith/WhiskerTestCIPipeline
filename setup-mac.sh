#!/bin/bash

# Whisker App - Mac Setup Script
# This script helps you set up your Mac for mobile app development

set -e  # Exit on error

echo "🚀 Whisker App - Mac Setup Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Step 1: Checking prerequisites..."
echo "-----------------------------------"

# Check Homebrew
if command_exists brew; then
    print_success "Homebrew is installed"
else
    print_warning "Homebrew is not installed"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
fi

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed ($NODE_VERSION)"
    
    # Check if version is 18+
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        print_warning "Node.js version should be 18 or higher"
        echo "Installing latest Node.js..."
        brew install node
    fi
else
    print_warning "Node.js is not installed"
    echo "Installing Node.js..."
    brew install node
    print_success "Node.js installed"
fi

# Check Watchman
if command_exists watchman; then
    print_success "Watchman is installed"
else
    print_warning "Watchman is not installed"
    echo "Installing Watchman..."
    brew install watchman
    print_success "Watchman installed"
fi

# Check CocoaPods
if command_exists pod; then
    print_success "CocoaPods is installed"
else
    print_warning "CocoaPods is not installed"
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
    print_success "CocoaPods installed"
fi

# Check Xcode
if command_exists xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n1)
    print_success "Xcode is installed ($XCODE_VERSION)"
    
    # Check Command Line Tools
    if xcode-select -p >/dev/null 2>&1; then
        print_success "Xcode Command Line Tools are installed"
    else
        print_warning "Xcode Command Line Tools are not installed"
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        print_info "Please complete the installation in the dialog that appears"
    fi
else
    print_error "Xcode is not installed"
    print_info "Please install Xcode from the Mac App Store"
    print_info "https://apps.apple.com/us/app/xcode/id497799835"
fi

# Check Android SDK
if [ -d "$HOME/Library/Android/sdk" ]; then
    print_success "Android SDK is installed"
    export ANDROID_HOME=$HOME/Library/Android/sdk
else
    print_warning "Android SDK not found"
    print_info "Please install Android Studio from:"
    print_info "https://developer.android.com/studio"
fi

echo ""
echo "Step 2: Environment Variables"
echo "-----------------------------------"

# Check if ANDROID_HOME is set
if [ -z "$ANDROID_HOME" ]; then
    print_warning "ANDROID_HOME is not set"
    echo ""
    echo "Add these lines to your ~/.zshrc (or ~/.bash_profile if using bash):"
    echo ""
    echo "export ANDROID_HOME=\$HOME/Library/Android/sdk"
    echo "export PATH=\$PATH:\$ANDROID_HOME/emulator"
    echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
    echo "export PATH=\$PATH:\$ANDROID_HOME/tools"
    echo "export PATH=\$PATH:\$ANDROID_HOME/tools/bin"
    echo ""
    echo "Then run: source ~/.zshrc"
else
    print_success "ANDROID_HOME is set: $ANDROID_HOME"
fi

echo ""
echo "Step 3: Project Setup"
echo "-----------------------------------"

# Ask user if they want to initialize React Native project
echo ""
read -p "Do you want to initialize a React Native project now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Initializing React Native project..."
    
    # Check if we're in the Whisker directory
    print_info "Creating React Native project..."
    print_info "This will take 2-3 minutes..."
    
    npx @react-native-community/cli@latest init WhiskerApp
    
    if [ -d "WhiskerApp" ]; then
        cd WhiskerApp
        print_success "Project created successfully"
    else
        print_error "Failed to create project"
        print_info "Try running manually: npx @react-native-community/cli@latest init WhiskerApp"
        exit 1
    fi
    
    print_success "React Native project created!"
    
    # Install iOS dependencies
    print_info "Installing iOS dependencies..."
    cd ios
    pod install
    cd ..
    print_success "iOS dependencies installed"
    
    echo ""
    print_success "Setup complete! 🎉"
    echo ""
    echo "Next steps:"
    echo "1. Open a terminal and run: npm start"
    echo "2. Open another terminal and run: npx react-native run-ios"
    echo "3. For Android: npx react-native run-android (make sure emulator is running)"
    echo ""
    echo "For more details, see LOCAL_MAC_SETUP.md"
else
    print_info "Skipping React Native project initialization"
    echo ""
    echo "To initialize later, run:"
    echo "npx react-native@latest init WhiskerApp"
fi

echo ""
echo "=================================="
print_success "Mac setup script completed!"
echo "=================================="
echo ""
echo "📚 Documentation:"
echo "   - Local setup guide: LOCAL_MAC_SETUP.md"
echo "   - Getting started: GETTING_STARTED.md"
echo "   - Quick reference: QUICK_REFERENCE.md"
echo ""

