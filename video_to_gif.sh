#!/bin/bash
# video_to_gif.sh - Convert video to optimized GIF for GitHub
# Automatically optimizes for GitHub's 10MB limit

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check for ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}❌ ffmpeg not installed${NC}"
    echo -e "${YELLOW}   Install with: brew install ffmpeg${NC}"
    exit 1
fi

# Parse arguments
INPUT_VIDEO=""
OUTPUT_GIF=""
FPS=15
WIDTH=640
COLORS=128
SPEED=1.0

while [[ $# -gt 0 ]]; do
    case $1 in
        --fps)
            FPS="$2"
            shift 2
            ;;
        --width)
            WIDTH="$2"
            shift 2
            ;;
        --colors)
            COLORS="$2"
            shift 2
            ;;
        --speed)
            SPEED="$2"
            shift 2
            ;;
        --output)
            OUTPUT_GIF="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 INPUT_VIDEO [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --fps N        Frames per second (default: 15)"
            echo "  --width N      Width in pixels (default: 640)"
            echo "  --colors N     Number of colors (default: 128)"
            echo "  --speed N      Speed multiplier (default: 1.0, use 10 for 10x speed)"
            echo "  --output FILE  Output GIF file"
            echo "  --help         Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 video.mp4"
            echo "  $0 video.mp4 --fps 10 --width 480"
            echo "  $0 video.mp4 --speed 10              # 10x faster"
            echo "  $0 video.mp4 --speed 5 --fps 20      # 5x speed, smooth"
            echo "  $0 video.mp4 --output demo.gif"
            exit 0
            ;;
        *)
            if [ -z "$INPUT_VIDEO" ]; then
                INPUT_VIDEO="$1"
            else
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate input
if [ -z "$INPUT_VIDEO" ]; then
    echo -e "${RED}❌ No input video specified${NC}"
    echo "Usage: $0 INPUT_VIDEO [OPTIONS]"
    exit 1
fi

if [ ! -f "$INPUT_VIDEO" ]; then
    echo -e "${RED}❌ File not found: $INPUT_VIDEO${NC}"
    exit 1
fi

# Set output filename if not specified
if [ -z "$OUTPUT_GIF" ]; then
    OUTPUT_GIF="${INPUT_VIDEO%.*}.gif"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            🎨 VIDEO TO GIF CONVERTER 🎨                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📹 Input:  $INPUT_VIDEO${NC}"
echo -e "${GREEN}🎨 Output: $OUTPUT_GIF${NC}"
echo -e "${GREEN}⚙️  Settings:${NC}"
echo -e "${BLUE}   FPS: $FPS, Width: ${WIDTH}px, Colors: $COLORS${NC}"
if [ "$SPEED" != "1.0" ] && [ "$SPEED" != "1" ]; then
    echo -e "${BLUE}   ⚡ Speed: ${SPEED}x faster${NC}"
fi
echo ""
echo -e "${YELLOW}🎬 Converting...${NC}"
echo ""

# Build video filter chain
# Calculate PTS multiplier for speed (1/SPEED)
PTS_MULTIPLIER=$(echo "scale=4; 1/$SPEED" | bc)

# If speed is 1.0, don't add setpts filter
if [ "$SPEED" = "1.0" ] || [ "$SPEED" = "1" ]; then
    VIDEO_FILTERS="fps=$FPS,scale=$WIDTH:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
else
    VIDEO_FILTERS="setpts=${PTS_MULTIPLIER}*PTS,fps=$FPS,scale=$WIDTH:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
fi

# Convert with high quality palette
ffmpeg -i "$INPUT_VIDEO" \
    -vf "$VIDEO_FILTERS" \
    -loop 0 \
    "$OUTPUT_GIF" \
    -y 2>&1 | grep -E "time=|frame=|size=" || true

echo ""

if [ ! -f "$OUTPUT_GIF" ]; then
    echo -e "${RED}❌ Failed to create GIF${NC}"
    exit 1
fi

# Get file size
GIF_SIZE_BYTES=$(stat -f%z "$OUTPUT_GIF" 2>/dev/null || stat -c%s "$OUTPUT_GIF" 2>/dev/null)
GIF_SIZE_MB=$((GIF_SIZE_BYTES / 1024 / 1024))
GIF_SIZE_HUMAN=$(du -h "$OUTPUT_GIF" | cut -f1)

echo -e "${GREEN}✅ GIF created!${NC}"
echo -e "${BLUE}   Size: $GIF_SIZE_HUMAN${NC}"

# Optimize with gifsicle if available
if command -v gifsicle &> /dev/null; then
    echo ""
    echo -e "${YELLOW}⚡ Optimizing with gifsicle...${NC}"
    
    TEMP_GIF="${OUTPUT_GIF%.gif}_temp.gif"
    if gifsicle -O3 --colors "$COLORS" "$OUTPUT_GIF" -o "$TEMP_GIF" 2>/dev/null; then
        mv "$TEMP_GIF" "$OUTPUT_GIF"
        
        NEW_SIZE=$(du -h "$OUTPUT_GIF" | cut -f1)
        NEW_SIZE_BYTES=$(stat -f%z "$OUTPUT_GIF" 2>/dev/null || stat -c%s "$OUTPUT_GIF" 2>/dev/null)
        NEW_SIZE_MB=$((NEW_SIZE_BYTES / 1024 / 1024))
        
        SAVED=$((GIF_SIZE_BYTES - NEW_SIZE_BYTES))
        SAVED_HUMAN=$(echo "scale=1; $SAVED / 1024 / 1024" | bc)
        
        echo -e "${GREEN}✅ Optimized!${NC}"
        echo -e "${BLUE}   New size: $NEW_SIZE (saved ${SAVED_HUMAN}MB)${NC}"
        
        GIF_SIZE_MB=$NEW_SIZE_MB
    fi
else
    echo ""
    echo -e "${YELLOW}💡 Install gifsicle for better compression: brew install gifsicle${NC}"
fi

# Check if GIF is too large for GitHub
echo ""
if [ "$GIF_SIZE_MB" -gt 10 ]; then
    echo -e "${YELLOW}⚠️  WARNING: GIF is ${GIF_SIZE_MB}MB (GitHub limit: 10MB)${NC}"
    echo ""
    echo -e "${YELLOW}Suggestions to reduce size:${NC}"
    echo -e "  1. Speed up:     $0 \"$INPUT_VIDEO\" --speed 5    # 5x faster = 1/5 duration"
    echo -e "  2. Lower FPS:    $0 \"$INPUT_VIDEO\" --fps 10"
    echo -e "  3. Smaller size: $0 \"$INPUT_VIDEO\" --width 480"
    echo -e "  4. Fewer colors: $0 \"$INPUT_VIDEO\" --colors 64"
    echo -e "  5. Combo deal:   $0 \"$INPUT_VIDEO\" --speed 10 --fps 12 --width 480 --colors 64"
else
    echo -e "${GREEN}✅ GIF is ${GIF_SIZE_MB}MB - Perfect for GitHub!${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Add to README.md:${NC}"
echo ""
echo "![Demo]($OUTPUT_GIF)"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

