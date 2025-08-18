#!/bin/bash

# Script to generate individual task files from target.yml and task.md

set -e

# Clean up tasks directory at the beginning
echo "Cleaning up existing tasks directory..."
rm -rf "tasks"

# Define file paths
TARGET_FILE="target.yml"
TASK_FILE="task.md"
GUIDE_FILE="GUIDE.md"
OUTPUT_DIR="tasks"

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


# Create tasks directory
echo "Generating tasks in $OUTPUT_DIR directory..."

# Remove existing tasks directory and create a new one
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Create a counter for task files
TASK_COUNTER=1

# Parse target.yml and extract repo/branch pairs
# This uses yq to parse YAML, but falls back to basic parsing if yq is not available
if command -v yq &> /dev/null; then
    # Use yq for proper YAML parsing
    yq eval '.target[] | .repo + "/" + .branch' "$TARGET_FILE" 2>/dev/null | while read -r target; do
        if [[ -n "$target" && "$target" != "null" ]]; then
            # Create filename with zero-padded counter
            TASK_FILE_NAME=$(printf "%03d_%s.md" "$TASK_COUNTER" "${target//\//_}")

            # Write task content to individual file
            cat > "$OUTPUT_DIR/$TASK_FILE_NAME" << EOF
# Task: $target

## Guide
<guide>
$GUIDE_CONTENT
</guide>

## Description
<task>
$TASK_CONTENT
</task>
EOF

            echo "Created: $OUTPUT_DIR/$TASK_FILE_NAME"
            TASK_COUNTER=$((TASK_COUNTER + 1))
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
            # Create filename with zero-padded counter
            TASK_FILE_NAME=$(printf "%03d_%s.md" "$TASK_COUNTER" "${target//\//_}")

            # Write task content to individual file
            cat > "$OUTPUT_DIR/$TASK_FILE_NAME" << EOF
# Task: $target

## Guide
<guide>
$GUIDE_CONTENT
</guide>

## Description
<task>
$TASK_CONTENT
</task>
EOF

            echo "Created: $OUTPUT_DIR/$TASK_FILE_NAME"
            TASK_COUNTER=$((TASK_COUNTER + 1))
        fi
    done
fi

echo "Successfully generated tasks in $OUTPUT_DIR directory"
