# Code Agent

An automated workflow that uses AI to make code changes across multiple repositories based on GitHub issues.

## Overview

Code Agent monitors specific GitHub issues, automatically makes code changes in selected repositories based on the issue description, and creates pull requests with those changes.

## How It Works

1. A user creates an issue using the `code_agent_task.yml` template
2. The user selects target repositories by checking boxes in the issue
3. The Code Agent workflow automatically:
   - Extracts the selected repositories from the issue
   - For each repository:
     - Clones the repository
     - Creates a new branch
     - Uses AI (Claude 3.7 Sonnet) to make code changes based on the issue description
     - Generates a commit message
     - Creates a pull request to the original repository
     - Posts a summary comment on the issue

## Requirements

- GitHub Actions workflow permissions for:
  - Repository contents (write)
  - Pull requests (write)
  - Issues (write)

## Setup

The workflow requires the following secrets:

- `AGENT_GH_TOKEN`: GitHub token with repository access
- `OPENAI_API_KEY`: OpenAI API key
- `OPENROUTER_API_KEY`: OpenRouter API key

## Dependencies

The workflow requires the following tools:

### mods

[mods](https://github.com/charmbracelet/mods) is a command-line AI tool by Charm that connects to LLM providers.

Installation in the workflow:

```bash
go install github.com/charmbracelet/mods@latest
```

Used for:

- Generating commit messages from git diffs
- Creating summaries of code changes

### codex

[@openai/codex](https://www.npmjs.com/package/@openai/codex) is a CLI tool that provides AI code assistance.

Installation in the workflow:

```bash
npm i -g @openai/codex@0.1.2504251709
```

Used for:

- Making automatic code changes based on natural language instructions
- Analyzing and modifying repository code

**Note**: The workflow uses a specific version of codex (0.1.2504251709) to avoid sandbox-related issues in GitHub Actions runners.

## Usage

1. Create a new issue using the Code Agent issue template
2. Fill in the task description with clear instructions for what code changes are needed
3. Check the boxes next to the repositories where you want the changes to be applied
4. Submit the issue

The Code Agent will automatically process your request and create pull requests with the requested changes.

## Workflow Details

- Triggered by: Opening or reopening issues
- Limited to specific users: xuezhaojun, zhujian7, qiujian16, zhiweiyin318, haoqing0110, elgnay
- Uses AI models:
  - mods with GPT-4o for commit messages and summaries
  - codex with Claude 3.7 Sonnet for code changes

## Example Issue Template

```markdown
### Task Description

Add logging to the cluster-proxy-addon component to improve debugging capabilities.

### Target Repositories

- [ ] open-cluster-management-io/ocm
- [ ] open-cluster-management-io/managed-serviceaccount
- [x] stolostron/cluster-proxy-addon
- [ ] stolostron/backplane-operator
```

The AI agent will only operate on the repositories with checked boxes.

## Limitations

- codex can't run commands that require network access, so you can run `make test` to test the code locally, but you can't run `go get` to install dependencies.
- codex can't create new files, codex can only edit existing files.
- codex is not stable for CI mode: https://github.com/openai/codex/issues/156

## TODO

### Make the Project More Testable

- Create local testing scripts that simulate the GitHub environment
- Extract core workflow logic into standalone scripts for easier local testing
- Add `workflow_dispatch` trigger with input parameters to simulate issues
- Implement test flags to control behavior (e.g., skip actual PR creation)
- Use environment variables to differentiate between test and production environments
- Leverage [nektos/act](https://github.com/nektos/act) to run GitHub Actions locally
- Modularize complex logic into separate functions or reusable actions
- Add mock services for GitHub API interactions
- Implement logging levels for better debugging
- Create a development guide with testing procedures

### Test with other code-agent solutions

- [smolagents](https://github.com/huggingface/smolagents?tab=readme-ov-file)
