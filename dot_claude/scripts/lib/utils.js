/**
 * Cross-platform utility functions for Claude Code hooks and scripts
 * Linux-only deployment for WSL2 Ubuntu
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// Platform detection (Linux-only deployment)
const isLinux = true;

/**
 * Get the user's home directory
 */
function getHomeDir() {
  return os.homedir();
}

/**
 * Get the Claude config directory
 * Hardcoded to ~/.claude/ per user decision
 */
function getClaudeDir() {
  return path.join(getHomeDir(), '.claude');
}

/**
 * Get the sessions directory
 */
function getSessionsDir() {
  return path.join(getClaudeDir(), 'sessions');
}

/**
 * Get the insights directory (renamed from homunculus)
 */
function getInsightsDir() {
  return path.join(getClaudeDir(), 'insights');
}

/**
 * Get the learned skills directory
 */
function getLearnedSkillsDir() {
  return path.join(getInsightsDir(), 'instincts', 'personal');
}

/**
 * Ensure a directory exists (create if not)
 */
function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
  return dirPath;
}

/**
 * Get current date in YYYY-MM-DD format
 */
function getDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Get current time in HH:MM format
 */
function getTimeString() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}

/**
 * Get current datetime in YYYY-MM-DD HH:MM:SS format
 */
function getDateTimeString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

/**
 * Get short session ID from CLAUDE_SESSION_ID environment variable
 * Returns last 8 characters, falls back to project name then fallback value
 */
function getSessionIdShort(fallback = 'default') {
  const sessionId = process.env.CLAUDE_SESSION_ID;
  if (sessionId && sessionId.length > 0) {
    return sessionId.slice(-8);
  }
  return getProjectName() || fallback;
}

/**
 * Get the git repository name
 */
function getGitRepoName() {
  const result = runCommand('git rev-parse --show-toplevel');
  if (!result.success) return null;
  return path.basename(result.output);
}

/**
 * Get project name from git repo or current directory
 */
function getProjectName() {
  const repoName = getGitRepoName();
  if (repoName) return repoName;
  return path.basename(process.cwd()) || null;
}

/**
 * Find files matching a pattern in a directory
 * @param {string} dir - Directory to search
 * @param {string} pattern - File pattern (e.g., "*.tmp", "*.md")
 * @param {object} options - Options { maxAge: days, recursive: boolean }
 */
function findFiles(dir, pattern, options = {}) {
  const { maxAge = null, recursive = false } = options;
  const results = [];

  if (!fs.existsSync(dir)) {
    return results;
  }

  const regexPattern = pattern
    .replace(/\./g, '\\.')
    .replace(/\*/g, '.*')
    .replace(/\?/g, '.');
  const regex = new RegExp(`^${regexPattern}$`);

  function searchDir(currentDir) {
    try {
      const entries = fs.readdirSync(currentDir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);

        if (entry.isFile() && regex.test(entry.name)) {
          if (maxAge !== null) {
            const stats = fs.statSync(fullPath);
            const ageInDays = (Date.now() - stats.mtimeMs) / (1000 * 60 * 60 * 24);
            if (ageInDays <= maxAge) {
              results.push({ path: fullPath, mtime: stats.mtimeMs });
            }
          } else {
            const stats = fs.statSync(fullPath);
            results.push({ path: fullPath, mtime: stats.mtimeMs });
          }
        } else if (entry.isDirectory() && recursive) {
          searchDir(fullPath);
        }
      }
    } catch (_err) {
      // Ignore permission errors
    }
  }

  searchDir(dir);

  // Sort by modification time (newest first)
  results.sort((a, b) => b.mtime - a.mtime);

  return results;
}

/**
 * Read a text file safely
 */
function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

/**
 * Write a text file
 */
function writeFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, 'utf8');
}

/**
 * Append to a text file
 */
function appendFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.appendFileSync(filePath, content, 'utf8');
}

/**
 * Replace text in a file (cross-platform sed alternative)
 */
function replaceInFile(filePath, search, replace) {
  const content = readFile(filePath);
  if (content === null) return false;

  const newContent = content.replace(search, replace);
  writeFile(filePath, newContent);
  return true;
}

/**
 * Count occurrences of a pattern in a file
 */
function countInFile(filePath, pattern) {
  const content = readFile(filePath);
  if (content === null) return 0;

  const regex = pattern instanceof RegExp ? pattern : new RegExp(pattern, 'g');
  const matches = content.match(regex);
  return matches ? matches.length : 0;
}

/**
 * Read JSON from stdin (for hook input)
 */
async function readStdinJson() {
  return new Promise((resolve, reject) => {
    let data = '';

    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => {
      data += chunk;
    });

    process.stdin.on('end', () => {
      try {
        if (data.trim()) {
          resolve(JSON.parse(data));
        } else {
          resolve({});
        }
      } catch (err) {
        reject(err);
      }
    });

    process.stdin.on('error', reject);
  });
}

/**
 * Log to stderr (visible to user in Claude Code)
 */
function log(message) {
  console.error(message);
}

/**
 * Output to stdout (returned to Claude)
 */
function output(data) {
  if (typeof data === 'object') {
    console.log(JSON.stringify(data));
  } else {
    console.log(data);
  }
}

/**
 * Run a command and return output
 *
 * SECURITY NOTE: This function executes shell commands. Only use with
 * trusted, hardcoded commands. Never pass user-controlled input directly.
 *
 * @param {string} cmd - Command to execute (should be trusted/hardcoded)
 * @param {object} options - execSync options
 */
function runCommand(cmd, options = {}) {
  try {
    const result = execSync(cmd, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      ...options
    });
    return { success: true, output: result.trim() };
  } catch (err) {
    return { success: false, output: err.stderr || err.message };
  }
}

/**
 * Check if current directory is a git repository
 */
function isGitRepo() {
  return runCommand('git rev-parse --git-dir').success;
}

module.exports = {
  // Platform info
  isLinux,

  // Directories
  getHomeDir,
  getClaudeDir,
  getSessionsDir,
  getInsightsDir,
  getLearnedSkillsDir,
  ensureDir,

  // Date/Time
  getDateString,
  getTimeString,
  getDateTimeString,

  // Session/Project
  getSessionIdShort,
  getGitRepoName,
  getProjectName,

  // File operations
  findFiles,
  readFile,
  writeFile,
  appendFile,
  replaceInFile,
  countInFile,

  // Hook I/O
  readStdinJson,
  log,
  output,

  // System
  runCommand,
  isGitRepo
};
