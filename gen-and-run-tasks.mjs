#!/usr/bin/env zx

import 'zx/globals';
import { loadConfig, validateConfig, resolveFilePaths } from './lib/config.mjs';
import { printHeader, printUsage, parseArguments } from './lib/utils.mjs';
import { generateTasks } from './lib/taskgen.mjs';
import { executeTasks } from './lib/executor.mjs';

// Disable default command output
$.verbose = false;

/**
 * Main function
 */
async function main() {
  try {
    // Parse command line arguments
    const cliOptions = parseArguments(argv);

    // Show help if requested
    if (cliOptions.help) {
      printUsage();
      process.exit(0);
    }

    // Load configuration
    const config = await loadConfig(cliOptions, cliOptions.bundle);

    // Validate configuration
    validateConfig(config);

    // Apply special rules for parallel mode
    if (config.parallel) {
      config.saveLogs = true;
      console.log('🚀 Parallel mode enabled: automatically enabling log saving');
    }

    // Resolve file paths
    const paths = await resolveFilePaths(cliOptions.bundle, config.guideFile);

    // Display configuration info
    if (cliOptions.bundle) {
      console.log(`📦 Using bundle: ${cliOptions.bundle}`);
      if (paths.bundleGuide) {
        console.log(`📋 Using bundle-specific guide: ${paths.guideFile}`);
      }
    }

    // GENERATION SECTION
    if (!config.runOnly) {
      printHeader('📝 TASK GENERATION');

      const generatedCount = await generateTasks(paths, config);

      console.log('');
      console.log(`🎉 Successfully generated ${generatedCount} tasks in ${paths.outputDir} directory`);
      console.log('═══════════════════════════════════════════════════════════════════════════════════');
      console.log('');
    }

    // EXECUTION SECTION
    if (!config.generateOnly) {
      printHeader('⚡ TASK EXECUTION');

      const executionResult = await executeTasks(paths.outputDir, paths.logDir, config);

      // Print summary
      console.log('');
      printHeader('📦 EXECUTION SUMMARY');
      console.log(`🕰️  Started at:    ${executionResult.startTimestamp}`);
      console.log(`🏁 Finished at:   ${executionResult.endTimestamp}`);
      console.log(`⏱️  Total duration: ${executionResult.duration}`);
      console.log(`✅ Successful:    ${executionResult.successful}`);
      console.log(`❌ Failed:        ${executionResult.failed}`);
      console.log(`📁 Total tasks:   ${executionResult.totalTasks}`);
      console.log('═══════════════════════════════════════════════════════════════════════════════════');

      if (executionResult.failed > 0) {
        console.log('');
        if (executionResult.logDir) {
          console.log(`⚠️  Some tasks failed. Check logs in ${executionResult.logDir}/ for details.`);
        } else {
          console.log('⚠️  Some tasks failed. See output above for details.');
        }
        console.log('❌ Execution completed with failures.');
        process.exit(1);
      } else {
        console.log('');
        console.log('🎉 All tasks completed successfully!');
        console.log('✅ Execution completed successfully.');
        process.exit(0);
      }
    }
  } catch (error) {
    console.error('');
    console.error(chalk.red('❌ ERROR:'), error.message);
    console.error('');

    if (error.stack && process.env.DEBUG) {
      console.error(chalk.gray('Stack trace:'));
      console.error(chalk.gray(error.stack));
    }

    process.exit(1);
  }
}

// Run main function
main();
