#!/bin/bash

# Script to process gemini-task-list.yml and run Gemini CLI for each task
# This script navigates to each task's directory and executes the corresponding prompt

set -e

# Define file paths
TASK_LIST_FILE="gemini-task-list.yml"
LOG_FILE="gemini-execution.log"

# Check if required files exist
if [[ ! -f "$TASK_LIST_FILE" ]]; then
    echo "Error: $TASK_LIST_FILE not found"
    echo "Please run ./script/generate-task-list-for-gemini.sh first"
    exit 1
fi

# Check if gemini CLI is available
if ! command -v gemini &> /dev/null; then
    echo "Error: gemini CLI not found"
    echo "Please install gemini CLI first"
    exit 1
fi

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo "Error: yq not found"
    echo "Please install yq for YAML parsing: brew install yq"
    exit 1
fi

# Initialize log file
echo "=== Gemini Task Execution Log ===" > "$LOG_FILE"
echo "Started at: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Get the total number of tasks
total_tasks=$(yq eval '.tasks | length' "$TASK_LIST_FILE")
echo "Found $total_tasks tasks to process"
echo "Found $total_tasks tasks to process" >> "$LOG_FILE"
echo ""

# Process each task
current_task=0
failed_tasks=0
successful_tasks=0

while IFS= read -r task_index; do
    current_task=$((current_task + 1))

    # Extract task information
    task_name=$(yq eval ".tasks[$task_index].name" "$TASK_LIST_FILE")
    task_directory=$(yq eval ".tasks[$task_index].directory" "$TASK_LIST_FILE")
    task_prompt=$(yq eval ".tasks[$task_index].prompt" "$TASK_LIST_FILE")

    echo "[$current_task/$total_tasks] Processing task: $task_name"
    echo "[$current_task/$total_tasks] Processing task: $task_name" >> "$LOG_FILE"
    echo "Directory: $task_directory"
    echo "Directory: $task_directory" >> "$LOG_FILE"

    # Check if directory exists
    if [[ ! -d "$task_directory" ]]; then
        echo "Error: Directory $task_directory does not exist, skipping task"
        echo "Error: Directory $task_directory does not exist, skipping task" >> "$LOG_FILE"
        failed_tasks=$((failed_tasks + 1))
        echo ""
        echo "" >> "$LOG_FILE"
        continue
    fi

    # Change to task directory
    echo "Changing to directory: $task_directory"
    echo "Changing to directory: $task_directory" >> "$LOG_FILE"

    # Execute gemini command in the task directory
    echo "Executing: gemini --yolo -p \"$task_prompt\""
    echo "Executing: gemini --yolo -p \"[PROMPT_CONTENT_HIDDEN]\"" >> "$LOG_FILE"

    # Run gemini command and capture output
    if (cd "$task_directory" && gemini --yolo -p "$task_prompt") >> "$LOG_FILE" 2>&1; then
        echo "✅ Task completed successfully"
        echo "✅ Task completed successfully" >> "$LOG_FILE"
        successful_tasks=$((successful_tasks + 1))
    else
        echo "❌ Task failed"
        echo "❌ Task failed" >> "$LOG_FILE"
        failed_tasks=$((failed_tasks + 1))
    fi

    echo ""
    echo "" >> "$LOG_FILE"

    # Add a small delay between tasks to avoid overwhelming the system
    sleep 2

done < <(seq 0 $((total_tasks - 1)))

# Summary
echo "=== Execution Summary ==="
echo "=== Execution Summary ===" >> "$LOG_FILE"
echo "Total tasks: $total_tasks"
echo "Total tasks: $total_tasks" >> "$LOG_FILE"
echo "Successful: $successful_tasks"
echo "Successful: $successful_tasks" >> "$LOG_FILE"
echo "Failed: $failed_tasks"
echo "Failed: $failed_tasks" >> "$LOG_FILE"
echo "Completed at: $(date)"
echo "Completed at: $(date)" >> "$LOG_FILE"

if [[ $failed_tasks -gt 0 ]]; then
    echo ""
    echo "⚠️  Some tasks failed. Check $LOG_FILE for details."
    exit 1
else
    echo ""
    echo "🎉 All tasks completed successfully!"
    exit 0
fi
