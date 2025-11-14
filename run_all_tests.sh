#!/bin/bash
#
# Whisker Complete Test Suite Runner
# Runs all 6 UI test categories in sequence
# Supports: Headless mode, Android, iOS, or both platforms
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MAESTRO_BIN="$HOME/.maestro/bin/maestro"
TEST_DIR="tests/organized"
STANDALONE_DIR="tests/standalone"
REGISTRATION_DIR="tests/registration"
JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

# Default options
HEADLESS_MODE=false
PLATFORM="android"  # android, ios, or both
TEST_SUITE="organized"  # organized, all, registration, or smoke
SINGLE_TEST=""
CUSTOM_LIST=""
LIST_TESTS=false
AUTO_STOP_STUDIO=false
GENERATE_REPORTS=false
REPEAT_COUNT=1  # Number of times to repeat the test suite
ENABLE_ANALYZE=false  # Enable Maestro AI analysis (Beta, requires cloud)

# Create timestamped report directory
REPORT_TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_DIR="reports/${REPORT_TIMESTAMP}"

# Screenshot directory (will be set after parsing args)
SCREENSHOT_DIR=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --headless)
            HEADLESS_MODE=true
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --suite)
            TEST_SUITE="$2"
            shift 2
            ;;
        --test)
            SINGLE_TEST="$2"
            shift 2
            ;;
        --custom)
            CUSTOM_LIST="$2"
            shift 2
            ;;
        --list)
            LIST_TESTS=true
            shift
            ;;
        --force)
            AUTO_STOP_STUDIO=true
            shift
            ;;
        --reports)
            GENERATE_REPORTS=true
            shift
            ;;
        --repeat)
            REPEAT_COUNT="$2"
            shift 2
            ;;
        --analyze)
            ENABLE_ANALYZE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --headless           Run tests in headless mode (no UI, faster)"
            echo "  --platform PLATFORM  Specify platform: android, ios, or both (default: android)"
            echo "  --suite SUITE        Test suite: smoke, organized, all, or registration (default: organized)"
            echo "  --test TEST          Run a single specific test (file path or name)"
            echo "  --custom FILE        Run tests from a custom list file"
            echo "  --list               List all available tests and exit"
            echo "  --force              Auto-stop Maestro Studio if running (no prompts)"
            echo "  --reports            Generate HTML and JUnit XML reports (saved to reports/)"
            echo "  --repeat N           Repeat the test suite N times (for stability/stress testing)"
            echo "  --analyze            Enable Maestro AI analysis (Beta, requires cloud, may be rate-limited)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Test Suites:"
            echo "  smoke         - ⚡ Critical tests only (Login, Shop, Profile) ~5-8 min [FASTEST]"
            echo "  organized     - 6 organized UI tests (Profile, Pets, Shop, Devices, Insights, Logout/Login)"
            echo "  all           - ALL tests including registration, login, UI tests, and organized tests"
            echo "  registration  - Registration + Login flow tests only"
            echo ""
            echo "Examples:"
            echo "  $0 --list                                          # Show all available tests"
            echo "  $0 --test 01_profile_account_tests.yaml            # Run single test"
            echo "  $0 --test whisker_ui_test.yaml --headless          # Run single test headless"
            echo "  $0 --custom my_tests.txt                           # Run custom test list"
            echo "  $0 --suite smoke --headless                        # ⚡ SMOKE TEST (5-8 min) [CI/CD]"
            echo "  $0 --suite smoke --repeat 10 --headless            # 🔁 Run smoke 10 times (stability check)"
            echo "  $0 --repeat 5 --reports                            # 🔁 Repeat organized suite 5x with reports"
            echo "  $0                                                 # Organized tests on Android with UI"
            echo "  $0 --headless                                      # Organized tests on Android headless"
            echo "  $0 --suite all                                     # ALL tests on Android with UI"
            echo "  $0 --suite all --headless                          # ALL tests on Android headless"
            echo "  $0 --suite registration                            # Registration/Login tests only"
            echo "  $0 --platform ios                                  # Organized tests on iOS with UI"
            echo "  $0 --platform both                                 # Organized tests on both platforms"
            echo "  $0 --headless --platform both --suite all          # ALL tests, both platforms, headless"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate suite
if [[ "$TEST_SUITE" != "smoke" && "$TEST_SUITE" != "organized" && "$TEST_SUITE" != "all" && "$TEST_SUITE" != "registration" ]]; then
    echo -e "${RED}Invalid test suite: $TEST_SUITE${NC}"
    echo "Valid options: smoke, organized, all, registration"
    exit 1
fi

# Validate platform
if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" && "$PLATFORM" != "both" ]]; then
    echo -e "${RED}Invalid platform: $PLATFORM${NC}"
    echo "Valid options: android, ios, both"
    exit 1
fi

# Validate repeat count
if ! [[ "$REPEAT_COUNT" =~ ^[0-9]+$ ]] || [ "$REPEAT_COUNT" -lt 1 ]; then
    echo -e "${RED}Invalid repeat count: $REPEAT_COUNT${NC}"
    echo "Repeat count must be a positive integer"
    exit 1
fi

# Set environment
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║          🚀 WHISKER COMPLETE TEST SUITE RUNNER 🚀            ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Set screenshot directory based on whether reports are enabled
if [ "$GENERATE_REPORTS" = true ]; then
    # When reports are enabled, save screenshots directly in report directory (no subdirectory)
    SCREENSHOT_DIR="$REPORT_DIR"
    mkdir -p "$REPORT_DIR"
    echo -e "${GREEN}📊 Report generation: ENABLED${NC}"
    echo -e "${BLUE}   Reports will be saved to: ${REPORT_DIR}/${NC}"
    echo -e "${BLUE}   Screenshots will be saved to: ${SCREENSHOT_DIR}/${NC}"
    echo ""
else
    # When reports are disabled, use standalone screenshots directory
    SCREENSHOT_DIR="screenshots"
    mkdir -p "$SCREENSHOT_DIR"
fi

# Calculate test count based on suite
TEST_COUNT=6
if [[ "$TEST_SUITE" == "smoke" ]]; then
    TEST_COUNT="3-4"
elif [[ "$TEST_SUITE" == "all" ]]; then
    TEST_COUNT="15+"
elif [[ "$TEST_SUITE" == "registration" ]]; then
    TEST_COUNT="2-3"
fi

echo -e "${BLUE}Test Suite:${NC}   $TEST_SUITE ($TEST_COUNT tests)"
echo -e "${BLUE}Platform:${NC}     $PLATFORM"
echo -e "${BLUE}Mode:${NC}         $([ "$HEADLESS_MODE" = true ] && echo "Headless (no UI)" || echo "Standard (with UI)")"
if [[ "$TEST_SUITE" == "smoke" ]]; then
    echo -e "${BLUE}Est. Time:${NC}    $([ "$HEADLESS_MODE" = true ] && echo "~3-5 minutes ⚡" || echo "~5-8 minutes ⚡")"
elif [[ "$TEST_SUITE" == "all" ]]; then
    echo -e "${BLUE}Est. Time:${NC}    $([ "$HEADLESS_MODE" = true ] && echo "~20-25 minutes" || echo "~30-35 minutes")"
elif [[ "$TEST_SUITE" == "registration" ]]; then
    echo -e "${BLUE}Est. Time:${NC}    ~5-7 minutes"
else
    echo -e "${BLUE}Est. Time:${NC}    $([ "$HEADLESS_MODE" = true ] && echo "~12-15 minutes" || echo "~20 minutes")"
fi
echo -e "${BLUE}Started:${NC}      $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Check devices based on platform
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    echo -e "${YELLOW}🔍 Checking Android device...${NC}"
    if command -v adb &> /dev/null; then
        ANDROID_COUNT=$(adb devices 2>/dev/null | grep -c "device$" || echo "0")
        if [ "$ANDROID_COUNT" -eq 0 ]; then
            echo -e "${RED}❌ No Android device/emulator detected!${NC}"
            echo "   Please start your Android emulator first."
            exit 1
        fi
        echo -e "${GREEN}✅ Android device detected${NC}"
    else
        echo -e "${RED}❌ ADB not found!${NC}"
        echo "   Add to PATH: export PATH=\$HOME/Library/Android/Sdk/platform-tools:\$PATH"
        exit 1
    fi
fi

if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "both" ]]; then
    echo -e "${YELLOW}🔍 Checking iOS Simulator...${NC}"
    if command -v xcrun &> /dev/null; then
        IOS_COUNT=$(xcrun simctl list devices | grep -c "Booted" || echo "0")
        if [ "$IOS_COUNT" -eq 0 ]; then
            echo -e "${RED}❌ No iOS Simulator running!${NC}"
            echo "   Please start an iOS Simulator first."
            exit 1
        fi
        echo -e "${GREEN}✅ iOS Simulator detected${NC}"
    else
        echo -e "${RED}❌ xcrun not found! (Xcode required for iOS)${NC}"
        exit 1
    fi
fi

echo ""

# Check if Maestro is installed
if [ ! -f "$MAESTRO_BIN" ]; then
    echo -e "${RED}❌ Maestro not found at: $MAESTRO_BIN${NC}"
    exit 1
fi

# Check if Maestro Studio is running (port 9999)
if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Maestro Studio detected running on port 9999${NC}"
    echo -e "${YELLOW}   This may interfere with automated tests.${NC}"
    echo ""
    
    if [ "$AUTO_STOP_STUDIO" = true ]; then
        # Auto-stop mode (for CI/CD or --force flag)
        echo -e "${YELLOW}Auto-stopping Maestro Studio (--force enabled)...${NC}"
        STUDIO_PID=$(lsof -Pi :9999 -sTCP:LISTEN -t)
        if [ -n "$STUDIO_PID" ]; then
            kill $STUDIO_PID 2>/dev/null
            sleep 2
            if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
                echo -e "${RED}❌ Could not stop Maestro Studio${NC}"
                echo "   Please stop it manually and try again"
                exit 1
            else
                echo -e "${GREEN}✅ Maestro Studio stopped${NC}"
            fi
        fi
    else
        # Interactive mode - give user options
        echo -e "${BLUE}Options:${NC}"
        echo "  1. Stop Maestro Studio manually and press Enter"
        echo "  2. Let the script try to stop it automatically"
        echo "  3. Continue anyway (may cause test failures)"
        echo ""
        echo -e "${DIM}Tip: Use --force flag to auto-stop without prompting${NC}"
        echo ""
        read -p "Choose (1/2/3): " choice
        
        case $choice in
            1)
                echo -e "${YELLOW}Waiting for you to stop Maestro Studio...${NC}"
                read -p "Press Enter when done..."
                ;;
            2)
                echo -e "${YELLOW}Attempting to stop Maestro Studio...${NC}"
                # Find and kill Maestro Studio process
                STUDIO_PID=$(lsof -Pi :9999 -sTCP:LISTEN -t)
                if [ -n "$STUDIO_PID" ]; then
                    kill $STUDIO_PID 2>/dev/null
                    sleep 2
                    if lsof -Pi :9999 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
                        echo -e "${RED}❌ Could not stop Maestro Studio${NC}"
                        echo "   Please stop it manually and try again"
                        exit 1
                    else
                        echo -e "${GREEN}✅ Maestro Studio stopped${NC}"
                    fi
                fi
                ;;
            3)
                echo -e "${YELLOW}⚠️  Continuing with Maestro Studio running...${NC}"
                echo -e "${YELLOW}   Tests may fail or behave unexpectedly.${NC}"
                sleep 2
                ;;
            *)
                echo -e "${RED}Invalid choice. Exiting.${NC}"
                exit 1
                ;;
        esac
    fi
    echo ""
fi

# Function to add report flags to maestro command
add_report_flags() {
    local cmd="$1"
    local test_name="$2"
    
    if [ "$GENERATE_REPORTS" = true ]; then
        # Sanitize test name for filename (remove path, extension, special chars)
        local safe_name=$(basename "$test_name" .yaml | sed 's/[^a-zA-Z0-9_-]/_/g')
        
        # Use iteration-specific report dir if in repeat mode, otherwise main report dir
        local target_dir="${ITERATION_REPORT_DIR:-$REPORT_DIR}"
        
        # Add JUnit XML report (primary format for CI/CD)
        cmd="$cmd --format=JUNIT --output=${target_dir}/${safe_name}_junit.xml"
    fi
    
    echo "$cmd"
}

# Function to extract error details from maestro output
extract_error_details() {
    local log_file="$1"
    local test_yaml_file="$2"  # Optional: path to YAML file for context
    local error_summary=""
    
    if [ ! -f "$log_file" ]; then
        echo "Log file not found"
        return
    fi
    
    # Extract key error information from Maestro output
    
    # Look for [Failed] lines with test name and error
    if grep -q "\[Failed\]" "$log_file"; then
        local failed_info=$(grep "\[Failed\]" "$log_file" | head -1)
        error_summary="${error_summary}${failed_info}\n"
    fi
    
    # Check for "Element not found" errors
    if grep -q "Element not found:" "$log_file"; then
        local element=$(grep "Element not found:" "$log_file" | head -1 | sed 's/.*Element not found: //' | sed 's/)$//')
        error_summary="${error_summary}• Element not found: $element\n"
    fi
    
    # Check for "Tap on" or other command failures
    if grep -qE "❌|✗|FAILED" "$log_file"; then
        local failed_cmd=$(grep -E "❌|✗|FAILED" "$log_file" | grep -v "Flow Failed" | head -3 | sed 's/^/• /')
        if [ -n "$failed_cmd" ]; then
            error_summary="${error_summary}${failed_cmd}\n"
        fi
    fi
    
    # Check for timeout errors
    if grep -qi "timed out\|timeout\|TimeoutException" "$log_file"; then
        error_summary="${error_summary}• Test timed out\n"
    fi
    
    # Look for assertion failures
    if grep -q "Assertion failed\|assertVisible\|assertNotVisible" "$log_file"; then
        local assertion=$(grep -E "Assertion failed|assertVisible|assertNotVisible" "$log_file" | head -1 | cut -c1-120)
        error_summary="${error_summary}• $assertion\n"
    fi
    
    # Extract YAML file line numbers (format: file.yaml:line)
    if grep -qE "\\.yaml:[0-9]+" "$log_file"; then
        local file_line=$(grep -oE "[^/]+\\.yaml:[0-9]+" "$log_file" | head -1)
        error_summary="${error_summary}• Location: $file_line\n"
    fi
    
    # Try to find the line number in different formats
    if grep -qE "line [0-9]+" "$log_file"; then
        local line_num=$(grep -oE "line [0-9]+" "$log_file" | head -1)
        error_summary="${error_summary}• Error at $line_num\n"
    fi
    
    # Look for "> Flow:" lines which show which flow failed
    if grep -q "> Flow:" "$log_file"; then
        local flow_name=$(grep "> Flow:" "$log_file" | tail -1 | sed 's/.*> Flow: //')
        error_summary="${error_summary}• Failed in flow: $flow_name\n"
    fi
    
    # Extract last command before failure
    if grep -qE "^- (tapOn|inputText|scrollUntilVisible|assertVisible|waitFor)" "$log_file"; then
        local last_cmd=$(grep -E "^- (tapOn|inputText|scrollUntilVisible|assertVisible|waitFor)" "$log_file" | tail -3 | sed 's/^/  /')
        if [ -n "$last_cmd" ]; then
            error_summary="${error_summary}• Last commands:\n${last_cmd}\n"
        fi
    fi
    
    # If we have the YAML file path, try to find the failing line
    if [ -n "$test_yaml_file" ] && [ -f "$test_yaml_file" ]; then
        # Extract the failing element/text from error
        local failing_element=$(echo "$error_summary" | grep -oE "Element not found: .*" | head -1 | sed 's/Element not found: //' | sed 's/Text matching regex: //')
        
        if [ -n "$failing_element" ]; then
            # Search for this element in the YAML file
            local yaml_line=$(grep -n "$failing_element" "$test_yaml_file" 2>/dev/null | head -1 | cut -d: -f1)
            if [ -n "$yaml_line" ]; then
                error_summary="${error_summary}• YAML Line: $(basename "$test_yaml_file"):${yaml_line}\n"
            fi
        fi
    fi
    
    # Get test duration if available
    if grep -qE "\([0-9]+m [0-9]+s\)|\([0-9]+s\)" "$log_file"; then
        local duration=$(grep -oE "\([0-9]+m [0-9]+s\)|\([0-9]+s\)" "$log_file" | tail -1)
        error_summary="${error_summary}• Duration: $duration\n"
    fi
    
    # If no specific error found, get relevant lines from the end
    if [ -z "$error_summary" ]; then
        error_summary=$(tail -10 "$log_file" | grep -v "^$" | sed 's/^/• /' | head -5)
    fi
    
    echo -e "$error_summary"
}

# Function to list all tests
list_all_tests() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║                📋 AVAILABLE WHISKER TESTS                     ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${BLUE}━━━ REGISTRATION & LOGIN TESTS ━━━${NC}"
    echo "  • registration     - python3 smart_test_runner.py --register"
    echo "  • login            - python3 smart_test_runner.py --login"
    echo ""
    
    echo -e "${BLUE}━━━ STANDALONE TESTS ━━━${NC}"
    if ls tests/standalone/*.yaml 2>/dev/null > /dev/null; then
        ls tests/standalone/*.yaml 2>/dev/null | while read -r file; do
            basename_file=$(basename "$file")
            echo "  • $basename_file"
        done
    else
        # Fallback to root directory for backward compatibility
        if ls *.yaml 2>/dev/null | grep -v "generated_" | grep -v "Flow.yaml" > /dev/null; then
            ls *.yaml 2>/dev/null | grep -v "generated_" | grep -v "Flow.yaml" | while read -r file; do
                echo "  • $file"
            done
        else
            echo "  (None found)"
        fi
    fi
    echo ""
    
    echo -e "${BLUE}━━━ ORGANIZED TEST SUITE ━━━${NC}"
    if ls tests/organized/*.yaml 2>/dev/null | grep -v "_prepared" > /dev/null; then
        ls tests/organized/*.yaml 2>/dev/null | grep -v "_prepared" | while read -r file; do
            basename_file=$(basename "$file")
            echo "  • $basename_file"
        done
    else
        # Fallback to old directory
        if ls organized_tests/*.yaml 2>/dev/null | grep -v "_prepared" > /dev/null; then
            ls organized_tests/*.yaml 2>/dev/null | grep -v "_prepared" | while read -r file; do
                basename_file=$(basename "$file")
                echo "  • $basename_file"
            done
        else
            echo "  (None found)"
        fi
    fi
    echo ""
    
    echo -e "${YELLOW}━━━ USAGE ━━━${NC}"
    echo "Run single test:  ./run_all_tests.sh --test <filename>"
    echo "Example:          ./run_all_tests.sh --test 01_profile_account_tests.yaml"
    echo ""
    echo "Run custom list:  ./run_all_tests.sh --custom my_tests.txt"
    echo "                  (Create my_tests.txt with one test per line)"
    echo ""
}

# If --list flag, show tests and exit
if [ "$LIST_TESTS" = true ]; then
    list_all_tests
    exit 0
fi

# Start time
START_TIME_EPOCH=$(date +%s)
START_TIME_DISPLAY=$(date '+%Y-%m-%d %H:%M:%S')

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=()
PASSED_TEST_NAMES=()

# Failure details tracking (parallel arrays)
declare -a FAILURE_DETAILS
declare -a FAILURE_LOGS

# Repeat/iteration tracking
declare -a ITERATION_RESULTS  # Track pass/fail count per iteration
declare -a ITERATION_DURATIONS  # Track duration per iteration
CURRENT_ITERATION=1

# Create logs directory for failed tests
mkdir -p "$REPORT_DIR/logs" 2>/dev/null || true

# Show repeat info if applicable
if [ "$REPEAT_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}🔁 Repeat Mode: Will run test suite $REPEAT_COUNT times${NC}"
    echo -e "${YELLOW}   This is useful for finding intermittent failures and stability testing${NC}"
    echo ""
fi

# Function to run smoke tests (critical path only)
run_smoke_tests() {
    local current_platform=$1
    local platform_label=$2
    
    echo -e "${BLUE}⚡ Running SMOKE TEST Suite (Critical Paths Only)${NC}"
    echo ""
    
    # Test 1: Login test (authentication critical)
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 SMOKE TEST 1/3: Login Flow${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if python3 smart_test_runner.py --login; then
        echo ""
        echo -e "${GREEN}✅ PASSED: Login Flow${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_TEST_NAMES+=("Login Flow")
    else
        echo ""
        echo -e "${RED}❌ FAILED: Login Flow${NC}"
        FAILED_TESTS+=("Login Flow")
    fi
    
    echo ""
    echo -e "${YELLOW}⏸️  Pausing for 2 seconds...${NC}"
    sleep 2
    
    # Test 2: Shop (most common user flow)
    run_test "$TEST_DIR/03_shop_commerce_tests.yaml" "2/3" "$current_platform"
    
    # Test 3: Profile (critical user data)
    run_test "$TEST_DIR/01_profile_account_tests.yaml" "3/3" "$current_platform"
    
    echo ""
    echo -e "${GREEN}⚡ Smoke test complete!${NC}"
}

# Function to run registration test
run_registration_test() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 REGISTRATION TEST: Create new user${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if python3 smart_test_runner.py --register; then
        echo ""
        echo -e "${GREEN}✅ PASSED: Registration test${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_TEST_NAMES+=("Registration test")
    else
        echo ""
        echo -e "${RED}❌ FAILED: Registration test${NC}"
        FAILED_TESTS+=("Registration test")
    fi
    
    echo ""
    echo -e "${YELLOW}⏸️  Pausing for 2 seconds...${NC}"
    sleep 2
}

# Function to run login test
run_login_test() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 LOGIN TEST: Login with existing credentials${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if python3 smart_test_runner.py --login; then
        echo ""
        echo -e "${GREEN}✅ PASSED: Login test${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_TEST_NAMES+=("Login test")
    else
        echo ""
        echo -e "${RED}❌ FAILED: Login test${NC}"
        FAILED_TESTS+=("Login test")
    fi
    
    echo ""
    echo -e "${YELLOW}⏸️  Pausing for 2 seconds...${NC}"
    sleep 2
}

# Function to run standalone test files
run_standalone_tests() {
    echo ""
    echo -e "${BLUE}📱 Running Standalone Test Files${NC}"
    echo ""
    
    # Check for tests in new location first, fallback to root
    local test_base_dir="tests/standalone"
    if [ ! -d "$test_base_dir" ] || [ -z "$(ls -A $test_base_dir 2>/dev/null)" ]; then
        test_base_dir="."
    fi
    
    # List of standalone test files
    local standalone_files=(
        "whisker_ui_test.yaml"
        "whisker_advanced_test2.yaml"
        "whisker_advanced_test.yaml"
        "whisker_stress_test.yaml"
    )
    
    for test_file in "${standalone_files[@]}"; do
        full_path="$test_base_dir/$test_file"
        if [[ -f "$full_path" ]]; then
            test_file="$full_path"
        elif [[ -f "$test_file" ]]; then
            # Fallback to root directory
            test_file="$test_file"
        else
            continue
        fi
        
        if [[ -f "$test_file" ]]; then
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}🧪 STANDALONE TEST: $test_file${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            
            MAESTRO_CMD="$MAESTRO_BIN test"
            if [ "$HEADLESS_MODE" = true ]; then
                MAESTRO_CMD="$MAESTRO_CMD --headless"
            fi
            # Add output, logging, and analysis flags
            MAESTRO_CMD="$MAESTRO_CMD --test-output-dir=$SCREENSHOT_DIR --flatten-debug-output"
            MAESTRO_CMD="$MAESTRO_CMD --debug-output=maestro_debug_output"
            
            # Enable AI-enhanced analysis (Beta feature - optional, may be rate-limited)
            if [ "$ENABLE_ANALYZE" = true ]; then
                MAESTRO_CMD="$MAESTRO_CMD --analyze"
            fi
            
            # Add report flags if enabled
            MAESTRO_CMD=$(add_report_flags "$MAESTRO_CMD" "$test_file")
            
            # Add test file at the end
            MAESTRO_CMD="$MAESTRO_CMD $test_file"
            
            # Run test with full live UI (no redirection for better UX)
            if eval "$MAESTRO_CMD"; then
                echo ""
                echo -e "${GREEN}✅ PASSED: $test_file${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                PASSED_TEST_NAMES+=("$(basename "$test_file" .yaml)")
            else
                echo ""
                echo -e "${RED}❌ FAILED: $test_file${NC}"
                FAILED_TESTS+=("$test_file")
                
                # Only capture logs on failure (if reports enabled)
                if [ "$GENERATE_REPORTS" = true ]; then
                    # Use iteration-specific directory if in repeat mode
                    local log_dir="${ITERATION_REPORT_DIR:-$REPORT_DIR}/logs"
                    mkdir -p "$log_dir"
                    TEST_LOG="${log_dir}/$(basename "$test_file" .yaml)_$(date +%s).log"
                    
                    # Re-run to capture output with full detail using script command
                    # script creates a pseudo-TTY so Maestro shows detailed output
                    echo -e "${YELLOW}📝 Capturing detailed error log...${NC}"
                    script -q "$TEST_LOG" bash -c "eval '$MAESTRO_CMD'" || true
                    
                    # Clean up script output artifacts (removes terminal control codes)
                    if [ -f "$TEST_LOG" ]; then
                        # Remove terminal escape sequences for cleaner logs
                        sed -i.bak $'s/\x1b\\[[0-9;]*m//g' "$TEST_LOG" 2>/dev/null || true
                        rm -f "${TEST_LOG}.bak"
                    fi
                    
                    # Extract and store error details
                    ERROR_DETAILS=$(extract_error_details "$TEST_LOG" "$test_file")
                    FAILURE_DETAILS+=("$ERROR_DETAILS")
                    FAILURE_LOGS+=("$TEST_LOG")
                    
                    # Show error summary in terminal
                    echo -e "${YELLOW}Error Details:${NC}"
                    echo -e "$ERROR_DETAILS"
                else
                    # No reports - just note the failure
                    FAILURE_DETAILS+=("Test failed - run with --reports for details")
                    FAILURE_LOGS+=("")
                fi
            fi
            
            echo ""
            echo -e "${YELLOW}⏸️  Pausing for 2 seconds...${NC}"
            sleep 2
        fi
    done
}

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .yaml)
    local test_num=$2
    local current_platform=$3
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 TEST $test_num: $test_name${NC}"
    if [[ "$PLATFORM" == "both" ]]; then
        echo -e "${CYAN}   Platform: $current_platform${NC}"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Build maestro command
    MAESTRO_CMD="$MAESTRO_BIN test"
    
    # Add headless flag if enabled
    if [ "$HEADLESS_MODE" = true ]; then
        MAESTRO_CMD="$MAESTRO_CMD --headless"
    fi
    
    # Add screenshot output directory with flatten flag to prevent nested directories
    MAESTRO_CMD="$MAESTRO_CMD --test-output-dir=$SCREENSHOT_DIR --flatten-debug-output"
    MAESTRO_CMD="$MAESTRO_CMD --debug-output=maestro_debug_output"
    
    # Enable AI-enhanced analysis (Beta feature - optional, may be rate-limited)
    if [ "$ENABLE_ANALYZE" = true ]; then
        MAESTRO_CMD="$MAESTRO_CMD --analyze"
    fi
    
    # Add report flags if enabled
    MAESTRO_CMD=$(add_report_flags "$MAESTRO_CMD" "$test_file")
    
    # Add test file
    MAESTRO_CMD="$MAESTRO_CMD $test_file"
    
    # Run test with full live UI (no redirection for better UX)
    if eval "$MAESTRO_CMD"; then
        echo ""
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_TEST_NAMES+=("$test_name")
    else
        echo ""
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        FAILED_TESTS+=("$test_name ($current_platform)")
        
        # Only capture logs on failure (if reports enabled)
        if [ "$GENERATE_REPORTS" = true ]; then
            # Use iteration-specific directory if in repeat mode
            local log_dir="${ITERATION_REPORT_DIR:-$REPORT_DIR}/logs"
            mkdir -p "$log_dir"
            TEST_LOG="${log_dir}/${test_name}_$(date +%s).log"
            
            # Re-run to capture output with full detail using script command
            # script creates a pseudo-TTY so Maestro shows detailed output
            echo -e "${YELLOW}📝 Capturing detailed error log...${NC}"
            script -q "$TEST_LOG" bash -c "eval '$MAESTRO_CMD'" || true
            
            # Clean up script output artifacts (removes terminal control codes)
            if [ -f "$TEST_LOG" ]; then
                # Remove terminal escape sequences for cleaner logs
                sed -i.bak $'s/\x1b\\[[0-9;]*m//g' "$TEST_LOG" 2>/dev/null || true
                rm -f "${TEST_LOG}.bak"
            fi
            
            # Extract and store error details
            ERROR_DETAILS=$(extract_error_details "$TEST_LOG" "$test_file")
            FAILURE_DETAILS+=("$ERROR_DETAILS")
            FAILURE_LOGS+=("$TEST_LOG")
            
            # Show error summary in terminal
            echo -e "${YELLOW}Error Details:${NC}"
            echo -e "$ERROR_DETAILS"
        else
            # No reports - just note the failure
            FAILURE_DETAILS+=("Test failed - run with --reports for details")
            FAILURE_LOGS+=("")
        fi
    fi
    
    # Brief pause between tests
    echo ""
    echo -e "${YELLOW}⏸️  Pausing for 2 seconds...${NC}"
    sleep 2
}

# Function to run all tests on a specific platform
run_platform_tests() {
    local current_platform=$1
    local platform_label=$2
    
    echo -e "${BLUE}📱 Running UI Test Suite on $platform_label${NC}"
    echo ""
    
    # Test files (01-05)
    local test_files=(
        "$TEST_DIR/01_profile_account_tests.yaml"
        "$TEST_DIR/02_pet_management_tests.yaml"
        "$TEST_DIR/03_shop_commerce_tests.yaml"
        "$TEST_DIR/04_device_management_tests.yaml"
        "$TEST_DIR/05_insights_analytics_tests.yaml"
    )
    
    local test_num=1
    for test_file in "${test_files[@]}"; do
        # For iOS, use the iOS version if it exists
        if [[ "$current_platform" == "ios" ]]; then
            ios_test_file="${test_file%.yaml}_ios.yaml"
            if [[ -f "$ios_test_file" ]]; then
                run_test "$ios_test_file" "$test_num" "$current_platform"
            else
                run_test "$test_file" "$test_num" "$current_platform"
            fi
        else
            run_test "$test_file" "$test_num" "$current_platform"
        fi
        test_num=$((test_num + 1))
    done
    
    # Logout/Login test
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 TEST 6: logout_login_tests${NC}"
    if [[ "$PLATFORM" == "both" ]]; then
        echo -e "${CYAN}   Platform: $current_platform${NC}"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📧 Preparing test with saved credentials...${NC}"
    
    if python3 prepare_logout_login_test.py; then
        echo ""
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        MAESTRO_CMD="$MAESTRO_BIN test"
        if [ "$HEADLESS_MODE" = true ]; then
            MAESTRO_CMD="$MAESTRO_CMD --headless"
        fi
        
        MAESTRO_CMD="$MAESTRO_CMD --test-output-dir=$SCREENSHOT_DIR --flatten-debug-output"
        MAESTRO_CMD="$MAESTRO_CMD --debug-output=maestro_debug_output"
        
        # Enable AI-enhanced analysis (Beta feature - optional, may be rate-limited)
        if [ "$ENABLE_ANALYZE" = true ]; then
            MAESTRO_CMD="$MAESTRO_CMD --analyze"
        fi
        
        # Determine test file
        if [[ "$current_platform" == "ios" ]] && [[ -f "$TEST_DIR/06_logout_login_tests_prepared_ios.yaml" ]]; then
            TEST_FILE="$TEST_DIR/06_logout_login_tests_prepared_ios.yaml"
        else
            TEST_FILE="$TEST_DIR/06_logout_login_tests_prepared.yaml"
        fi
        
        # Add report flags if enabled
        MAESTRO_CMD=$(add_report_flags "$MAESTRO_CMD" "logout_login_tests")
        
        # Add test file
        MAESTRO_CMD="$MAESTRO_CMD $TEST_FILE"
        
        # Run test with full live UI (no redirection for better UX)
        if eval "$MAESTRO_CMD"; then
            echo ""
            echo -e "${GREEN}✅ PASSED: logout_login_tests${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            PASSED_TEST_NAMES+=("logout_login_tests")
        else
            echo ""
            echo -e "${RED}❌ FAILED: logout_login_tests${NC}"
            FAILED_TESTS+=("logout_login_tests ($current_platform)")
            
            # Only capture logs on failure (if reports enabled)
            if [ "$GENERATE_REPORTS" = true ]; then
                # Use iteration-specific directory if in repeat mode
                local log_dir="${ITERATION_REPORT_DIR:-$REPORT_DIR}/logs"
                mkdir -p "$log_dir"
                TEST_LOG="${log_dir}/logout_login_tests_$(date +%s).log"
                
                # Re-run to capture output with full detail using script command
                # script creates a pseudo-TTY so Maestro shows detailed output
                echo -e "${YELLOW}📝 Capturing detailed error log...${NC}"
                script -q "$TEST_LOG" bash -c "eval '$MAESTRO_CMD'" || true
                
                # Clean up script output artifacts (removes terminal control codes)
                if [ -f "$TEST_LOG" ]; then
                    # Remove terminal escape sequences for cleaner logs
                    sed -i.bak $'s/\x1b\\[[0-9;]*m//g' "$TEST_LOG" 2>/dev/null || true
                    rm -f "${TEST_LOG}.bak"
                fi
                
                # Extract and store error details
                ERROR_DETAILS=$(extract_error_details "$TEST_LOG" "$TEST_FILE")
                FAILURE_DETAILS+=("$ERROR_DETAILS")
                FAILURE_LOGS+=("$TEST_LOG")
                
                # Show error summary in terminal
                echo -e "${YELLOW}Error Details:${NC}"
                echo -e "$ERROR_DETAILS"
            else
                # No reports - just note the failure
                FAILURE_DETAILS+=("Test failed - run with --reports for details")
                FAILURE_LOGS+=("")
            fi
        fi
    else
        echo ""
        echo -e "${RED}❌ FAILED: Could not prepare logout/login test (no saved credentials?)${NC}"
        FAILED_TESTS+=("logout_login_tests ($current_platform)")
    fi
}

# ==============================================================================
# MAIN TEST EXECUTION LOOP (supports --repeat for multiple iterations)
# ==============================================================================

for ((CURRENT_ITERATION=1; CURRENT_ITERATION<=REPEAT_COUNT; CURRENT_ITERATION++)); do
    # Reset test counters for this iteration
    ITERATION_START_TIME=$(date +%s)
    ITERATION_TOTAL=0
    ITERATION_PASSED=0
    ITERATION_FAILED=()
    
    # Create iteration-specific subdirectories for reports
    if [ "$GENERATE_REPORTS" = true ] && [ "$REPEAT_COUNT" -gt 1 ]; then
        ITERATION_REPORT_DIR="$REPORT_DIR/iteration_$CURRENT_ITERATION"
        mkdir -p "$ITERATION_REPORT_DIR"
        mkdir -p "$ITERATION_REPORT_DIR/logs"
        
        # Screenshots go directly in iteration dir (no subdirectory)
        SCREENSHOT_DIR="$ITERATION_REPORT_DIR"
    elif [ "$GENERATE_REPORTS" = true ]; then
        # Single iteration - use main report dir
        ITERATION_REPORT_DIR="$REPORT_DIR"
    fi
    
    # Show iteration header if repeating
    if [ "$REPEAT_COUNT" -gt 1 ]; then
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                                                               ║${NC}"
        echo -e "${CYAN}║           🔁 ITERATION $CURRENT_ITERATION of $REPEAT_COUNT${NC}"
        echo -e "${CYAN}║                                                               ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        if [ "$GENERATE_REPORTS" = true ]; then
            echo -e "${BLUE}   Reports for this iteration: ${ITERATION_REPORT_DIR}${NC}"
        fi
        echo ""
        sleep 1
    fi
    
    # Handle single test execution
    if [[ -n "$SINGLE_TEST" ]]; then
    echo -e "${CYAN}🎯 Running Single Test${NC}"
    echo ""
    
    # Find the test file (check multiple locations)
    TEST_FILE=""
    if [[ -f "$SINGLE_TEST" ]]; then
        TEST_FILE="$SINGLE_TEST"
    elif [[ -f "tests/organized/$SINGLE_TEST" ]]; then
        TEST_FILE="tests/organized/$SINGLE_TEST"
    elif [[ -f "tests/standalone/$SINGLE_TEST" ]]; then
        TEST_FILE="tests/standalone/$SINGLE_TEST"
    elif [[ -f "tests/registration/$SINGLE_TEST" ]]; then
        TEST_FILE="tests/registration/$SINGLE_TEST"
    elif [[ -f "organized_tests/$SINGLE_TEST" ]]; then
        TEST_FILE="organized_tests/$SINGLE_TEST"
    elif [[ -f "$TEST_DIR/$SINGLE_TEST" ]]; then
        TEST_FILE="$TEST_DIR/$SINGLE_TEST"
    else
        echo -e "${RED}❌ Test file not found: $SINGLE_TEST${NC}"
        echo ""
        echo "Available tests:"
        list_all_tests
        exit 1
    fi
    
    # Check if it's a special test
    if [[ "$SINGLE_TEST" == "registration" ]]; then
        run_registration_test
    elif [[ "$SINGLE_TEST" == "login" ]]; then
        run_login_test
    else
        # Run the test file
        run_test "$TEST_FILE" "1/1" "$PLATFORM"
    fi
    
    # Skip to summary
    echo ""
    # Continue to summary section at end
    
# Handle custom test list
elif [[ -n "$CUSTOM_LIST" ]]; then
    if [[ ! -f "$CUSTOM_LIST" ]]; then
        echo -e "${RED}❌ Custom test list not found: $CUSTOM_LIST${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📝 Running Custom Test List: $CUSTOM_LIST${NC}"
    echo ""
    
    test_count=0
    while IFS= read -r test_line || [[ -n "$test_line" ]]; do
        # Skip empty lines and comments
        [[ -z "$test_line" || "$test_line" =~ ^[[:space:]]*# ]] && continue
        
        test_count=$((test_count + 1))
        
        # Check if it's a special test
        if [[ "$test_line" == "registration" ]]; then
            run_registration_test
        elif [[ "$test_line" == "login" ]]; then
            run_login_test
        else
            # Find the test file (check multiple locations)
            TEST_FILE=""
            if [[ -f "$test_line" ]]; then
                TEST_FILE="$test_line"
            elif [[ -f "tests/organized/$test_line" ]]; then
                TEST_FILE="tests/organized/$test_line"
            elif [[ -f "tests/standalone/$test_line" ]]; then
                TEST_FILE="tests/standalone/$test_line"
            elif [[ -f "tests/registration/$test_line" ]]; then
                TEST_FILE="tests/registration/$test_line"
            elif [[ -f "organized_tests/$test_line" ]]; then
                TEST_FILE="organized_tests/$test_line"
            elif [[ -f "$TEST_DIR/$test_line" ]]; then
                TEST_FILE="$TEST_DIR/$test_line"
            else
                echo -e "${YELLOW}⚠️  Skipping: Test file not found: $test_line${NC}"
                continue
            fi
            
            run_test "$TEST_FILE" "$test_count" "$PLATFORM"
        fi
    done < "$CUSTOM_LIST"
    
    echo ""
    echo -e "${GREEN}📝 Custom test list complete!${NC}"
    
# Run tests based on suite selection
elif [[ "$TEST_SUITE" == "smoke" ]]; then
    # Smoke tests only (critical paths)
    if [[ "$PLATFORM" == "both" ]]; then
        echo -e "${CYAN}⚡ Running smoke tests on BOTH platforms${NC}"
        echo ""
        
        # Run on Android first
        run_smoke_tests "android" "Android"
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}📱 Switching to iOS...${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        sleep 3
        
        # Then run on iOS
        run_smoke_tests "ios" "iOS"
        
    elif [[ "$PLATFORM" == "ios" ]]; then
        run_smoke_tests "ios" "iOS"
    else
        run_smoke_tests "android" "Android"
    fi
    
elif [[ "$TEST_SUITE" == "registration" ]]; then
    # Registration suite only
    echo -e "${BLUE}🔐 Running Registration & Login Tests${NC}"
    echo ""
    
    run_registration_test
    run_login_test
    
elif [[ "$TEST_SUITE" == "all" ]]; then
    # ALL tests: registration, login, standalone, and organized
    echo -e "${BLUE}🌟 Running COMPLETE Test Suite (ALL)${NC}"
    echo ""
    
    # 1. Registration and Login
    echo -e "${YELLOW}══════ PHASE 1: Registration & Login ══════${NC}"
    run_registration_test
    run_login_test
    
    # 2. Standalone tests
    echo ""
    echo -e "${YELLOW}══════ PHASE 2: Standalone Tests ══════${NC}"
    run_standalone_tests
    
    # 3. Organized tests (based on platform)
    echo ""
    echo -e "${YELLOW}══════ PHASE 3: Organized Test Suite ══════${NC}"
    
    if [[ "$PLATFORM" == "both" ]]; then
        echo -e "${CYAN}🔄 Running organized tests on BOTH platforms${NC}"
        echo ""
        
        # Run on Android first
        run_platform_tests "android" "Android"
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}📱 Switching to iOS...${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        sleep 3
        
        # Then run on iOS
        run_platform_tests "ios" "iOS"
        
    elif [[ "$PLATFORM" == "ios" ]]; then
        run_platform_tests "ios" "iOS"
    else
        run_platform_tests "android" "Android"
    fi
    
else
    # Organized tests only (default)
    if [[ "$PLATFORM" == "both" ]]; then
        echo -e "${CYAN}🔄 Running organized tests on BOTH platforms${NC}"
        echo ""
        
        # Run on Android first
        run_platform_tests "android" "Android"
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}📱 Switching to iOS...${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        sleep 3
        
        # Then run on iOS
        run_platform_tests "ios" "iOS"
        
    elif [[ "$PLATFORM" == "ios" ]]; then
        run_platform_tests "ios" "iOS"
    else
        run_platform_tests "android" "Android"
    fi
fi

    # Track iteration results
    ITERATION_END_TIME=$(date +%s)
    ITERATION_ELAPSED=$((ITERATION_END_TIME - ITERATION_START_TIME))
    ITERATION_MINUTES=$((ITERATION_ELAPSED / 60))
    ITERATION_SECONDS=$((ITERATION_ELAPSED % 60))
    
    # Store iteration statistics
    ITERATION_RESULTS+=("$PASSED_TESTS/$TOTAL_TESTS")
    ITERATION_DURATIONS+=("${ITERATION_MINUTES}m ${ITERATION_SECONDS}s")
    
    # Show iteration summary if repeating
    if [ "$REPEAT_COUNT" -gt 1 ]; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}🔁 ITERATION $CURRENT_ITERATION COMPLETE${NC}"
        echo -e "${YELLOW}   Passed: $PASSED_TESTS/$TOTAL_TESTS   Duration: ${ITERATION_MINUTES}m ${ITERATION_SECONDS}s${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Brief pause between iterations (except on last one)
        if [ $CURRENT_ITERATION -lt $REPEAT_COUNT ]; then
            echo ""
            echo -e "${BLUE}⏸️  Pausing for 5 seconds before next iteration...${NC}"
            sleep 5
        fi
    fi

done  # End of repeat loop

# Calculate total elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME_EPOCH))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

# Print summary
echo ""
echo ""
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║                    📊 TEST SUITE SUMMARY                      ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BLUE}Test Suite:${NC}      $TEST_SUITE"
echo -e "${BLUE}Platform(s):${NC}     $PLATFORM"
echo -e "${BLUE}Mode:${NC}            $([ "$HEADLESS_MODE" = true ] && echo "Headless" || echo "Standard")"
echo -e "${BLUE}Total Tests:${NC}     $TOTAL_TESTS"
echo -e "${GREEN}✅ Passed:${NC}       $PASSED_TESTS"
echo -e "${RED}❌ Failed:${NC}       ${#FAILED_TESTS[@]}"
echo ""

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${BLUE}Success Rate:${NC}    ${SUCCESS_RATE}%"
else
    echo -e "${BLUE}Success Rate:${NC}    N/A"
fi

echo ""
echo -e "${BLUE}Total Time:${NC}      ${MINUTES}m ${SECONDS}s"
echo -e "${BLUE}Finished:${NC}        $(date '+%Y-%m-%d %H:%M:%S')"

# Show iteration breakdown if multiple runs
if [ "$REPEAT_COUNT" -gt 1 ]; then
    echo ""
    echo -e "${YELLOW}🔁 Iteration Breakdown:${NC}"
    for ((i=0; i<REPEAT_COUNT; i++)); do
        iter_num=$((i + 1))
        iter_result="${ITERATION_RESULTS[$i]}"
        iter_duration="${ITERATION_DURATIONS[$i]}"
        echo -e "  ${BLUE}Iteration $iter_num:${NC} $iter_result passed   ${BLUE}(${iter_duration})${NC}"
    done
fi

# List failed tests if any
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}❌${NC} $test"
    done
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Generate HTML summary report if reports are enabled
if [ "$GENERATE_REPORTS" = true ]; then
    echo ""
    echo -e "${BLUE}📊 Generating summary report...${NC}"
    
    # Main summary report location
    HTML_REPORT="$REPORT_DIR/summary.html"
    
    # If multiple iterations, also note we'll create per-iteration summaries
    if [ "$REPEAT_COUNT" -gt 1 ]; then
        echo -e "${BLUE}   • Master summary: $HTML_REPORT${NC}"
        echo -e "${BLUE}   • Per-iteration reports: $REPORT_DIR/iteration_*/summary.html${NC}"
    fi
    
    cat > "$HTML_REPORT" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Whisker Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2.5em;
        }
        .header p {
            margin: 5px 0;
            opacity: 0.9;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            margin: 0 0 10px 0;
            font-size: 0.9em;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stat-value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 0;
        }
        .passed { color: #10b981; }
        .failed { color: #ef4444; }
        .total { color: #3b82f6; }
        .rate { color: #8b5cf6; }
        .test-list {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .test-list h2 {
            margin-top: 0;
            color: #333;
        }
        .test-item {
            padding: 15px;
            margin: 10px 0;
            border-left: 4px solid;
            background: #f9fafb;
            border-radius: 4px;
        }
        .test-item.pass {
            border-left-color: #10b981;
        }
        .test-item.fail {
            border-left-color: #ef4444;
        }
        .test-name {
            font-weight: 600;
            margin-bottom: 5px;
        }
        .test-status {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .status-pass {
            background: #d1fae5;
            color: #065f46;
        }
        .status-fail {
            background: #fee2e2;
            color: #991b1b;
        }
        .error-details {
            margin-top: 10px;
            padding: 12px;
            background: #fef3c7;
            border-left: 3px solid #f59e0b;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.85em;
            color: #92400e;
            white-space: pre-wrap;
            overflow-x: auto;
        }
        .error-details strong {
            color: #78350f;
            display: block;
            margin-bottom: 8px;
        }
        .log-link {
            display: inline-block;
            margin-top: 8px;
            padding: 4px 8px;
            background: #fff;
            border: 1px solid #f59e0b;
            border-radius: 4px;
            color: #92400e;
            text-decoration: none;
            font-size: 0.8em;
        }
        .log-link:hover {
            background: #fef3c7;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            color: #6b7280;
        }
        .junit-links {
            background: #fffbeb;
            border: 1px solid #fcd34d;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .junit-links h3 {
            margin-top: 0;
            color: #92400e;
        }
        .junit-links ul {
            margin: 10px 0;
            padding-left: 20px;
        }
        .junit-links a {
            color: #1d4ed8;
            text-decoration: none;
        }
        .junit-links a:hover {
            text-decoration: underline;
        }
        .iterations {
            background: #eff6ff;
            border: 1px solid #3b82f6;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .iterations h3 {
            margin-top: 0;
            color: #1e40af;
        }
        .iteration-item {
            padding: 10px;
            margin: 8px 0;
            background: white;
            border-radius: 4px;
            border-left: 3px solid #3b82f6;
        }
        .iteration-item a {
            color: #1d4ed8;
            text-decoration: none;
            font-weight: 600;
        }
        .iteration-item a:hover {
            text-decoration: underline;
        }
        .iteration-pass {
            color: #10b981;
            font-weight: 600;
        }
        .iteration-fail {
            color: #ef4444;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🐾 Whisker Test Report</h1>
        <p><strong>Test Suite:</strong> TEST_SUITE_PLACEHOLDER</p>
        <p><strong>Platform:</strong> PLATFORM_PLACEHOLDER</p>
        <p><strong>Mode:</strong> MODE_PLACEHOLDER</p>
        <p><strong>Repeat Count:</strong> REPEAT_COUNT_PLACEHOLDER</p>
        <p><strong>Started:</strong> START_TIME_PLACEHOLDER</p>
        <p><strong>Finished:</strong> END_TIME_PLACEHOLDER</p>
        <p><strong>Duration:</strong> DURATION_PLACEHOLDER</p>
    </div>

    <div class="stats">
        <div class="stat-card">
            <h3>Total Tests</h3>
            <p class="stat-value total">TOTAL_TESTS_PLACEHOLDER</p>
        </div>
        <div class="stat-card">
            <h3>Passed</h3>
            <p class="stat-value passed">PASSED_TESTS_PLACEHOLDER</p>
        </div>
        <div class="stat-card">
            <h3>Failed</h3>
            <p class="stat-value failed">FAILED_TESTS_PLACEHOLDER</p>
        </div>
        <div class="stat-card">
            <h3>Success Rate</h3>
            <p class="stat-value rate">SUCCESS_RATE_PLACEHOLDER</p>
        </div>
    </div>

    ITERATIONS_PLACEHOLDER

    <div class="junit-links">
        <h3>📋 JUnit XML Reports</h3>
        <p>Individual test reports (for CI/CD integration):</p>
        JUNIT_LINKS_PLACEHOLDER
    </div>

    <div class="test-list">
        <h2>Test Results</h2>
        TEST_RESULTS_PLACEHOLDER
    </div>

    <div class="footer">
        <p>Generated by Whisker Test Suite Runner</p>
        <p>Report Directory: REPORT_DIR_PLACEHOLDER</p>
    </div>
</body>
</html>
EOF

    # Replace placeholders
    sed -i.bak "s|TEST_SUITE_PLACEHOLDER|$TEST_SUITE|g" "$HTML_REPORT"
    sed -i.bak "s|PLATFORM_PLACEHOLDER|$PLATFORM|g" "$HTML_REPORT"
    sed -i.bak "s|MODE_PLACEHOLDER|$([ "$HEADLESS_MODE" = true ] && echo "Headless" || echo "Standard (with UI)")|g" "$HTML_REPORT"
    sed -i.bak "s|REPEAT_COUNT_PLACEHOLDER|$REPEAT_COUNT $([ "$REPEAT_COUNT" -gt 1 ] && echo "iterations" || echo "iteration")|g" "$HTML_REPORT"
    sed -i.bak "s|START_TIME_PLACEHOLDER|$START_TIME_DISPLAY|g" "$HTML_REPORT"
    sed -i.bak "s|END_TIME_PLACEHOLDER|$(date '+%Y-%m-%d %H:%M:%S')|g" "$HTML_REPORT"
    sed -i.bak "s|DURATION_PLACEHOLDER|${MINUTES}m ${SECONDS}s|g" "$HTML_REPORT"
    sed -i.bak "s|TOTAL_TESTS_PLACEHOLDER|$TOTAL_TESTS|g" "$HTML_REPORT"
    sed -i.bak "s|PASSED_TESTS_PLACEHOLDER|$PASSED_TESTS|g" "$HTML_REPORT"
    sed -i.bak "s|FAILED_TESTS_PLACEHOLDER|$((TOTAL_TESTS - PASSED_TESTS))|g" "$HTML_REPORT"
    sed -i.bak "s|REPORT_DIR_PLACEHOLDER|$REPORT_DIR|g" "$HTML_REPORT"
    
    # Calculate success rate
    if [ $TOTAL_TESTS -gt 0 ]; then
        SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f%%\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    else
        SUCCESS_RATE="N/A"
    fi
    sed -i.bak "s|SUCCESS_RATE_PLACEHOLDER|$SUCCESS_RATE|g" "$HTML_REPORT"
    
    # Generate JUnit links
    JUNIT_LINKS="<ul>"
    for junit_file in "$REPORT_DIR"/*_junit.xml; do
        if [ -f "$junit_file" ]; then
            filename=$(basename "$junit_file")
            JUNIT_LINKS="$JUNIT_LINKS<li><a href=\"$filename\">$filename</a></li>"
        fi
    done
    JUNIT_LINKS="$JUNIT_LINKS</ul>"
    
    # Escape special characters for sed
    JUNIT_LINKS_ESCAPED=$(echo "$JUNIT_LINKS" | sed 's/[&/\]/\\&/g')
    sed -i.bak "s|JUNIT_LINKS_PLACEHOLDER|$JUNIT_LINKS_ESCAPED|g" "$HTML_REPORT"
    
    # Generate iterations breakdown HTML (if repeat mode)
    if [ "$REPEAT_COUNT" -gt 1 ]; then
        ITERATIONS_HTML="<div class=\"iterations\">"
        ITERATIONS_HTML="$ITERATIONS_HTML<h3>🔁 Iteration Breakdown ($REPEAT_COUNT runs)</h3>"
        
        for ((i=0; i<REPEAT_COUNT; i++)); do
            iter_num=$((i + 1))
            iter_result="${ITERATION_RESULTS[$i]}"
            iter_duration="${ITERATION_DURATIONS[$i]}"
            
            # Determine pass/fail status for coloring
            iter_passed=$(echo "$iter_result" | cut -d'/' -f1)
            iter_total=$(echo "$iter_result" | cut -d'/' -f2)
            
            if [ "$iter_passed" = "$iter_total" ]; then
                status_class="iteration-pass"
                status_symbol="✓"
            else
                status_class="iteration-fail"
                status_symbol="✗"
            fi
            
            ITERATIONS_HTML="$ITERATIONS_HTML<div class=\"iteration-item\">"
            ITERATIONS_HTML="$ITERATIONS_HTML<a href=\"iteration_${iter_num}/summary.html\">Iteration $iter_num</a>: "
            ITERATIONS_HTML="$ITERATIONS_HTML<span class=\"$status_class\">$status_symbol $iter_result passed</span> "
            ITERATIONS_HTML="$ITERATIONS_HTML<span style=\"color: #6b7280;\">($iter_duration)</span>"
            ITERATIONS_HTML="$ITERATIONS_HTML</div>"
        done
        
        ITERATIONS_HTML="$ITERATIONS_HTML</div>"
        
        # Escape for sed
        ITERATIONS_HTML_ESCAPED=$(echo "$ITERATIONS_HTML" | sed 's/[&/\]/\\&/g')
        sed -i.bak "s|ITERATIONS_PLACEHOLDER|$ITERATIONS_HTML_ESCAPED|g" "$HTML_REPORT"
    else
        # No iterations section for single run
        sed -i.bak "s|ITERATIONS_PLACEHOLDER||g" "$HTML_REPORT"
    fi
    
    # Generate test results HTML
    TEST_RESULTS=""
    
    # Add passed tests
    for test_name in "${PASSED_TEST_NAMES[@]}"; do
        TEST_RESULTS="$TEST_RESULTS<div class=\"test-item pass\"><div class=\"test-name\">$test_name</div><span class=\"test-status status-pass\">✓ PASSED</span></div>"
    done
    
    # Add failed tests with error details
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        for i in "${!FAILED_TESTS[@]}"; do
            test="${FAILED_TESTS[$i]}"
            error_detail="${FAILURE_DETAILS[$i]:-No details available}"
            log_file="${FAILURE_LOGS[$i]:-}"
            
            # Escape HTML special characters in error details
            error_detail_escaped=$(echo "$error_detail" | sed 's/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
            
            # Build the failed test HTML with error details
            TEST_RESULTS="$TEST_RESULTS<div class=\"test-item fail\">"
            TEST_RESULTS="$TEST_RESULTS<div class=\"test-name\">$test</div>"
            TEST_RESULTS="$TEST_RESULTS<span class=\"test-status status-fail\">✗ FAILED</span>"
            TEST_RESULTS="$TEST_RESULTS<div class=\"error-details\">"
            TEST_RESULTS="$TEST_RESULTS<strong>Error Details:</strong>"
            TEST_RESULTS="$TEST_RESULTS$error_detail_escaped"
            
            # Add link to full log if available
            if [ -n "$log_file" ] && [ -f "$log_file" ]; then
                log_filename=$(basename "$log_file")
                TEST_RESULTS="$TEST_RESULTS<br><a href=\"logs/$log_filename\" class=\"log-link\">📄 View Full Log</a>"
            fi
            
            TEST_RESULTS="$TEST_RESULTS</div></div>"
        done
    fi
    
    # If no test results, show message
    if [ -z "$TEST_RESULTS" ]; then
        TEST_RESULTS="<p>No test results available.</p>"
    fi
    
    # Use awk to replace TEST_RESULTS_PLACEHOLDER without sed multi-line issues
    # Create a temporary file with the test results
    TEMP_RESULTS="${REPORT_DIR}/.temp_results.txt"
    echo "$TEST_RESULTS" > "$TEMP_RESULTS"
    
    # Use awk to insert test results (handles multi-line content properly)
    TEMP_HTML="${HTML_REPORT}.tmp"
    awk -v results_file="$TEMP_RESULTS" '
        /TEST_RESULTS_PLACEHOLDER/ {
            while ((getline line < results_file) > 0) {
                print line
            }
            close(results_file)
            next
        }
        { print }
    ' "$HTML_REPORT" > "$TEMP_HTML"
    
    mv "$TEMP_HTML" "$HTML_REPORT"
    rm -f "$TEMP_RESULTS"
    
    # Clean up backup files
    rm -f "$HTML_REPORT.bak"
    
    echo -e "${GREEN}✅ Summary report generated: ${HTML_REPORT}${NC}"
    echo -e "${BLUE}📁 All reports saved to: ${REPORT_DIR}${NC}"
    echo ""
fi

# Exit with appropriate code
if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}"
    echo "🎉 ALL TESTS PASSED! 🎉"
    echo -e "${NC}"
    exit 0
else
    echo -e "${YELLOW}"
    echo "⚠️  Some tests failed. Check the output above for details."
    echo -e "${NC}"
    exit 1
fi

