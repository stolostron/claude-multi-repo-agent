#!/bin/bash

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

# Get current GitHub username using gh CLI
echo "Getting GitHub username..."
GITHUB_USER=$(gh api user --jq '.login')

if [ -z "$GITHUB_USER" ]; then
  echo "Error: Could not get GitHub username. Please make sure you are logged in with 'gh auth login'"
  exit 1
fi

echo "GitHub username: $GITHUB_USER"

# Create workspace directory if it doesn't exist
WORKSPACE_DIR="workspace"
if [ ! -d "$WORKSPACE_DIR" ]; then
  echo "Creating workspace directory..."
  mkdir -p "$WORKSPACE_DIR"
fi

# Change to workspace directory
cd "$WORKSPACE_DIR"

# Clone each repository
echo "Cloning repositories..."
for repo in "${REPOS[@]}"; do
  if [ -d "$repo" ]; then
    echo "Repository '$repo' already exists, skipping..."
  else
    echo "Cloning $repo..."
    git clone "https://github.com/$GITHUB_USER/$repo.git" --depth 1
    if [ $? -eq 0 ]; then
      echo "Successfully cloned $repo"
    else
      echo "Failed to clone $repo"
    fi
  fi
done

echo "Repository setup complete!"
