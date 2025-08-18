# Server Foundation Code Agent (Claude Code Based)

This repository provides a Claude Code-based approach for automated code processing across multiple Open Cluster Management (OCM) repositories.

## Quick Start

### 1. Initial Setup

Run the setup scripts to prepare your environment:

```bash
./script/setup.sh          # Creates target.yml and task.md template files
./script/setup-repos.sh    # Clones OCM repositories to workspace/ directory
```

### 2. Configure Your Task

Edit the generated files according to your requirements:
- `task.md`: Define the task description and objectives
- `target.yml`: Specify target repositories and branches

### 3. Generate Individual Tasks

```bash
./script/generate-tasks.sh
```

This creates individual task files in the `tasks/` directory, one for each repository-branch combination defined in `target.yml`.

### 4. Execute Tasks

Choose one of the following execution methods:

#### Option A: Run All Tasks Automatically
```bash
./script/run-tasks.sh                # Print output directly to console
./script/run-tasks.sh --save-logs    # Save output to log files in logs/
```

#### Option B: Manual Execution via Claude CLI
Process individual task files manually:
```bash
cat tasks/001_ocm_main.md | claude -p "Execute this task"
```

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `setup.sh` | Creates initial `target.yml` and `task.md` template files |
| `setup-repos.sh` | Clones OCM repositories from your GitHub forks to `workspace/` |
| `generate-tasks.sh` | Generates individual task files from `target.yml` and `task.md` |
| `run-tasks.sh` | Executes all tasks automatically using Claude CLI |

## File Structure

- `task.md`: Task description template (created by setup.sh)
- `target.yml`: Repository and branch configuration (created by setup.sh)
- `CLAUDE.md`: Workflow guidelines and project instructions
- `workspace/`: Contains cloned repositories (created by setup-repos.sh)
- `tasks/`: Individual task files (created by generate-tasks.sh)
- `logs/`: Task execution logs (created by run-tasks.sh --save-logs)

## Supported OCM Repositories

- ocm
- managedcluster-import-controller
- multicloud-operators-foundation
- cluster-proxy
- cluster-proxy-addon
- managed-serviceaccount
- clusterlifecycle-state-metrics
- klusterlet-addon-controller
- cluster-lifecycle-api