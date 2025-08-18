#!/bin/bash

# Script to run all task files in tasks/ directory using Claude CLI in print mode

set -e

# Parse command line arguments
SAVE_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --save-logs)
            SAVE_LOGS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--save-logs]"
            echo "  --save-logs  Save output to log files (default: print directly)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Define paths
TASKS_DIR="tasks"
LOG_DIR="logs"

# Check if tasks directory exists
if [[ ! -d "$TASKS_DIR" ]]; then
    echo "Error: $TASKS_DIR directory not found"
    echo "Please run ./script/generate-task-list.sh first"
    exit 1
fi

# Create logs directory only if saving logs
if [[ "$SAVE_LOGS" == "true" ]]; then
    mkdir -p "$LOG_DIR"
fi

# Get all task files sorted by name
TASK_FILES=($(find "$TASKS_DIR" -name "*.md" | sort))

if [[ ${#TASK_FILES[@]} -eq 0 ]]; then
    echo "Error: No task files found in $TASKS_DIR"
    echo "Please run ./script/generate-task-list.sh first"
    exit 1
fi

echo "Found ${#TASK_FILES[@]} task files to process"

# Function to run a single task
run_task() {
    local task_file="$1"
    local task_name=$(basename "$task_file" .md)
    local log_file="$LOG_DIR/${task_name}.log"
    
    echo "Processing: $task_file"
    
    if [[ "$SAVE_LOGS" == "true" ]]; then
        # Run Claude CLI and save output to log file
        if cat "$task_file" | claude -p "Execute this task" --verbose --output-format text --dangerously-skip-permissions > "$log_file" 2>&1; then
            echo "✓ Completed: $task_name"
            echo "  Log: $log_file"
            return 0
        else
            echo "✗ Failed: $task_name"
            echo "  Log: $log_file"
            return 1
        fi
    else
        # Run Claude CLI and print output directly
        echo "Output for $task_name:"
        echo "========================"
        if cat "$task_file" | claude -p "Execute this task" --verbose --output-format text --dangerously-skip-permissions; then
            echo "========================"
            echo "✓ Completed: $task_name"
            return 0
        else
            echo "========================"
            echo "✗ Failed: $task_name"
            return 1
        fi
    fi
}

# Process all tasks
echo "Starting task execution..."
if [[ "$SAVE_LOGS" == "true" ]]; then
    echo "Logs will be saved to: $LOG_DIR/"
else
    echo "Output will be printed directly (no logs saved)"
fi

SUCCESSFUL=0
FAILED=0

for task_file in "${TASK_FILES[@]}"; do
    if run_task "$task_file"; then
        SUCCESSFUL=$((SUCCESSFUL + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Summary
echo "================================"
echo "Task Execution Summary:"
echo "  Successful: $SUCCESSFUL"
echo "  Failed: $FAILED"
echo "  Total: ${#TASK_FILES[@]}"
echo "================================"

if [[ $FAILED -gt 0 ]]; then
    if [[ "$SAVE_LOGS" == "true" ]]; then
        echo "Some tasks failed. Check logs in $LOG_DIR/ for details."
    else
        echo "Some tasks failed. See output above for details."
    fi
    exit 1
else
    echo "All tasks completed successfully!"
    exit 0
fi