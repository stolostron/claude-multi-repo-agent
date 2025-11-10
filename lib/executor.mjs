#!/usr/bin/env zx

import { $, fs, path, chalk } from 'zx';
import pLimit from 'p-limit';
import { formatTimestamp, calculateDuration, formatDuration, groupTasksByRepo } from './utils.mjs';

/**
 * Extract workspace path from task file
 * @param {string} taskFile - Path to task file
 * @returns {string} Workspace path
 */
async function extractWorkspacePath(taskFile) {
  const content = await fs.readFile(taskFile, 'utf-8');
  const match = content.match(/^- \*\*Workspace Path\*\*: (.+)$/m);

  if (!match) {
    throw new Error('Could not extract workspace path from task file');
  }

  return match[1].trim();
}

/**
 * Run a single task
 * @param {string} taskFile - Path to task file
 * @param {string} logFile - Path to log file (if saving logs)
 * @param {boolean} saveLogs - Whether to save logs
 * @returns {Object} Task result {success, duration, startTime, endTime}
 */
export async function runTask(taskFile, logFile = null, saveLogs = false) {
  const taskName = path.basename(taskFile, '.md');
  const startTimestamp = formatTimestamp();
  const startTime = Date.now();

  console.log('');
  console.log(`🚀 Processing: ${taskName}`);
  console.log(`🕰️  Started at: ${startTimestamp}`);

  try {
    // Extract workspace path
    const workspacePath = await extractWorkspacePath(taskFile);

    if (!(await fs.pathExists(workspacePath))) {
      throw new Error(`Workspace directory does not exist: ${workspacePath}`);
    }

    console.log(`📁 Changing to repository directory: ${workspacePath}`);

    // Run Claude CLI
    if (saveLogs) {
      console.log(`🤖 Running Claude CLI... (output saved to log)`);
      const taskContent = await fs.readFile(taskFile, 'utf-8');

      // Ensure log file directory exists before writing
      await fs.ensureDir(path.dirname(logFile));

      // Convert log file to absolute path for use in subshell
      const absoluteLogFile = path.resolve(logFile);

      try {
        // Run claude command and save output
        await $`cd ${workspacePath} && echo ${taskContent} | claude -p "Execute this task" --verbose --output-format text --dangerously-skip-permissions > ${absoluteLogFile} 2>&1`;
      } catch (error) {
        // Command failed, but output was saved to log
        const endTimestamp = formatTimestamp();
        const endTime = Date.now();
        const duration = calculateDuration(startTime, endTime);
        const formattedDuration = formatDuration(duration);

        console.log(`🏁 Finished at: ${endTimestamp}`);
        console.log(`⏱️  Duration: ${formattedDuration}`);
        console.log(`❌ Failed: ${taskName}`);
        console.log(`📄 Log: ${logFile}`);

        return {
          success: false,
          taskName,
          startTimestamp,
          endTimestamp,
          duration,
          formattedDuration,
          logFile,
        };
      }
    } else {
      console.log(`🤖 Running Claude CLI...`);
      console.log('────────────────────────────────────────');

      const taskContent = await fs.readFile(taskFile, 'utf-8');

      try {
        // Run claude command with direct output
        await $`cd ${workspacePath} && echo ${taskContent} | claude -p "Execute this task" --verbose --output-format text --dangerously-skip-permissions`;
        console.log('────────────────────────────────────────');
      } catch (error) {
        console.log('────────────────────────────────────────');

        const endTimestamp = formatTimestamp();
        const endTime = Date.now();
        const duration = calculateDuration(startTime, endTime);
        const formattedDuration = formatDuration(duration);

        console.log(`🏁 Finished at: ${endTimestamp}`);
        console.log(`⏱️  Duration: ${formattedDuration}`);
        console.log(`❌ Failed: ${taskName}`);

        return {
          success: false,
          taskName,
          startTimestamp,
          endTimestamp,
          duration,
          formattedDuration,
        };
      }
    }

    const endTimestamp = formatTimestamp();
    const endTime = Date.now();
    const duration = calculateDuration(startTime, endTime);
    const formattedDuration = formatDuration(duration);

    console.log(`🏁 Finished at: ${endTimestamp}`);
    console.log(`⏱️  Duration: ${formattedDuration}`);
    console.log(`✅ Completed: ${taskName}`);

    if (saveLogs) {
      console.log(`📄 Log: ${logFile}`);
    }

    return {
      success: true,
      taskName,
      startTimestamp,
      endTimestamp,
      duration,
      formattedDuration,
      logFile,
    };
  } catch (error) {
    const endTimestamp = formatTimestamp();
    const endTime = Date.now();
    const duration = calculateDuration(startTime, endTime);
    const formattedDuration = formatDuration(duration);

    console.log(`🏁 Finished at: ${endTimestamp}`);
    console.log(`⏱️  Duration: ${formattedDuration}`);
    console.log(`❌ Failed: ${taskName} - ${error.message}`);

    return {
      success: false,
      taskName,
      startTimestamp,
      endTimestamp,
      duration,
      formattedDuration,
      error: error.message,
    };
  }
}

/**
 * Execute tasks sequentially
 * @param {string[]} taskFiles - Array of task file paths
 * @param {string} logDir - Log directory path
 * @param {boolean} saveLogs - Whether to save logs
 * @returns {Object} Execution results {successful, failed, results}
 */
export async function executeSequential(taskFiles, logDir, saveLogs = false) {
  console.log('🔄 Running in sequential mode');

  const results = [];
  let successful = 0;
  let failed = 0;

  for (const taskFile of taskFiles) {
    const taskName = path.basename(taskFile, '.md');
    const logFile = saveLogs ? path.join(logDir, `${taskName}.log`) : null;

    const result = await runTask(taskFile, logFile, saveLogs);
    results.push(result);

    if (result.success) {
      successful++;
    } else {
      failed++;
    }

    console.log('');
  }

  return { successful, failed, results };
}

/**
 * Execute tasks in parallel (grouped by repository)
 * @param {string[]} taskFiles - Array of task file paths
 * @param {string} logDir - Log directory path
 * @param {number} maxJobs - Maximum concurrent jobs
 * @returns {Object} Execution results {successful, failed, results}
 */
export async function executeParallel(taskFiles, logDir, maxJobs = 4) {
  console.log(`🚀 Running in parallel mode (max ${maxJobs} concurrent repository groups)`);

  // Group tasks by repository
  const taskGroups = groupTasksByRepo(taskFiles);
  const repoNames = Object.keys(taskGroups);

  console.log(`📂 Found ${repoNames.length} repository groups to process`);

  // Create concurrency limiter
  const limit = pLimit(maxJobs);

  // Track all results
  const allResults = [];
  let successful = 0;
  let failed = 0;

  // Process each repository group
  const groupPromises = repoNames.map((repo) => {
    return limit(async () => {
      const repoTasks = taskGroups[repo];
      console.log(`🚀 Starting repository group: ${repo} (${repoTasks.length} tasks)`);

      const groupResults = [];

      // Execute tasks sequentially within the same repository
      for (const taskFile of repoTasks) {
        const taskName = path.basename(taskFile, '.md');
        const logFile = path.join(logDir, `${taskName}.log`);

        const result = await runTask(taskFile, logFile, true);
        groupResults.push(result);

        if (result.success) {
          successful++;
        } else {
          failed++;
        }
      }

      console.log(`✅ Repository group completed: ${repo}`);
      return groupResults;
    });
  });

  // Wait for all groups to complete
  console.log('⏳ Waiting for all repository groups to complete...');
  const groupResults = await Promise.all(groupPromises);

  // Flatten results
  for (const results of groupResults) {
    allResults.push(...results);
  }

  console.log('🎉 All repository groups completed');

  // Print results summary
  console.log('');
  console.log('📊 PARALLEL EXECUTION RESULTS');
  console.log('════════════════════════════════════════');

  for (const result of allResults) {
    if (result.success) {
      console.log(`✅ ${result.taskName} (${result.formattedDuration}) - 📄 Log: ${result.logFile}`);
    } else {
      console.log(`❌ ${result.taskName} (${result.formattedDuration}) - 📄 Log: ${result.logFile || 'N/A'}`);
      if (result.error) {
        console.log(`   Error: ${result.error}`);
      }
    }
  }

  console.log('');
  console.log(`📊 Result summary: ${successful} successful, ${failed} failed (total processed: ${allResults.length})`);
  console.log('🎉 All parallel tasks completed!');

  return { successful, failed, results: allResults };
}

/**
 * Execute all tasks
 * @param {string} outputDir - Output directory containing task files
 * @param {string} logDir - Log directory path
 * @param {Object} config - Configuration object
 * @returns {Object} Execution results {successful, failed, totalTasks}
 */
export async function executeTasks(outputDir, logDir, config) {
  // Check if tasks directory exists
  if (!(await fs.pathExists(outputDir))) {
    throw new Error(`${outputDir} directory not found. Please ensure task generation was successful`);
  }

  // Create logs directory if saving logs
  if (config.saveLogs || config.parallel) {
    console.log('🧹 Cleaning up existing logs directory...');
    await fs.remove(logDir);
    await fs.ensureDir(logDir);
  }

  // Get all task files
  const taskFiles = (await fs.readdir(outputDir))
    .filter(file => file.endsWith('.md'))
    .map(file => path.join(outputDir, file))
    .sort();

  if (taskFiles.length === 0) {
    throw new Error(`No task files found in ${outputDir}. Please ensure task generation was successful`);
  }

  console.log(`📁 Found ${taskFiles.length} task files to process`);

  const executionStartTimestamp = formatTimestamp();
  const executionStartTime = Date.now();

  console.log('🚀 Starting task execution...');
  console.log(`🕰️  Execution started at: ${executionStartTimestamp}`);

  if (config.saveLogs || config.parallel) {
    console.log(`📁 Logs will be saved to: ${logDir}/`);
  } else {
    console.log('🖥️  Output will be printed directly (no logs saved)');
  }

  // Execute tasks
  let result;
  if (config.parallel) {
    result = await executeParallel(taskFiles, logDir, config.maxJobs);
  } else {
    result = await executeSequential(taskFiles, logDir, config.saveLogs);
  }

  const executionEndTimestamp = formatTimestamp();
  const executionEndTime = Date.now();
  const totalDuration = calculateDuration(executionStartTime, executionEndTime);
  const formattedTotalDuration = formatDuration(totalDuration);

  return {
    successful: result.successful,
    failed: result.failed,
    totalTasks: taskFiles.length,
    startTimestamp: executionStartTimestamp,
    endTimestamp: executionEndTimestamp,
    duration: formattedTotalDuration,
    logDir: config.saveLogs || config.parallel ? logDir : null,
  };
}
