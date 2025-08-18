# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Server Foundation Code Agent repository that provides a Claude Code-based approach for automated code processing across multiple Open Cluster Management (OCM) repositories. The system allows for batch processing of tasks across multiple Git repositories with automated pull request creation.

---

# Server Foundation Code Agent Workflow Guide

## Overview

This guide describes the automated workflow for processing multiple Git repositories, making code changes according to specified tasks, and creating pull requests.

### Workspace Directory

- **`workspace/`**: Contains multiple project directories
  - Each subdirectory is a separate Git repository

## Project Configuration

Each project in the workspace has the following Git remote setup:

```
origin    → User's forked repository
upstream  → Original project repository (PR target)
```

- Default branch: `main`
- Release branches follow the pattern: `backplane-2.x`

## Workflow Process

### 1. Task Initialization

When the user initiates a task:

1. Read the contents of `task.md`
2. Parse the Records table - each row is a project to process

### 2. Project Processing Loop

For each record in the table:

#### a. Navigate to Project

```bash
cd workspace/<record.repo>
```

#### b. Prepare Repository

```bash
# Stash any uncommitted changes
git stash

# Fetch latest changes from all remotes
git fetch --all

# Checkout the specified upstream branch
git checkout upstream/<record.branch>
```

#### c. Create Feature Branch

1. Generate a short branch name (max 5 words) based on `task.description`
2. Follow Git branch naming best practices
3. Create and checkout the new branch:

```bash
git checkout -b <task_short_description>
```

#### d. Execute Task

- Implement code changes according to `task.description`
- Ensure all code comments are in English

#### e. Commit Changes

```bash
# All commits must be signed
git commit -s -m "Your commit message"
```

**Commit Requirements:**

- Use the `-s` flag for signing
- Message must be in English
- Keep messages concise (max 2 sentences)

#### f. Create Pull Request

Use GitHub CLI to create PR from fork to upstream:

```bash
gh pr create \
  --repo stolostron/<repo-name> \
  --base <base-branch> \
  --head <github-username>:<branch-name> \
  --title "..." \
  --body $'...'
```

**PR Requirements:**

- Always target the upstream repository
- Default base branch is `main` unless specified
- Title must be concise and in English
- Description should use markdown format with detailed reasoning
- Use `$'...'` syntax for proper escape sequence handling

## Important Notes

### Git Commands

- List branches: `git --no-pager branch`
- Get current username: `git config --get user.name`

### Code Standards

- All code comments must be in English
- Never use non-English characters in code comments

### Error Handling

- If a project fails, mark `pass` as `no` and provide a clear explanation in `result`
- Continue processing remaining projects even if one fails

## Quick Reference

| Action                   | Command                                     |
| ------------------------ | ------------------------------------------- |
| Stash changes            | `git stash`                                 |
| Fetch all remotes        | `git fetch --all`                           |
| Checkout upstream branch | `git checkout upstream/<branch>`            |
| Create feature branch    | `git checkout -b <branch-name>`             |
| Signed commit            | `git commit -s -m "message"`                |
| Create PR                | `gh pr create --repo stolostron/<repo> ...` |

---

# Target Yaml Management

## Overview

The target.yml configuration file defines which repositories and branches should be targeted for automated task execution across Open Cluster Management (OCM) projects.

## Known OCM Repositories

- ocm
- managedcluster-import-controller
- multicloud-operators-foundation
- cluster-proxy
- cluster-proxy-addon
- managed-serviceaccount
- clusterlifecycle-state-metrics
- klusterlet-addon-controller
- cluster-lifecycle-api

## Common Branch Patterns

- main (default branch)
- backplane-2.x (release branches: backplane-2.6, backplane-2.7, backplane-2.8, backplane-2.9, backplane-2.10, etc.)

## Target.yml Structure

The target.yml file should follow this format:

```yaml
targets:
  - repo: <repository-name>
    branch: <branch-name>
  - repo: <repository-name>
    branch: <branch-name>
```

## Usage Guidelines

### Range Expansion
When specifying a range like "backplane-2.6 to backplane-2.10", expand to include all intermediate versions.

### Repository Validation
Verify repository names against the known OCM repository list.

### Branch Validation
Ensure branch names follow expected patterns (main, backplane-2.x).

### All Repos Handling
When targeting "all repos", include all known OCM repositories.

### Incremental Updates
Preserve existing entries unless explicitly overriding.

### Conflict Resolution
When conflicts arise, ask for clarification rather than making assumptions.

## Error Handling

- If repository name is unclear or not in known list, ask for clarification
- If branch range is ambiguous, request specific version boundaries
- If target.yml doesn't exist, create it with proper YAML structure
- Validate YAML syntax before saving changes

## Quality Assurance

- Verify YAML syntax is valid
- Ensure no duplicate repository-branch combinations
- Confirm all specified repositories exist in the OCM ecosystem
- Validate branch names follow expected patterns