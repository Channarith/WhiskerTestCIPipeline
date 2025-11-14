#!/bin/bash
#
# Pre-flight Check for Whisker Test Suite
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║           🔍 PRE-FLIGHT CHECK - WHISKER TESTS            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

ALL_GOOD=true

# Check 1: ADB
echo -e "${CYAN}[1/6]${NC} Checking ADB..."
if command -v adb &> /dev/null; then
    echo -e "      ${GREEN}✅ ADB found: $(which adb)${NC}"
else
    echo -e "      ${RED}❌ ADB not found${NC}"
    echo "      Add to PATH: export PATH=\$HOME/Library/Android/Sdk/platform-tools:\$PATH"
    ALL_GOOD=false
fi

# Check 2: Emulator
echo ""
echo -e "${CYAN}[2/6]${NC} Checking Android Emulator..."
if command -v adb &> /dev/null; then
    DEVICE_COUNT=$(adb devices 2>/dev/null | grep -c "device$" || echo "0")
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        echo -e "      ${GREEN}✅ Emulator running ($DEVICE_COUNT device(s))${NC}"
        adb devices | grep "device$" | while read -r line; do
            echo "         • $line"
        done
    else
        echo -e "      ${RED}❌ No emulator running${NC}"
        echo "      Start: Android Studio → Device Manager → Start Device"
        ALL_GOOD=false
    fi
else
    echo -e "      ${YELLOW}⚠️  Cannot check (ADB not found)${NC}"
fi

# Check 3: Whisker App
echo ""
echo -e "${CYAN}[3/6]${NC} Checking Whisker App..."
if command -v adb &> /dev/null && [ "$DEVICE_COUNT" -gt 0 ]; then
    if adb shell pm list packages 2>/dev/null | grep -q "com.whisker.android"; then
        echo -e "      ${GREEN}✅ Whisker app installed (com.whisker.android)${NC}"
    else
        echo -e "      ${RED}❌ Whisker app not installed${NC}"
        echo "      Install from Play Store on emulator"
        ALL_GOOD=false
    fi
else
    echo -e "      ${YELLOW}⚠️  Cannot check (emulator not running)${NC}"
fi

# Check 4: Maestro
echo ""
echo -e "${CYAN}[4/6]${NC} Checking Maestro..."
MAESTRO_BIN="$HOME/.maestro/bin/maestro"
if [ -f "$MAESTRO_BIN" ]; then
    echo -e "      ${GREEN}✅ Maestro found: $MAESTRO_BIN${NC}"
else
    echo -e "      ${RED}❌ Maestro not found${NC}"
    echo "      Install: curl -Ls https://get.maestro.mobile.dev | bash"
    ALL_GOOD=false
fi

# Check 5: Java
echo ""
echo -e "${CYAN}[5/6]${NC} Checking Java..."
JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
if [ -d "$JAVA_HOME" ]; then
    echo -e "      ${GREEN}✅ Java found: $JAVA_HOME${NC}"
else
    echo -e "      ${YELLOW}⚠️  Java not found at expected location${NC}"
    echo "      Install: brew install openjdk@17"
fi

# Check 6: Test Credentials
echo ""
echo -e "${CYAN}[6/6]${NC} Checking Test Credentials..."
if [ -f "test_credentials.json" ]; then
    USER_COUNT=$(grep -c "email" test_credentials.json 2>/dev/null || echo "0")
    if [ "$USER_COUNT" -gt 0 ]; then
        echo -e "      ${GREEN}✅ Credentials found ($USER_COUNT user(s))${NC}"
    else
        echo -e "      ${YELLOW}⚠️  Credentials file exists but appears empty${NC}"
        echo "      Register user: python3 smart_test_runner.py --register"
    fi
else
    echo -e "      ${YELLOW}⚠️  No credentials file${NC}"
    echo "      Register user: python3 smart_test_runner.py --register"
    echo "      (Test 6 will be skipped)"
fi

# Check 7: Test Files
echo ""
echo -e "${CYAN}[7/7]${NC} Checking Test Files..."
if [ -d "organized_tests" ]; then
    TEST_COUNT=$(ls organized_tests/*.yaml 2>/dev/null | wc -l | tr -d ' ')
    echo -e "      ${GREEN}✅ Test files found ($TEST_COUNT files)${NC}"
else
    echo -e "      ${RED}❌ organized_tests directory not found${NC}"
    echo "      Generate: python3 test_organizer.py"
    ALL_GOOD=false
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if $ALL_GOOD; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED!${NC}"
    echo ""
    echo "You're ready to run the full test suite:"
    echo -e "${CYAN}  ./run_all_tests.sh${NC}"
else
    echo -e "${RED}⚠️  SOME CHECKS FAILED${NC}"
    echo ""
    echo "Fix the issues above before running tests."
    echo "See RUN_TESTS.txt for troubleshooting help."
fi

echo ""

