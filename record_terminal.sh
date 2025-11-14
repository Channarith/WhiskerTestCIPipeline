#!/bin/bash
# record_terminal.sh - Record terminal session with asciinema
# Perfect for documenting command-line workflows

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OUTPUT_DIR="demo_videos"
OUTPUT_FILE="${OUTPUT_DIR}/terminal_$(date +%Y%m%d_%H%M%S).cast"

# Check for asciinema
if ! command -v asciinema &> /dev/null; then
    echo -e "${RED}❌ asciinema not installed${NC}"
    echo ""
    echo -e "${YELLOW}Install with:${NC}"
    echo "  brew install asciinema"
    echo ""
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           💻 TERMINAL SESSION RECORDER 💻                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📹 Output: $OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo "  1. Recording will start in 3 seconds"
echo "  2. Run your commands (tests, demos, etc.)"
echo "  3. Press Ctrl+D to stop recording"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "  - Speak commands out loud as you type"
echo "  - Use 'clear' between major steps"
echo "  - Keep it under 5 minutes for best results"
echo ""

# Parse arguments
AUTO_COMMAND=""
if [ $# -gt 0 ]; then
    AUTO_COMMAND="$@"
    echo -e "${GREEN}Auto-run command: $AUTO_COMMAND${NC}"
    echo ""
fi

echo -e "${YELLOW}Starting in 3...${NC}"
sleep 1
echo -e "${YELLOW}2...${NC}"
sleep 1
echo -e "${YELLOW}1...${NC}"
sleep 1
echo ""
echo -e "${GREEN}🎬 RECORDING NOW${NC}"
echo ""

# Record
if [ -n "$AUTO_COMMAND" ]; then
    # Auto-execute command
    asciinema rec "$OUTPUT_FILE" -c "$AUTO_COMMAND"
else
    # Manual recording
    asciinema rec "$OUTPUT_FILE"
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "${RED}❌ Recording failed or was cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Recording saved: $OUTPUT_FILE${NC}"
echo ""

# Offer to convert to GIF
if command -v agg &> /dev/null; then
    echo -e "${YELLOW}Convert to GIF? (y/n)${NC}"
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        GIF_FILE="${OUTPUT_FILE%.cast}.gif"
        echo -e "${BLUE}Converting to GIF...${NC}"
        agg "$OUTPUT_FILE" "$GIF_FILE"
        
        if [ -f "$GIF_FILE" ]; then
            GIF_SIZE=$(du -h "$GIF_FILE" | cut -f1)
            echo -e "${GREEN}✅ GIF created: $GIF_FILE ($GIF_SIZE)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}💡 Convert to GIF with: agg${NC}"
    echo "   Install: brew install agg"
    echo "   Convert: agg $OUTPUT_FILE ${OUTPUT_FILE%.cast}.gif"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Add to README.md:${NC}"
echo ""
echo "## Terminal Demo"
echo ""
if [ -f "${OUTPUT_FILE%.cast}.gif" ]; then
    echo "![Terminal Demo](${OUTPUT_FILE%.cast}.gif)"
else
    echo "[![asciicast](https://asciinema.org/a/14.png)]($OUTPUT_FILE)"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

