#!/bin/bash

# Set default values
CONTEXT_FILE=""
TASK_CONTENT=""
DEFAULT_OLLAMA_MODEL="qwen3:14b"
OLLAMA_MODEL="$DEFAULT_OLLAMA_MODEL"

# Function to filter <think> tags from Ollama output
filter_ollama_output() {
  # Remove everything between <think> and </think> tags including the tags themselves
  sed -E 's/<think>.*<\/think>//g' | sed '/^$/d'
}

# Define shorthand function for codex command
autocodex() {
  CODEX_UNSAFE_ALLOW_NO_SANDBOX=true codex -q --provider ollama --model "$OLLAMA_MODEL" -a full-auto "$@"
}

# Function to print usage information
print_usage() {
  echo "Usage: $0 [OPTIONS] TASK_CONTENT"
  echo "Options:"
  echo "  -f, --file FILE        Optional file containing additional context"
  echo "  -c, --content CONTENT  Task content as a string (alternative to positional argument)"
  echo "  -m, --model MODEL      Ollama model to use (default: $DEFAULT_OLLAMA_MODEL)"
  echo "  -d, --deliver          Run in delivery mode (reset branch, commit changes, create PR)"
  echo "  -h, --help             Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0 \"Fix the logging bug\""
  echo "  $0 -f context.md \"Implement new feature\""
  echo "  $0 -m codellama:7b \"Update dependencies\" -d"
}

# Function to check if current directory is a git repository
is_git_repo() {
  git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# Function to get the repository name from git remote
get_repo_name() {
  local remote_url=$(git config --get remote.origin.url)
  if [ -n "$remote_url" ]; then
    # Extract repo name from the URL (works for both SSH and HTTPS URLs)
    echo "$remote_url" | sed -E 's/.*\/([^\/]+)(\.git)?$/\1/'
  else
    # If no remote origin, use the directory name
    basename "$(pwd)"
  fi
}

# Function to run the agent
run_agent() {
  local repo_dir="$(pwd)"

  # Run codex with the task content
  echo "Running codex with task: '$TASK_CONTENT' on repository $(basename "$repo_dir")"
  if [ -n "$CONTEXT_FILE" ]; then
    if [ ! -f "$CONTEXT_FILE" ]; then
      echo "Error: Context file $CONTEXT_FILE does not exist"
      exit 1
    fi
    echo "Using file '$CONTEXT_FILE' as context"
    autocodex --project-doc "$CONTEXT_FILE" "$TASK_CONTENT"
  else
    autocodex "$TASK_CONTENT"
  fi
}

# Function to reset branch to clean main
reset_to_clean_branch() {
  local repo_dir="$(pwd)"

  # Check if the current directory is a git repository (already done in main validation)
  # if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  #   echo "Error: $repo_dir is not a git repository."
  #   exit 1
  # fi

  # Get the current branch name
  current_branch=$(git symbolic-ref --short HEAD)

  # Function to check and stash uncommitted changes
  stash_if_needed() {
    # Check for uncommitted changes (including untracked files)
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
      echo "Uncommitted changes detected. Stashing changes."
      git stash push -u -m "Auto-stash before switching or on main"
    else
      echo "No uncommitted changes to stash."
    fi
  }

  if [ "$current_branch" != "main" ]; then
    echo "Current branch is '$current_branch'. Stashing changes and switching to 'main'."
    stash_if_needed
    git checkout main
    git pull origin main
  else
    echo "Already on 'main' branch. Checking for uncommitted changes."
    stash_if_needed
  fi

  # Sync with upstream main if available
  if git remote get-url upstream > /dev/null 2>&1; then
    echo "Syncing with upstream/main..."
    git pull upstream main
  else
    echo "No upstream remote found. Using origin/main."
    git pull origin main
  fi

  # Generate branch name using Ollama
  echo "Generating branch name using Ollama based on task: '$TASK_CONTENT'..."
  ollama_prompt="Generate a concise, lowercase, git-branch-name-friendly name (use hyphens instead of spaces, max 40 chars) based on this task description: <task>\"$TASK_CONTENT\"</task>. Just output the name itself, nothing else."

  # Run Ollama and capture output, suppressing stderr for cleaner output, and filter <think> tags
  generated_name=$(ollama run "$OLLAMA_MODEL" "$ollama_prompt" 2>/dev/null | filter_ollama_output)

  # Sanitize the generated name
  # Remove leading/trailing whitespace, replace spaces/special chars with hyphens, convert to lowercase, truncate
  sanitized_name=$(echo "$generated_name" | xargs | tr -s '[:space:]' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-40)

  # Check if sanitization resulted in an empty string or if Ollama failed
  if [ -z "$sanitized_name" ]; then
    echo "Warning: Failed to generate branch name using Ollama or result was empty after sanitization. Falling back to timestamp-based name."
    new_branch="autocodex-$(date +%m%d-%H%M)"
  else
    new_branch="autocodex/$sanitized_name-$(date +%m%d-%H%M)"
  fi

  # Create a new branch for the task
  echo "Creating new branch '$new_branch' for the task..."
  git checkout -b "$new_branch"
  echo "Ready to work on branch: $new_branch"
}

# Function to commit changes
commit_changes() {
  local repo_dir="$(pwd)"

  # This functionality would come from your deliver:commit-changes task
  # Assuming it does something like:
  echo "Committing changes..."
  git add .

  diff=$(git diff --cached)

  # Generate a commit message by ollama
  ollama_prompt="Generate a concise, lowercase, git-commit-message-friendly message (max 50 chars) based on this task description: <task>\"$TASK_CONTENT\"</task> and code diff: <diff>$diff</diff>. Just output the message itself, nothing else."
  generated_message=$(ollama run "$OLLAMA_MODEL" "$ollama_prompt" 2>/dev/null | filter_ollama_output)
  git commit -m "$generated_message"
}

# Function to create PR
create_pr() {
  local repo_dir="$(pwd)"
  local current_branch=$(git symbolic-ref --short HEAD)

  # Push the current branch to origin
  echo "Pushing branch '$current_branch' to origin..."
  git push -u origin "$current_branch"
  if [ $? -ne 0 ]; then
      echo "Error: Failed to push branch to origin."
      exit 1
  fi

  # Get the last commit message for context
  last_commit_message=$(git log -1 --pretty=%B)

  # --- Generate PR Title ---
  echo "Generating PR title using Ollama..."
  ollama_title_prompt="Generate a concise PR title (max 70 chars) based on this task description: <task>\"$TASK_CONTENT\"</task>. Output only the title."
  generated_title=$(ollama run "$OLLAMA_MODEL" "$ollama_title_prompt" 2>/dev/null | filter_ollama_output)

  # Fallback for PR Title
  if [ -z "$generated_title" ]; then
      echo "Warning: Failed to generate PR title using Ollama. Using fallback title."
      pr_title="Autocodex: ${TASK_CONTENT:0:50}"
  else
      # Simple sanitization for title (remove leading/trailing whitespace)
      pr_title=$(echo "$generated_title" | xargs)
  fi

  # --- Generate PR Body ---
  echo "Generating PR body using Ollama..."
  ollama_body_prompt="Generate a brief PR description based on this task: <task>\"$TASK_CONTENT\"</task> and the commit message: <commit>\"$last_commit_message\"</commit>. Describe what was done. Output only the description."
  generated_body=$(ollama run "$OLLAMA_MODEL" "$ollama_body_prompt" 2>/dev/null | filter_ollama_output)

  # Fallback for PR Body
  if [ -z "$generated_body" ]; then
      echo "Warning: Failed to generate PR body using Ollama. Using fallback body."
      pr_body="This PR was automatically generated by autocodex to address the task: \"$TASK_CONTENT\".\n\nCommit: $last_commit_message"
  else
      # Simple sanitization for body (remove leading/trailing whitespace)
      pr_body=$(echo "$generated_body" | xargs)
  fi

  # Create the pull request using generated/fallback title and body
  echo "Creating pull request to upstream repository..."
  # For forked repos, we need to explicitly target the upstream repository
  upstream_repo=$(git remote get-url upstream 2>/dev/null | sed -E 's/.*github.com[:/]([^/]+\/[^.]+)(\.git)?$/\1/')

  if [ -n "$upstream_repo" ]; then
    # If upstream exists, create PR to upstream repository
    gh pr create --repo "$upstream_repo" --base main --title "$pr_title" --body "$pr_body"
  else
    # Fallback to origin if upstream is not configured
    echo "Warning: No upstream remote found. Creating PR to origin repository instead."
    gh pr create --title "$pr_title" --body "$pr_body"
  fi

  if [ $? -ne 0 ]; then
      echo "Error: Failed to create pull request using gh."
      # Note: Branch was already pushed, user might need to create PR manually.
      exit 1
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  # Check if this is the last argument and no flag is provided
  if [[ $# -eq 1 && ! "$1" =~ ^- ]]; then
    TASK_CONTENT="$1"
    shift
    continue
  fi

  case $1 in
    -f|--file)
      CONTEXT_FILE="$2"
      shift 2
      ;;
    -c|--content)
      TASK_CONTENT="$2"
      shift 2
      ;;
    -m|--model)
      OLLAMA_MODEL="$2"
      shift 2
      ;;
    -d|--deliver)
      DELIVER=true
      shift
      ;;
    -r|--raw)
      FORMAT_OUTPUT=false
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      # If it doesn't match any flag and isn't the last argument
      if [[ ! "$1" =~ ^- ]]; then
        TASK_CONTENT="$1"
        shift
      else
        echo "Unknown option: $1"
        print_usage
        exit 1
      fi
      ;;
  esac
done

# Check if current directory is under git management
if is_git_repo; then
  echo "No repository specified, using current directory as it's a git repository"
  # Get the repository name for informational purposes
  CURRENT_REPO=$(get_repo_name)
  echo "Detected repository: $CURRENT_REPO"
else
  echo "Warning: code-agent should be run inside a git repository."
fi

# Ensure task content is provided
if [ -z "$TASK_CONTENT" ]; then
  echo "Error: Task content must be specified. You can provide it as a positional argument or with -c/--content"
  print_usage
  exit 1
fi

# Execute the task
if [ "$DELIVER" = true ]; then
  # Run in delivery mode
  reset_to_clean_branch
  run_agent
  commit_changes
  create_pr
else
  # Run in normal mode
  run_agent
fi