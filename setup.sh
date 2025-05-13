#!/bin/bash

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CODE_AGENT_SCRIPT_PATH="$SCRIPT_DIR/code-agent.sh"
ZSHRC_FILE="$HOME/.zshrc"
ALIAS_LINE="alias cg='$CODE_AGENT_SCRIPT_PATH'"

echo "Setting up code-agent command..."

# Check if code-agent.sh exists and is executable
if [ ! -f "$CODE_AGENT_SCRIPT_PATH" ]; then
    echo "Error: code-agent.sh not found at $CODE_AGENT_SCRIPT_PATH"
    exit 1
fi
chmod +x "$CODE_AGENT_SCRIPT_PATH" # Ensure it's executable

# Check if the alias already exists in .zshrc
if grep -Fq "$ALIAS_LINE" "$ZSHRC_FILE"; then
    echo "Code-agent alias is already configured in $ZSHRC_FILE."
else
    echo "Adding code-agent alias to $ZSHRC_FILE..."
    # Add the alias to .zshrc
    echo -e "\n# Code-agent alias\n$ALIAS_LINE" >> "$ZSHRC_FILE"
    echo "Successfully added code-agent alias."
    echo "Please run 'source $ZSHRC_FILE' or open a new terminal to use the 'code-agent' command."
fi

echo "Setup complete."
