#!/bin/bash
# Example:
# ./run-on-repos.sh "code-agent.sh 'fix some issue'"

# Define repository list
REPOS=(
  "ocm"
  "managedcluster-import-controller"
  "multicloud-operators-foundation"
  "cluster-proxy"
  "cluster-proxy-addon"
  "managed-serviceaccount"
  "clusterlifecycle-state-metrics"
  "klusterlet-addon-controller"
  "cluster-lifecycle-api"
)

# Check if a command was provided
if [ $# -eq 0 ]; then
  echo "Error: Please provide a command to run on repositories"
  echo "Usage: $0 \"command to execute\""
  echo "Example: $0 \"git status\""
  exit 1
fi

# Get the command to run
COMMAND="$*"

# Define workspace directory
WORKSPACE_DIR="$(pwd)/workspace"
# Ensure workspace directory exists
mkdir -p "$WORKSPACE_DIR"

# Run command on each repository
for REPO in "${REPOS[@]}"; do
  echo "=================================================="
  echo "Running on repository $REPO: $COMMAND"
  echo "=================================================="
  # Check if repository directory exists
  REPO_DIR="$WORKSPACE_DIR/$REPO"
  if [ ! -d "$REPO_DIR" ]; then
    echo "Warning: Repository directory $REPO_DIR does not exist, skipping..."
    continue
  fi
  # Change to repository directory and execute command
  cd "$REPO_DIR" || continue
  eval "$COMMAND"

  # Add separator
  echo "--------------------------------------------------"
  echo ""
  echo "--------------------------------------------------"
  echo ""
echo "All repositories processing completed"
