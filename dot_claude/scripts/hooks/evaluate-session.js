#!/usr/bin/env node
/**
 * Continuous Learning - Session Evaluator
 *
 * Runs on SessionEnd hook to extract reusable patterns from Claude Code sessions.
 *
 * Hook type: SessionEnd (runs after session-end.js)
 * When: Session termination (after state persistence)
 * Never blocks: Always exits 0
 *
 * Why SessionEnd instead of UserPromptSubmit:
 * - SessionEnd runs once at session end (lightweight)
 * - UserPromptSubmit runs every message (heavy, adds latency)
 */

const path = require('path');
const fs = require('fs');
const {
  getHomeDir,
  getLearnedSkillsDir,
  ensureDir,
  readFile,
  countInFile,
  log
} = require('../lib/utils');

async function main() {
  // Config path: ~/.claude/skills/continuous-learning-v2/config.json (hardcoded)
  const configFile = path.join(getHomeDir(), '.claude', 'skills', 'continuous-learning-v2', 'config.json');

  // Default configuration
  let minSessionLength = 10;
  let learnedSkillsPath = getLearnedSkillsDir();

  // Load config if exists
  const configContent = readFile(configFile);
  if (configContent) {
    try {
      const config = JSON.parse(configContent);
      minSessionLength = config.min_session_length || 10;

      if (config.learned_skills_path) {
        // Handle ~ in path
        learnedSkillsPath = config.learned_skills_path.replace(/^~/, getHomeDir());
      }
    } catch {
      // Invalid config, use defaults
    }
  }

  // Ensure learned skills directory exists
  ensureDir(learnedSkillsPath);

  // Get transcript path from environment (set by Claude Code)
  const transcriptPath = process.env.CLAUDE_TRANSCRIPT_PATH;

  if (!transcriptPath || !fs.existsSync(transcriptPath)) {
    process.exit(0);
  }

  // Count user messages in session
  const messageCount = countInFile(transcriptPath, /"type":"user"/g);

  // Skip short sessions
  if (messageCount < minSessionLength) {
    log(`[ContinuousLearning] Session too short (${messageCount} messages), skipping`);
    process.exit(0);
  }

  // Signal to Claude that session should be evaluated for extractable patterns
  log(`[ContinuousLearning] Session has ${messageCount} messages - evaluate for extractable patterns`);
  log(`[ContinuousLearning] Save learned skills to: ${learnedSkillsPath}`);

  process.exit(0);
}

main().catch(err => {
  console.error('[ContinuousLearning] Error:', err.message);
  process.exit(0);
});
