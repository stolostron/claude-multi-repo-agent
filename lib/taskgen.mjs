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
 * Generate task file content
 * @param {Object} target - Target object {org, repo, branch}
 * @param {string} workspaceDir - Workspace directory path
 * @param {string} guideContent - Guide content
 * @param {string} taskContent - Task content
 * @returns {string} Generated task file content
 */
export function generateTaskContent(target, workspaceDir, guideContent, taskContent) {
  const { org, repo, branch } = target;
  const workspacePath = path.join(workspaceDir, repo);

  return `# Task: ${repo}/${branch} (from ${org}/${repo})

## Repository Info
- **Organization**: ${org}
- **Repository**: ${repo}
- **Branch**: ${branch}
- **Workspace Path**: ${workspacePath}

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
 * @param {Object} config - Configuration object
 * @returns {number} Number of generated tasks
 */
export async function generateTasks(paths, config) {
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

  // Generate task files
  console.log(`📂 Generating tasks in ${outputDir} directory...`);
  let taskCounter = 1;
  let successCount = 0;

  for (const target of targets) {
    const { org, repo, branch } = target;

    // Ensure repository exists in workspace
    console.log(`🔧 Setting up repository: ${org}/${repo}`);
    const setupSuccess = await ensureRepoExists(org, repo, workspaceDir, config.shallowClone);

    if (!setupSuccess) {
      console.warn(`⚠️  Warning: Failed to set up repository ${org}/${repo}, skipping...`);
      continue;
    }

    // Generate task file
    const taskFileName = `${String(taskCounter).padStart(3, '0')}_${repo}_${branch}.md`;
    const taskFilePath = path.join(outputDir, taskFileName);
    const taskFileContent = generateTaskContent(target, workspaceDir, guideContent, taskContent);

    await fs.writeFile(taskFilePath, taskFileContent, 'utf-8');
    console.log(`   ✅ Created: ${outputDir}/${taskFileName}`);

    taskCounter++;
    successCount++;
  }

  return successCount;
}
