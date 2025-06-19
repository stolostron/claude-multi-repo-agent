#!/bin/bash

# Script to generate task-list.md from target.yml, task.md, and GUIDE.md

set -e

# Define file paths
TARGET_FILE="target.yml"
TASK_FILE="task.md"
GUIDE_FILE="GUIDE.md"
OUTPUT_FILE="task-list.md"

# Check if required files exist
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: $TARGET_FILE not found"
    exit 1
fi

if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: $TASK_FILE not found"
    exit 1
fi

if [[ ! -f "$GUIDE_FILE" ]]; then
    echo "Error: $GUIDE_FILE not found"
    exit 1
fi

# Read task content (everything from task.md) and remove empty lines
TASK_CONTENT=$(cat "$TASK_FILE" | sed '/^[[:space:]]*$/d')

# Read guide content (everything from GUIDE.md) and remove empty lines
GUIDE_CONTENT=$(cat "$GUIDE_FILE" | sed '/^[[:space:]]*$/d')

# Start generating the task-list.md file
echo "Generating $OUTPUT_FILE..."

# Write the fixed header
cat > "$OUTPUT_FILE" << 'EOF'
[ ] NAME:Current Task List DESCRIPTION:Root task for conversation **NEW_AGENT**
EOF

# Parse target.yml and extract repo/branch pairs
# This uses yq to parse YAML, but falls back to basic parsing if yq is not available
if command -v yq &> /dev/null; then
    # Use yq for proper YAML parsing
    yq eval '.target[] | .repo + "/" + .branch' "$TARGET_FILE" 2>/dev/null | while read -r target; do
        if [[ -n "$target" && "$target" != "null" ]]; then
            echo "- [ ] NAME: $target DESCRIPTION:<task>${TASK_CONTENT//$'\n'/\/n}</task><guide>${GUIDE_CONTENT//$'\n'/\/n}</guide>" >> "$OUTPUT_FILE"
        fi
    done
else
    # Fallback: Basic parsing without yq
    echo "Warning: yq not found, using basic YAML parsing"

    # Extract repo and branch pairs from YAML
    awk '
    /^[[:space:]]*-[[:space:]]*repo:/ {
        gsub(/^[[:space:]]*-[[:space:]]*repo:[[:space:]]*/, "")
        gsub(/[[:space:]]*$/, "")
        repo = $0
    }
    /^[[:space:]]*branch:/ {
        gsub(/^[[:space:]]*branch:[[:space:]]*/, "")
        gsub(/[[:space:]]*$/, "")
        branch = $0
        if (repo != "" && branch != "") {
            print repo "/" branch
            repo = ""
            branch = ""
        }
    }
    ' "$TARGET_FILE" | while read -r target; do
        if [[ -n "$target" ]]; then
            echo "- [ ] NAME:$target DESCRIPTION:<task>${TASK_CONTENT//$'\n'/\/n}</task><guide>${GUIDE_CONTENT//$'\n'/\/n}</guide>" >> "$OUTPUT_FILE"
        fi
    done
fi

echo "Successfully generated $OUTPUT_FILE"
