---
name: github-issue
description: >
  Manage GitHub issues: create from templates,
  search, update metadata, set project fields,
  triage, and plan roadmaps. Use when the user
  wants to create, list, organize, prioritize,
  or assign GitHub issues.
  Activate on: create issue, list issues, triage,
  prioritize issues, roadmap, assign issue.
  SKIP: if the user wants to manage pull requests
  or GitHub Actions workflows.
license: Apache-2.0
compatibility: >
  Requires gh (GitHub CLI) authenticated.
  Requires yq for template parsing.
  Requires jq for JSON output and GraphQL.
allowed-tools: Bash
metadata:
  author: mrbrandao
  version: "1.0"
---

# github-issue

## Trigger

Activate when user wants to create, list, update,
prioritize, triage, or plan issues on GitHub.

## Flow

### Step 1 -- Detect context

Determine: repo (from cwd or user input), operation
(create, list, update, fields, triage, roadmap).

### Step 2 -- Route to script

Always pass `--json` when calling scripts.

| Intent             | Script            |
|--------------------|-------------------|
| Discover templates | scripts/tpl.sh    |
| Create issue       | scripts/new.sh    |
| List/search        | scripts/ls.sh     |
| Update metadata    | scripts/edit.sh   |
| Set project fields | scripts/fields.sh |
| Triage issues      | scripts/triage.sh |
| Plan roadmap       | scripts/roadmap.sh|

Run `scripts/<name>.sh --help` to see all flags.

### Step 3 -- LLM responsibilities

The LLM handles ONLY:
- Interpreting user intent into operation + flags
- Composing issue body text for create/update
- Analyzing triage/roadmap output for
  recommendations and gap detection
- Asking user for missing required fields

### Step 4 -- Template resolution

When creating: run `tpl.sh --json` first.

1. If context is unclear, ask: "Which repo? Or a
   quick issue from a standard template?"
2. If repo is known and cloned, tpl.sh reads local
   .github/ISSUE_TEMPLATE/ automatically.
3. If not cloned, tpl.sh fetches via GitHub API.
4. If nothing found, tpl.sh offers built-in
   templates from assets/templates/.
5. Present template choices to user.

### Step 5 -- Field suggestion rules

Scripts are permissive. The LLM adapts to context.

1. Always create if user gives a title. Never
   block on missing optional fields.
2. Suggest fields when context is available --
   after creating or inline, never as a gate.
3. During triage/roadmap, treat assignee,
   priority, labels, type as expected. Flag
   missing ones as gaps.
4. If working in a known project, include
   --project automatically without asking.
5. Never ask more than one clarifying question
   before creating. Create first, refine after.

### Step 6 -- Triage workflow

1. Run triage.sh to gather issues
2. Analyze: identify missing priorities,
   unassigned issues, stale items
3. Propose recommendations to user
4. On approval, execute via edit.sh and fields.sh

### Step 7 -- Roadmap workflow

1. Run roadmap.sh to aggregate issues
2. Analyze: identify gaps in milestones,
   unbalanced iterations, features not yet
   tracked
3. Propose actions: create missing issues, set
   priorities, assign milestones
4. On approval, execute via new.sh, edit.sh,
   fields.sh

## Issue Body Guidelines

When composing issue text:

- Write like explaining to a colleague
- Lead with what and why in 1-2 sentences
- No emojis, no hedge language
- Skip sections with nothing to add
- Use real examples, not hypotheticals
- Short paragraphs, 2-4 sentences max
- 80 char line width
- Backticks for code and file paths
- Bug: 10-20 lines, Feature: 10-25, Task: 5-15
- Over 30 lines likely means multiple issues

## Cost Optimization

This skill performs mostly mechanical routing.
A smaller, faster model is sufficient for all
operations except triage and roadmap, which
benefit from stronger reasoning.

## Gotchas

- Always confirm repo with user before mutating
- For bulk triage, present plan before executing
- Project fields require --project number flag
- fields.sh uses GraphQL and needs jq installed
- Template discovery needs yq installed
