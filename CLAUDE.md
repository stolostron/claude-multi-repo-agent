# Claude Multi-Repo Agent

This project provides an automated system for executing Claude Code tasks across multiple GitHub repositories simultaneously.

## Project Overview

**Claude Multi-Repo Agent** is a universal automation toolkit that:
- Executes tasks across multiple GitHub repositories and branches
- **Supports parallel execution** for faster processing across repository groups
- Automatically manages repository forks and clones
- Organizes task scenarios using predefined bundles
- Generates individual task files for each target repository-branch combination
- Leverages Claude Code for intelligent task execution
- Built with modern JavaScript using Google's Zx framework

## Key Components

### Main Script
- **Main script**: `gen-and-run-tasks.mjs`
- **Requirements**: Node.js 18+, `gh` CLI, `claude` CLI
- **Built-in features**: YAML/JSON parsing, colored output, intelligent concurrency control
- **Documentation**: See [README-ZX.md](README-ZX.md), [QUICKSTART-ZX.md](QUICKSTART-ZX.md)

### Core Configuration Files
- `target.yml`: Repository and branch configuration (root mode)
- `task.md`: Task description and requirements (root mode)
- `GUIDE.md`: Optional workflow instructions
- `config.json`: Optional configuration overrides

### Bundle Organization
- `bundles/`: Directory containing task scenario bundles
  - `bundles/scenario-name/target.yml`: Bundle-specific repository configuration
  - `bundles/scenario-name/task.md`: Bundle-specific task description
  - `bundles/scenario-name/GUIDE.md`: Bundle-specific workflow instructions (optional)
- Examples: `bundles/upgrade-deps/`, `bundles/security-patch/`, `bundles/docs-sync/`

### Directory Structure
- `workspace/`: Auto-managed repository clones with upstream remotes
- `tasks/`: Generated task files (format: `001_repo_branch.md`)
- `logs/`: Execution logs (when using `--save-logs`)
- `bundles/`: Task scenario bundles (NEW)

## Configuration Format

### target.yml Structure
```yaml
target:
  - org: organization-name    # GitHub organization
    repos: [repo1, repo2]     # Repository names
    branches: [main, develop] # Target branches
```

### Bundle Structure
Each bundle is a directory containing:
```
bundles/scenario-name/
├── target.yml    # Bundle-specific repository and branch configuration
├── task.md       # Bundle-specific task description and requirements
├── GUIDE.md      # Bundle-specific workflow instructions (optional)
└── config.json   # Bundle-specific configuration overrides (optional)
```

### Task File Template
Each generated task file contains:
- Repository metadata (org, repo, branch, workspace path)
- Workflow guide (from GUIDE.md - bundle-specific if available, otherwise root)
- Task description (from task.md - either root or bundle)

## Automation Workflow

1. **Repository Setup**: Automatically forks and clones repositories if not present in workspace
2. **Task Generation**: Creates individual task files for each org/repo/branch combination
3. **Task Execution**: Runs Claude Code on each task file (sequential or parallel)
   - **Sequential Mode**: Tasks execute one by one (default)
   - **Parallel Mode**: Repository groups execute concurrently for faster processing
4. **Progress Tracking**: Provides execution summaries and optional logging

### Parallel Execution Strategy

- **Repository-Level Concurrency**: Different repositories can execute in parallel
- **Branch-Level Safety**: Tasks for the same repository execute sequentially to avoid conflicts
- **Smart Grouping**: Automatically groups tasks by repository to prevent Git conflicts
- **Configurable Limits**: Control maximum concurrent jobs with `--max-jobs`

## Usage Patterns

### Quick Start

```bash
zx gen-and-run-tasks.mjs --bundle bundles/my-task
# or using npm
npm start -- --bundle bundles/my-task
```

### Standard Workflow (Root Configuration)

```bash
zx gen-and-run-tasks.mjs              # Generate and execute all tasks
zx gen-and-run-tasks.mjs --save-logs  # With logging
zx gen-and-run-tasks.mjs --parallel   # Execute tasks in parallel
```

### Bundle Workflow (Recommended)

```bash
zx gen-and-run-tasks.mjs --bundle bundles/upgrade-deps     # Execute dependency update bundle
zx gen-and-run-tasks.mjs --bundle bundles/security-patch  # Execute security patch bundle
zx gen-and-run-tasks.mjs --bundle bundles/docs-sync       # Execute documentation sync bundle

# Parallel execution for faster processing
zx gen-and-run-tasks.mjs --bundle bundles/upgrade-deps --parallel
zx gen-and-run-tasks.mjs --bundle bundles/security-patch --parallel --max-jobs 2
```

### Advanced Options

```bash
zx gen-and-run-tasks.mjs --generate-only                    # Only generate task files
zx gen-and-run-tasks.mjs --run-only                         # Execute existing tasks
zx gen-and-run-tasks.mjs --bundle bundles/scenario --generate-only  # Generate from bundle only
zx gen-and-run-tasks.mjs --bundle bundles/scenario --guide-file custom-guide.md  # Bundle + custom guide

# Parallel execution options
zx gen-and-run-tasks.mjs --parallel                         # Default 4 concurrent repository groups
zx gen-and-run-tasks.mjs --parallel --max-jobs 8           # Custom concurrency level
zx gen-and-run-tasks.mjs --bundle bundles/upgrade-deps --parallel --max-jobs 2  # Bundle + parallel
```

## Git Integration

The system automatically:
- Checks for existing repository forks
- Creates forks if needed using GitHub CLI
- Clones forked repositories to workspace
- Sets up upstream remotes for PR workflows
- Handles multiple organizations and repositories

## Configuration System

The system supports JSON-based configuration files to set default behavior:

### Configuration Files

1. **Root Configuration** (`config.json`): Default settings for all executions
2. **Bundle Configuration** (`bundles/scenario/config.json`): Bundle-specific overrides

### Bundle Files

Bundles can include any combination of these files:
- `target.yml` (required): Repository and branch configuration
- `task.md` (required): Task description and requirements
- `GUIDE.md` (optional): Bundle-specific workflow instructions
- `config.json` (optional): Bundle-specific configuration overrides

### Configuration Schema

```json
{
  "parallel": false,
  "maxJobs": 4,
  "saveLogs": false,
  "generateOnly": false,
  "runOnly": false,
  "guideFile": "GUIDE.md"
}
```

### Configuration Priority

The system applies configuration in this priority order:
1. **Command line options** (highest priority)
2. **Bundle-specific config.json** 
3. **Root config.json**
4. **Built-in defaults** (lowest priority)

### Examples

**Root Configuration** (`config.json`):
```json
{
  "parallel": true,
  "maxJobs": 2,
  "saveLogs": true,
  "guideFile": "GUIDE.md"
}
```

**Bundle-specific Override** (`bundles/security-patch/config.json`):
```json
{
  "maxJobs": 8,
  "generateOnly": true
}
```

With these configs, running the script with `--bundle bundles/security-patch` would use:
- `maxJobs: 8` (from bundle config)
- `generateOnly: true` (from bundle config)
- `parallel: true` and `saveLogs: true` (from root config)
- Command line options would override any of these

## Requirements

- **Claude Code CLI** (authenticated) - `claude --version`
- **GitHub CLI** `gh` (authenticated) - `gh auth status`
- **Node.js** 18.0.0 or higher - `node --version`
- **NPM** 9.0.0 or higher - `npm --version`
- **Dependencies**: Auto-installed via `npm install`
  - `zx` - Google Zx framework
  - `yaml` - YAML parsing
  - `chalk` - Colored output
  - `p-limit` - Concurrency control

## Getting Started

```bash
# Check requirements
node --version  # Should be 18.0+
gh auth status
claude --version

# Install dependencies (first time only)
npm install

# Run your first task
zx gen-and-run-tasks.mjs --bundle bundles/my-task
# or
npm start -- --bundle bundles/my-task
```

## Documentation

- **Main Documentation**: This file (CLAUDE.md)
- **User Guide**: [README-ZX.md](README-ZX.md)
- **Quick Start**: [QUICKSTART-ZX.md](QUICKSTART-ZX.md)
- **Technical Details**: [ZX-IMPLEMENTATION-SUMMARY.md](ZX-IMPLEMENTATION-SUMMARY.md)
- **File Extension Explained**: [MJS-vs-JS-EXPLAINED.md](MJS-vs-JS-EXPLAINED.md)

## Bundle Examples

### Common Bundle Scenarios

1. **Dependency Updates** (`bundles/upgrade-deps/`)
   - Target: Development repositories across multiple organizations
   - Task: Update package.json, requirements.txt, go.mod, etc.

2. **Security Patches** (`bundles/security-patch/`)
   - Target: Production and security-critical repositories
   - Task: Apply CVE fixes and security updates

3. **Documentation Sync** (`bundles/docs-sync/`)
   - Target: Documentation repositories and websites
   - Task: Synchronize content, update links, standardize formatting

4. **Compliance Updates** (`bundles/compliance/`)
   - Target: All organizational repositories
   - Task: Update license headers, add security policies, standardize configurations

---

This tool is designed for batch operations like dependency updates, security patches, documentation synchronization, and configuration standardization across repository ecosystems. The bundle system enables organized, reusable task scenarios for efficient multi-repository management.

Built with modern JavaScript using Google's Zx framework for maintainability, cross-platform compatibility, and excellent developer experience.