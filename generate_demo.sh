#!/bin/bash
# generate_demo.sh - Complete demo video and GIF generator for GitHub
# Automatically records tests and creates GitHub-ready GIFs

set -e

# Configuration
DEMO_DIR="demo_videos"
DEVICE_RECORDING="/sdcard/whisker_demo.mp4"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_VIDEO="${DEMO_DIR}/whisker_test_${TIMESTAMP}.mp4"
OUTPUT_GIF="${DEMO_DIR}/whisker_test_demo.gif"
RECORDING_TIME=180  # 3 minutes max

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create demo directory
mkdir -p "$DEMO_DIR"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}║          🎬 WHISKER TEST DEMO GENERATOR 🎬                   ║${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse command line arguments
TEST_SUITE="smoke"
HEADLESS="--headless"
SPEED="1.0"

while [[ $# -gt 0 ]]; do
    case $1 in
        --suite)
            TEST_SUITE="$2"
            shift 2
            ;;
        --with-ui)
            HEADLESS=""
            shift
            ;;
        --time)
            RECORDING_TIME="$2"
            shift 2
            ;;
        --speed)
            SPEED="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --suite SUITE    Test suite to record (smoke, organized, all)"
            echo "  --with-ui        Record with UI (not headless)"
            echo "  --time SECONDS   Recording time limit (default: 180)"
            echo "  --speed N        Speed up GIF by Nx (default: 1.0, use 10 for 10x)"
            echo "  --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                      # Record smoke tests (headless)"
            echo "  $0 --suite organized    # Record organized tests"
            echo "  $0 --with-ui            # Record with Maestro UI visible"
            echo "  $0 --speed 10           # Create 10x speed GIF (recommended!)"
            echo "  $0 --suite all --speed 5 # Full suite at 5x speed"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check for emulator
echo -e "${BLUE}📱 Checking for Android device/emulator...${NC}"
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}❌ No Android device/emulator detected${NC}"
    echo -e "${YELLOW}   Start emulator first: Android Studio → Device Manager${NC}"
    exit 1
fi

DEVICE=$(adb devices | grep "device$" | head -1 | awk '{print $1}')
echo -e "${GREEN}✅ Device found: $DEVICE${NC}"
echo ""

# Check for ffmpeg (needed for GIF conversion)
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}⚠️  ffmpeg not installed - GIF creation will be skipped${NC}"
    echo -e "${YELLOW}   Install with: brew install ffmpeg${NC}"
    echo ""
fi

# Start recording
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📹 Starting screen recording (${RECORDING_TIME}s max)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

adb shell screenrecord --time-limit "$RECORDING_TIME" --bit-rate 4000000 "$DEVICE_RECORDING" &
RECORD_PID=$!

# Give recording time to start
sleep 3

# Run the test
echo -e "${GREEN}🧪 Running $TEST_SUITE tests...${NC}"
echo ""

if ./run_all_tests.sh --suite "$TEST_SUITE" $HEADLESS; then
    TEST_STATUS="PASSED"
else
    TEST_STATUS="FAILED"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⏳ Waiting for recording to finish...${NC}"

# Wait for recording to complete
wait $RECORD_PID 2>/dev/null || true
sleep 2

# Pull video from device
echo -e "${BLUE}📥 Downloading video from device...${NC}"
if adb pull "$DEVICE_RECORDING" "$OUTPUT_VIDEO" 2>/dev/null; then
    echo -e "${GREEN}✅ Video saved: $OUTPUT_VIDEO${NC}"
else
    echo -e "${RED}❌ Failed to download video${NC}"
    exit 1
fi

# Clean up device
adb shell rm "$DEVICE_RECORDING" 2>/dev/null || true

# Get video info
VIDEO_SIZE=$(du -h "$OUTPUT_VIDEO" | cut -f1)
VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_VIDEO" 2>/dev/null | cut -d. -f1 || echo "unknown")

echo -e "${BLUE}   File size: $VIDEO_SIZE${NC}"
if [ "$VIDEO_DURATION" != "unknown" ]; then
    echo -e "${BLUE}   Duration: ${VIDEO_DURATION}s${NC}"
fi

# Convert to GIF if ffmpeg is available
if command -v ffmpeg &> /dev/null; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🎨 Converting to GIF for GitHub...${NC}"
    if [ "$SPEED" != "1.0" ] && [ "$SPEED" != "1" ]; then
        echo -e "${BLUE}⚡ Speed: ${SPEED}x faster${NC}"
    fi
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Use our video_to_gif.sh script for conversion
    if ./video_to_gif.sh "$OUTPUT_VIDEO" --output "$OUTPUT_GIF" --speed "$SPEED" --fps 15 --width 640 --colors 128; then
        GIF_SIZE=$(du -h "$OUTPUT_GIF" | cut -f1)
        GIF_SIZE_MB=$(du -m "$OUTPUT_GIF" | cut -f1)
    else
        echo -e "${RED}❌ Failed to create GIF${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Skipped GIF creation (ffmpeg not installed)${NC}"
    echo -e "${YELLOW}   Install ffmpeg: brew install ffmpeg${NC}"
fi

# Generate README snippet
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Demo generation complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📁 Files created:${NC}"
echo -e "   📹 Video: $OUTPUT_VIDEO ($VIDEO_SIZE)"
if [ -f "$OUTPUT_GIF" ]; then
    echo -e "   🎨 GIF:   $OUTPUT_GIF ($GIF_SIZE)"
fi
echo ""
echo -e "${YELLOW}📋 Add to README.md:${NC}"
echo ""
if [ -f "$OUTPUT_GIF" ]; then
    echo "## 🎬 Tests in Action"
    echo ""
    echo "![Whisker $TEST_SUITE Tests]($OUTPUT_GIF)"
    echo ""
    if [ "$SPEED" != "1.0" ] && [ "$SPEED" != "1" ]; then
        echo "*Automated $TEST_SUITE tests (${SPEED}x speed) - Status: $TEST_STATUS*"
    else
        echo "*Automated $TEST_SUITE tests - Status: $TEST_STATUS*"
    fi
else
    echo "## 🎬 Test Demo Video"
    echo ""
    echo "[![Whisker Tests](demo_videos/thumbnail.png)]($OUTPUT_VIDEO)"
    echo ""
    echo "*Click to view the full test run*"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}🎉 Ready to showcase your tests on GitHub!${NC}"
echo ""

