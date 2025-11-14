#!/bin/bash
# Helper script to parse Maestro error logs and find YAML line numbers

if [ $# -lt 2 ]; then
    echo "Usage: $0 <log_file> <yaml_file>"
    exit 1
fi

LOG_FILE="$1"
YAML_FILE="$2"

if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found: $LOG_FILE"
    exit 1
fi

if [ ! -f "$YAML_FILE" ]; then
    echo "YAML file not found: $YAML_FILE"
    exit 1
fi

echo "🔍 Analyzing Maestro Error Log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract the error message
echo "📋 Error Message:"
if grep -q "\[Failed\]" "$LOG_FILE"; then
    grep "\[Failed\]" "$LOG_FILE" | head -1
fi

if grep -q "Element not found:" "$LOG_FILE"; then
    ELEMENT=$(grep "Element not found:" "$LOG_FILE" | head -1 | sed 's/.*Element not found: //' | sed 's/)$//')
    echo "   Element not found: $ELEMENT"
    echo ""
    
    # Try to find this element in the YAML
    echo "📍 Searching for element in YAML..."
    # Clean up the element text for searching
    SEARCH_TEXT=$(echo "$ELEMENT" | sed 's/Text matching regex: //' | sed 's/^"\(.*\)"$/\1/')
    
    if grep -qn "$SEARCH_TEXT" "$YAML_FILE"; then
        echo "   Found matches:"
        grep -n "$SEARCH_TEXT" "$YAML_FILE" | while IFS=: read -r line_num line_content; do
            echo "   Line $line_num: $line_content"
        done
    else
        echo "   No exact match found in YAML"
        echo "   Showing similar commands:"
        grep -n "tapOn:\|assertVisible:\|scrollUntilVisible:" "$YAML_FILE" | tail -10
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 To view full log: cat $LOG_FILE"
echo "💡 To view YAML: cat $YAML_FILE"

