#!/bin/bash

# Script to generate gemini-task-list.yml from target.yml, task.md, and GUIDE.md
# This YAML file is structured for Gemini CLI processing

set -e

# Define file paths
TARGET_FILE="target.yml"
TASK_FILE="task.md"
GUIDE_FILE="GUIDE.md"
OUTPUT_FILE="gemini-task-list.yml"
WORKSPACE_DIR="workspace"

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

if [[ ! -d "$WORKSPACE_DIR" ]]; then
    echo "Error: $WORKSPACE_DIR directory not found"
    exit 1
fi

# Read task content and escape for YAML
TASK_CONTENT=$(cat "$TASK_FILE" | sed 's/"/\\"/g' | tr '\n' ' ')

# Read guide content and escape for YAML
GUIDE_CONTENT=$(cat "$GUIDE_FILE" | sed 's/"/\\"/g' | tr '\n' ' ')

# Get absolute path of workspace directory
WORKSPACE_ABS_PATH=$(realpath "$WORKSPACE_DIR")

# Start generating the gemini-task-list.yml file
echo "Generating $OUTPUT_FILE..."

# Write the YAML header
cat > "$OUTPUT_FILE" << EOF
# Gemini CLI Task List
# Generated from target.yml, task.md, and GUIDE.md
# Each task contains the directory path and prompt for Gemini CLI

tasks:
EOF

# Parse target.yml and extract repo/branch pairs
if command -v yq &> /dev/null; then
    # Use yq for proper YAML parsing
    yq eval '.target[]' "$TARGET_FILE" 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" =~ ^repo:\ (.+)$ ]]; then
            repo="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^branch:\ (.+)$ ]]; then
            branch="${BASH_REMATCH[1]}"

            # Check if the repository directory exists
            repo_path="$WORKSPACE_ABS_PATH/$repo"
            if [[ -d "$repo_path" ]]; then
                # Generate the prompt combining task and guide
                prompt="<task>$TASK_CONTENT</task><guide>$GUIDE_CONTENT</guide>"

                # Add task entry to YAML
                cat >> "$OUTPUT_FILE" << EOF
  - name: "$repo/$branch"
    directory: "$repo_path"
    prompt: "$prompt"
EOF
            else
                echo "Warning: Directory $repo_path does not exist, skipping $repo/$branch"
            fi
        fi
    done
else
    # Fallback: Basic parsing without yq
    echo "Warning: yq not found, using basic YAML parsing"

    repo=""
    branch=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*repo:[[:space:]]*(.+)$ ]]; then
            repo="${BASH_REMATCH[1]}"
            repo=$(echo "$repo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        elif [[ "$line" =~ ^[[:space:]]*branch:[[:space:]]*(.+)$ ]]; then
            branch="${BASH_REMATCH[1]}"
            branch=$(echo "$branch" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            if [[ -n "$repo" && -n "$branch" ]]; then
                # Check if the repository directory exists
                repo_path="$WORKSPACE_ABS_PATH/$repo"
                if [[ -d "$repo_path" ]]; then
                    # Generate the prompt combining task and guide
                    prompt="<task>$TASK_CONTENT</task><guide>$GUIDE_CONTENT</guide>"

                    # Add task entry to YAML
                    cat >> "$OUTPUT_FILE" << EOF
  - name: "$repo/$branch"
    directory: "$repo_path"
    prompt: "$prompt"
EOF
                else
                    echo "Warning: Directory $repo_path does not exist, skipping $repo/$branch"
                fi

                # Reset for next iteration
                repo=""
                branch=""
            fi
        fi
    done < "$TARGET_FILE"
fi

echo "Successfully generated $OUTPUT_FILE"
echo "Task list contains $(grep -c "^  - name:" "$OUTPUT_FILE" 2>/dev/null || echo "0") tasks"
