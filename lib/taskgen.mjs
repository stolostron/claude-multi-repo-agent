#!/usr/bin/env zx

import { $, fs, path, chalk } from 'zx';
import YAML from 'yaml';
import { ensureRepoExists } from './repository.mjs';

/**
 * Parse target.yml file
 * @param {string} targetFile - Path to target.yml
 * @returns {Array} Array of {org, repo, branch} objects
 */
export async function parseTargetFile(targetFile) {
  try {
    const content = await fs.readFile(targetFile, 'utf-8');
    const data = YAML.parse(content);

    if (!data || !data.target || !Array.isArray(data.target)) {
      throw new Error('Invalid target.yml format: missing or invalid "target" array');
    }

    const targets = [];

    for (const item of data.target) {
      if (!item.org || !item.repos || !item.branches) {
        console.warn('⚠️  Warning: Skipping invalid target item:', item);
        continue;
      }

      // Generate all combinations of repos and branches for this org
      for (const repo of item.repos) {
        for (const branch of item.branches) {
          targets.push({
            org: item.org,
            repo: repo,
            branch: branch,
          });
        }
      }
    }

    return targets;
  } catch (error) {
    throw new Error(`Failed to parse target file: ${error.message}`);
  }
}

/**
 * Sanitize branch name for use in directory names
 * @param {string} branch - Branch name
 * @returns {string} Sanitized branch name
 */
export function sanitizeBranchName(branch) {
  return branch.replace(/\//g, '_');
}

/**
 * Create git worktree for a branch in a repository subdirectory
 * @param {string} repoDir - Repository directory in workspace
 * @param {string} taskDirPath - Path for the task directory (parent)
 * @param {string} branch - Branch name
 * @param {string} repo - Repository name (for subdirectory)
 * @returns {string|null} Path to the worktree subdirectory, or null if failed
 */
export async function createWorktree(repoDir, taskDirPath, branch, repo) {
  try {
    console.log(`   🌲 Creating worktree for branch ${branch}...`);

    // Create task directory first
    await fs.ensureDir(taskDirPath);

    // Calculate the worktree subdirectory path
    const worktreeRepoPath = path.join(taskDirPath, repo);

    // Check if branch exists locally, if not try upstream/branch, then origin/branch
    let branchRef = branch;
    try {
      await $`git -C ${repoDir} rev-parse --verify ${branch}`;
    } catch {
      // Branch doesn't exist locally, try upstream/branch first (for forked repos)
      console.log(`   📍 Branch ${branch} not found locally, trying upstream/${branch}...`);
      try {
        await $`git -C ${repoDir} rev-parse --verify upstream/${branch}`;
        branchRef = `upstream/${branch}`;
        console.log(`   ✅ Found branch on upstream remote`);
      } catch {
        // Try origin/branch as fallback
        console.log(`   📍 Branch not found on upstream, trying origin/${branch}...`);
        branchRef = `origin/${branch}`;
      }
    }

    // Create worktree in subdirectory
    await $`git -C ${repoDir} worktree add ${worktreeRepoPath} ${branchRef}`;
    console.log(`   ✅ Successfully created worktree at ${worktreeRepoPath}`);
    return worktreeRepoPath;
  } catch (error) {
    console.error(`   ❌ Error: Failed to create worktree for branch ${branch}`);
    console.error(`      ${error.message}`);
    return null;
  }
}

/**
 * Generate task file content
 * @param {Object} target - Target object {org, repo, branch}
 * @param {string} taskDirPath - Task directory path (parent directory)
 * @param {string} worktreeRepoPath - Worktree repository subdirectory path
 * @param {string} guideContent - Guide content
 * @param {string} taskContent - Task content
 * @returns {string} Generated task file content
 */
export function generateTaskContent(target, taskDirPath, worktreeRepoPath, guideContent, taskContent) {
  const { org, repo, branch } = target;

  return `# Task: ${repo}/${branch} (from ${org}/${repo})

## Repository Info
- **Organization**: ${org}
- **Repository**: ${repo}
- **Branch**: ${branch}
- **Task Directory**: ${taskDirPath}
- **Repository Code**: ${worktreeRepoPath}

## Guide
<guide>
${guideContent}
</guide>

## Description
<task>
${taskContent}
</task>
`;
}

/**
 * Generate all task files
 * @param {Object} paths - File paths configuration
 * @returns {number} Number of generated tasks
 */
export async function generateTasks(paths) {
  const { targetFile, taskFile, guideFile, outputDir, workspaceDir } = paths;

  // Validate required files exist
  if (!(await fs.pathExists(targetFile))) {
    throw new Error(`${targetFile} not found`);
  }
  if (!(await fs.pathExists(taskFile))) {
    throw new Error(`${taskFile} not found`);
  }
  if (!(await fs.pathExists(guideFile))) {
    throw new Error(`${guideFile} not found`);
  }

  // Read task and guide content
  const taskContent = (await fs.readFile(taskFile, 'utf-8'))
    .split('\n')
    .filter(line => line.trim())
    .join('\n');

  const guideContent = (await fs.readFile(guideFile, 'utf-8'))
    .split('\n')
    .filter(line => line.trim())
    .join('\n');

  // Parse target file
  console.log(`📂 Parsing ${targetFile}...`);
  const targets = await parseTargetFile(targetFile);
  console.log(`📋 Found ${targets.length} target combinations`);

  // Clean and create output directory
  console.log(`🧹 Cleaning up existing tasks directory...`);
  await fs.remove(outputDir);
  await fs.ensureDir(outputDir);

  // Create workspace directory
  await fs.ensureDir(workspaceDir);

  // Clean up any existing worktrees from previous runs
  console.log(`🧹 Cleaning up any stale worktrees...`);
  for (const target of targets) {
    const { repo } = target;
    const repoDir = path.join(workspaceDir, repo);

    if (await fs.pathExists(repoDir)) {
      try {
        await $`git -C ${repoDir} worktree prune`;
      } catch (error) {
        // Ignore errors during cleanup
      }
    }
  }

  // Generate task files with worktrees
  console.log(`📂 Generating task worktrees in ${outputDir} directory...`);
  let taskCounter = 1;
  let successCount = 0;

  for (const target of targets) {
    const { org, repo, branch } = target;

    // Ensure repository exists in workspace
    console.log(`🔧 Setting up repository: ${org}/${repo}`);
    const setupSuccess = await ensureRepoExists(org, repo, workspaceDir);

    if (!setupSuccess) {
      console.warn(`⚠️  Warning: Failed to set up repository ${org}/${repo}, skipping...`);
      continue;
    }

    // Create worktree directory
    const sanitizedBranch = sanitizeBranchName(branch);
    const taskDirName = `${String(taskCounter).padStart(3, '0')}_${repo}_${sanitizedBranch}`;
    const taskDirPath = path.resolve(path.join(outputDir, taskDirName));
    const repoDir = path.join(workspaceDir, repo);

    // Create worktree in subdirectory
    console.log(`   🌲 Creating worktree: ${taskDirName}/${repo}`);
    const worktreeRepoPath = await createWorktree(repoDir, taskDirPath, branch, repo);

    if (!worktreeRepoPath) {
      console.warn(`⚠️  Warning: Failed to create worktree for ${org}/${repo}@${branch}, skipping...`);
      continue;
    }

    // Generate task.md file at task directory root (NOT inside worktree)
    const taskFilePath = path.join(taskDirPath, 'task.md');
    const taskFileContent = generateTaskContent(target, taskDirPath, worktreeRepoPath, guideContent, taskContent);

    await fs.writeFile(taskFilePath, taskFileContent, 'utf-8');
    console.log(`   ✅ Created: ${taskDirName}/task.md`);

    taskCounter++;
    successCount++;
  }

  return successCount;
}
