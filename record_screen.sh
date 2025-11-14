#!/bin/bash
# record_screen.sh - Simple Android screen recorder
# Records whatever is happening on the Android emulator

# Configuration
OUTPUT_DIR="demo_videos"
OUTPUT_FILE="${OUTPUT_DIR}/recording_$(date +%Y%m%d_%H%M%S).mp4"
RECORDING_TIME=180  # Default 3 minutes

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --time)
            RECORDING_TIME="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --time SECONDS   Recording duration (default: 180)"
            echo "  --output FILE    Output file path"
            echo "  --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                          # Record for 3 minutes"
            echo "  $0 --time 60                # Record for 1 minute"
            echo "  $0 --output my_video.mp4    # Custom output file"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check for device
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}❌ No Android device/emulator detected${NC}"
    exit 1
fi

DEVICE=$(adb devices | grep "device$" | head -1 | awk '{print $1}')
DEVICE_FILE="/sdcard/screenrecord_$(date +%s).mp4"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              📹 ANDROID SCREEN RECORDER 📹                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📱 Device: $DEVICE${NC}"
echo -e "${GREEN}⏱️  Duration: ${RECORDING_TIME}s${NC}"
echo -e "${GREEN}💾 Output: $OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}🎬 Recording started...${NC}"
echo -e "${YELLOW}   Press Ctrl+C to stop early${NC}"
echo ""

# Start recording
adb shell screenrecord --time-limit "$RECORDING_TIME" --bit-rate 6000000 "$DEVICE_FILE" &
RECORD_PID=$!

# Show timer
for ((i=1; i<=RECORDING_TIME; i++)); do
    printf "\r${BLUE}⏱️  Recording: %02d:%02d${NC}" $((i/60)) $((i%60))
    sleep 1
    
    # Check if recording process is still running
    if ! ps -p $RECORD_PID > /dev/null 2>&1; then
        break
    fi
done

echo ""
echo ""

# Wait for recording to finish
wait $RECORD_PID 2>/dev/null || true
sleep 2

# Pull video
echo -e "${BLUE}📥 Downloading from device...${NC}"
if adb pull "$DEVICE_FILE" "$OUTPUT_FILE"; then
    adb shell rm "$DEVICE_FILE"
    
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo -e "${GREEN}✅ Recording saved!${NC}"
    echo -e "${GREEN}   File: $OUTPUT_FILE${NC}"
    echo -e "${GREEN}   Size: $FILE_SIZE${NC}"
    echo ""
    echo -e "${YELLOW}💡 Convert to GIF: ./video_to_gif.sh $OUTPUT_FILE${NC}"
else
    echo -e "${RED}❌ Failed to download recording${NC}"
    exit 1
fi

