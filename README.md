# Server Foundation Code Agent

This repository provides two approaches for automated code processing across multiple repositories:

1. **Augment Code-based approach** (original method)
2. **Gemini CLI-based approach** (new CI mode)

## Prerequisites

First run the setup scripts:

```bash
./script/setup.sh
./script/setup-repos.sh
```

Then modify 2 files: `task.md` and `target.yml` according to your requirements.

---

## Approach 1: Augment Code-based (Original)

This approach uses Augment Code's task list feature for interactive task management.

### Steps:

1. Run the task list generator:
   ```bash
   ./script/generate-task-list.sh
   ```
   This will generate a `task-list.md` file.

2. Import the task list into Augment Code:

   <img width="593" alt="image" src="https://github.com/user-attachments/assets/c782e2c0-94c8-4427-b95e-c701a3fbd87e" />

   Import the task-list.md and you will find tasks listed in the task panel:

   <img width="601" alt="image" src="https://github.com/user-attachments/assets/53cb7132-bf9c-4dc1-96ed-57f0b6cc2ae6" />

3. Execute all tasks:

   <img width="212" alt="image" src="https://github.com/user-attachments/assets/8df689a0-b68d-4a1c-8567-fa93f3e16c2d" />

---

## Approach 2: Gemini CLI-based (CI Mode)

This approach uses Gemini CLI for automated, non-interactive task execution suitable for CI/CD pipelines.

### Prerequisites:

- Install [Gemini CLI](https://github.com/google/generative-ai-cli)
- Install [yq](https://github.com/mikefarah/yq) for YAML parsing:
  ```bash
  brew install yq
  ```

### Steps:

1. Generate the Gemini task list:
   ```bash
   ./script/generate-task-list-for-gemini.sh
   ```
   This will generate a `gemini-task-list.yml` file with structured tasks.

2. Execute all tasks automatically:
   ```bash
   ./script/run-gemini-task-list.sh
   ```
   This script will:
   - Process each task in the YAML file
   - Navigate to the corresponding repository directory
   - Execute the task using `gemini --yolo -p "<prompt>"`
   - Log all execution details to `gemini-execution.log`

### Features:

- **Non-interactive execution**: Suitable for CI/CD pipelines
- **Detailed logging**: All execution details are logged
- **Error handling**: Failed tasks are reported with details
- **Progress tracking**: Shows current task progress
- **Automatic directory navigation**: Changes to each repository's directory automatically

---

## File Structure

- `task.md`: Contains the task description to be executed
- `target.yml`: Defines target repositories and branches
- `GUIDE.md`: Contains workflow guidelines and best practices
- `script/generate-task-list.sh`: Generates task list for Augment Code
- `script/generate-task-list-for-gemini.sh`: Generates YAML task list for Gemini CLI
- `script/run-gemini-task-list.sh`: Executes Gemini CLI tasks automatically
