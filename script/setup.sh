#!/bin/bash

# Setup script to create target.yml and task.md files

echo "Creating target.yml and task.md files..."

# Create target.yml
cat > target.yml << 'EOF'
# Here is an example of target, each item in the list represents a target repository and branch.
# You can set multiple targets with different repos and different branches.
# Example:
target:
    - repo: managedcluster-import-controller
      branch: main
    - repo: managedcluster-import-controller
      branch: backplane-2.9
EOF

# Create task.md
cat > task.md << 'EOF'
# Task Description

This is the main task file that describes what needs to be done.

## Objectives

- Review and analyze the target repositories
- Implement necessary changes
- Ensure compatibility across different branches

## Notes

Add your specific task details here.
EOF

echo "✅ Successfully created target.yml"
echo "✅ Successfully created task.md"
echo ""
echo "Files created:"
echo "  - target.yml: Configuration file for target repositories and branches"
echo "  - task.md: Task description and objectives"
