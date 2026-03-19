#!/usr/bin/env node

import '@dotenvx/dotenvx/config';
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { generateText } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

const CHANGELOG_PATH = 'CHANGELOG.md';
const REPO_URL = 'https://github.com/peschee/claude-statusline';
const DIFF_CHAR_LIMIT = 8000;

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const positionalArgs = args.filter((a) => !a.startsWith('--'));

// Phase 1: Determine versions
const newVersion = positionalArgs[0] || git('describe --tags --abbrev=0').trim();
const prevVersion = git(`describe --tags --abbrev=0 ${newVersion}^`).trim();
const date = new Date().toISOString().split('T')[0];

console.log(`Generating changelog for ${prevVersion}..${newVersion} (${date})`);

// Phase 2: Gather git context
const commitLog = git(`log --oneline ${prevVersion}..${newVersion}`);
const diffStat = git(`diff --stat ${prevVersion}..${newVersion}`);
const fullDiff = git(`diff ${prevVersion}..${newVersion}`).slice(0, DIFF_CHAR_LIMIT);

const changelog = readFileSync(CHANGELOG_PATH, 'utf-8');
const unreleasedContent = extractUnreleasedContent(changelog);

// Phase 3: Generate changelog entry via AI SDK
const systemPrompt = `You are a changelog writer. Generate changelog entries following the Keep a Changelog format (https://keepachangelog.com/en/1.1.0/).

Rules:
- Use ONLY these category headers as needed: ### Added, ### Changed, ### Deprecated, ### Removed, ### Fixed, ### Security
- Each entry is a bullet point starting with "- "
- Be concise but descriptive — focus on what changed from a user's perspective
- Do NOT wrap output in code fences
- Do NOT include the version header (## [x.y.z] - date) — only output the category subsections
- Use backticks for code references (file names, function names, env vars, etc.)
- If existing unreleased items are provided, incorporate them (they take priority as human-curated)
- Deduplicate entries that describe the same change`;

const userMessage = `Generate a changelog entry for version ${newVersion} (${date}).

Previous version: ${prevVersion}

Commit log:
${commitLog}

Diff stat:
${diffStat}

Diff (truncated):
${fullDiff}

${unreleasedContent ? `Existing [Unreleased] items (human-curated, take priority):\n${unreleasedContent}` : 'No existing unreleased items.'}`;

const { text: entry } = await generateText({
  model: anthropic('claude-sonnet-4-20250514'),
  system: systemPrompt,
  prompt: userMessage,
});

console.log('\nGenerated entry:\n');
console.log(entry);

// Phase 4: Update CHANGELOG.md
if (dryRun) {
  console.log('\n(dry run — CHANGELOG.md not modified)');
} else {
  const versionNum = newVersion.replace(/^v/, '');
  const updatedChangelog = updateChangelog(changelog, versionNum, date, entry);
  writeFileSync(CHANGELOG_PATH, updatedChangelog);
  console.log(`\nUpdated ${CHANGELOG_PATH}`);
}

// --- Helper functions ---

// Note: execSync is used here with git subcommands and version tags only,
// not with untrusted user input. Tags come from git describe or CLI args
// controlled by the caller (developer or CI).
function git(cmd) {
  return execSync(`git ${cmd}`, { encoding: 'utf-8' });
}

function extractUnreleasedContent(content) {
  const match = content.match(/^## \[Unreleased\]\s*\n([\s\S]*?)(?=\n## \[)/m);
  return match ? match[1].trim() : '';
}

function updateChangelog(content, version, date, entry) {
  const newVersionSection = `## [${version}] - ${date}\n\n${entry.trim()}`;

  const updated = content.replace(
    /^(## \[Unreleased\])\s*\n[\s\S]*?(?=\n## \[)/m,
    `$1\n\n${newVersionSection}\n\n`,
  );

  return updateReferenceLinks(updated, version);
}

function updateReferenceLinks(content, version) {
  const updatedUnreleased = content.replace(
    /^\[Unreleased\]:.*$/m,
    `[Unreleased]: ${REPO_URL}/compare/v${version}...HEAD`,
  );

  const prevVersionMatch = updatedUnreleased.match(
    /^\[Unreleased\]:.*\n(\[[\d.]+\]:.*)/m,
  );

  if (prevVersionMatch) {
    const prevLink = prevVersionMatch[1];
    const prevVer = prevLink.match(/^\[([\d.]+)\]/)[1];
    const newLink = `[${version}]: ${REPO_URL}/compare/v${prevVer}...v${version}`;

    return updatedUnreleased.replace(
      prevLink,
      `${newLink}\n${prevLink}`,
    );
  }

  return updatedUnreleased;
}
