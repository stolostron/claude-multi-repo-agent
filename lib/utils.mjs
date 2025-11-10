#!/usr/bin/env zx

import chalk from 'chalk';

/**
 * Format timestamp in human readable format
 * @returns {string} Formatted timestamp
 */
export function formatTimestamp() {
  const now = new Date();
  return now.toISOString().replace('T', ' ').substring(0, 19);
}

/**
 * Calculate duration between two timestamps
 * @param {number} startTime - Start time in milliseconds
 * @param {number} endTime - End time in milliseconds
 * @returns {number} Duration in seconds
 */
export function calculateDuration(startTime, endTime) {
  return Math.floor((endTime - startTime) / 1000);
}

/**
 * Format duration in human readable format
 * @param {number} durationSeconds - Duration in seconds
 * @returns {string} Formatted duration
 */
export function formatDuration(durationSeconds) {
  const hours = Math.floor(durationSeconds / 3600);
  const minutes = Math.floor((durationSeconds % 3600) / 60);
  const seconds = durationSeconds % 60;

  if (hours > 0) {
    return `${hours}h ${minutes}m ${seconds}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds}s`;
  } else {
    return `${seconds}s`;
  }
}

/**
 * Print section header
 * @param {string} title - Section title
 */
export function printHeader(title) {
  console.log('');
  console.log('═══════════════════════════════════════════════════════════════════════════════════');
  console.log(chalk.bold(title));
  console.log('═══════════════════════════════════════════════════════════════════════════════════');
  console.log('');
}

/**
 * Print usage information
 */
export function printUsage() {
  console.log('');
  console.log('🚀 ═══════════════════════════════════════════════════════════════════════════════════');
  console.log('🤖 CLAUDE MULTI-REPO AGENT (Zx Edition)');
  console.log('═══════════════════════════════════════════════════════════════════════════════════');
  console.log('');
  console.log('📋 Usage: zx gen-and-run-tasks.mjs --bundle BUNDLE_PATH [OPTIONS]');
  console.log('   or:    npm start -- --bundle BUNDLE_PATH [OPTIONS]');
  console.log('');
  console.log('⚙️  Required:');
  console.log('  📦 --bundle PATH       Bundle directory containing target.yml and task.md (REQUIRED)');
  console.log('');
  console.log('⚙️  Optional:');
  console.log('  📝 --guide-file FILE   Specify custom guide file (default: GUIDE.md or from config)');
  console.log('  📝 --generate-only     Only generate task files, don\'t run them');
  console.log('  ▶️  --run-only         Only run existing task files (skip generation)');
  console.log('  📄 --save-logs         Save Claude CLI output to log files (when running)');
  console.log('  🚀 --parallel          Execute tasks in parallel (automatically enables --save-logs)');
  console.log('  ⚙️  --max-jobs NUM     Maximum number of parallel jobs (default: 4, only with --parallel)');
  console.log('  📥 --shallow-clone     Use shallow clone for faster repository setup (default: true)');
  console.log('  📥 --full-clone        Use full clone with complete git history');
  console.log('  ❓ --help, -h          Show this help message');
  console.log('');
  console.log('📁 Configuration files:');
  console.log('  📜 config.json         Root configuration file (applies to all executions)');
  console.log('  📦 bundle/config.json  Bundle-specific configuration (overrides root config)');
  console.log('');
  console.log('📦 Bundle structure:');
  console.log('  bundles/my-task/');
  console.log('  ├── target.yml         Repository and branch configuration (REQUIRED)');
  console.log('  ├── task.md            Task description and requirements (REQUIRED)');
  console.log('  ├── GUIDE.md           Bundle-specific workflow instructions (optional)');
  console.log('  └── config.json        Bundle-specific configuration overrides (optional)');
  console.log('');
  console.log('💡 Examples:');
  console.log('  zx gen-and-run-tasks.mjs --bundle bundles/upgrade-deps');
  console.log('  npm start -- --bundle bundles/security-patch --parallel');
  console.log('  zx gen-and-run-tasks.mjs --bundle bundles/docs-sync --generate-only');
  console.log('');
  console.log('🔄 Priority: Command line options > Bundle config > Root config > Defaults');
  console.log('🎯 Default behavior: Generate task files and then run them sequentially');
  console.log('🚀 Parallel mode: Tasks from the same repository are still executed sequentially to avoid conflicts');
  console.log('═══════════════════════════════════════════════════════════════════════════════════');
  console.log('');
}

/**
 * Parse command line arguments (simplified - zx provides argv)
 * @param {Object} argv - Arguments from zx
 * @returns {Object} Parsed options
 */
export function parseArguments(argv) {
  const options = {
    bundle: argv.bundle,
    guideFile: argv['guide-file'],
    generateOnly: argv['generate-only'],
    runOnly: argv['run-only'],
    saveLogs: argv['save-logs'],
    parallel: argv.parallel,
    maxJobs: argv['max-jobs'] ? parseInt(argv['max-jobs']) : undefined,
    shallowClone: argv['shallow-clone'] ? true : (argv['full-clone'] ? false : undefined),
    help: argv.help || argv.h,
  };

  return options;
}

/**
 * Extract repository name from task filename
 * Format: 001_repo_branch.md -> repo
 * @param {string} filename - Task filename
 * @returns {string} Repository name
 */
export function extractRepoFromFilename(filename) {
  // Remove .md extension and number prefix
  const base = filename.replace(/\.md$/, '').replace(/^\d+_/, '');

  // Remove branch suffix (last underscore part)
  const parts = base.split('_');
  if (parts.length > 1) {
    parts.pop(); // Remove last part (branch)
    return parts.join('_');
  }

  return base;
}

/**
 * Group task files by repository to avoid conflicts
 * @param {string[]} taskFiles - Array of task file paths
 * @returns {Object} Map of repository -> task files
 */
export function groupTasksByRepo(taskFiles) {
  const groups = {};

  for (const taskFile of taskFiles) {
    const filename = taskFile.split('/').pop();
    const repo = extractRepoFromFilename(filename);

    if (!groups[repo]) {
      groups[repo] = [];
    }
    groups[repo].push(taskFile);
  }

  return groups;
}
