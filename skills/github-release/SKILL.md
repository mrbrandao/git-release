---
name: github-release
description: >-
  Create a GitHub release: detect or suggest a semver
  tag, generate a signed annotated tag with changelog,
  push, and create a release with auto-generated notes.
  Activate on: /github-release, create a release,
  tag and release, publish release. SKIP: if user
  wants GitLab releases (use gitlab-release instead).
license: Apache-2.0
compatibility: >-
  Requires git and gh (GitHub CLI) authenticated
  via gh auth login.
allowed-tools: Bash
metadata:
  author: mrbrandao
  version: "1.0"
---

# github-release

Create signed semver tags and GitHub releases with
auto-generated release notes.

## Instructions

### Step 1 -- Determine Tag

- If the user provides a tag, use it directly.
- If not:
  a. Find the latest tag:
     `git tag --sort=-creatordate | head -1`
  b. Detect prefix pattern from existing tags: if
     the latest tag starts with `v`, use `v` prefix;
     otherwise use bare semver.
  c. List commits since last tag:
     `git log <latest_tag>..HEAD --oneline`
  d. If no commits exist since the last tag, inform
     the user and stop.
  e. Suggest a version bump based on commit prefixes:
     - Any `BREAKING CHANGE` or `!:` in subject
       or body → major bump
     - Any `feat:` → minor bump
     - Only `fix:`, `docs:`, `chore:`, etc. → patch
  f. Present the suggested tag for approval. If the
     user changes it, use their version.

### Step 2 -- Generate Tag Message

Using `git log <previous_tag>..HEAD --no-merges
--pretty=format:"%s"`, build the tag annotation:

- First line: the tag version (e.g., `v0.7.0`)
- Body: one line per commit, formatted as:
  ` - <commit subject>`
- Max 30 lines total. If more commits exist,
  group minor items or summarize.
- Wrap lines at 72 chars (tpope body rule).
- Present the full message for user approval.
  If the user edits the message or title, use
  their version going forward.

### Step 3 -- Create Signed Tag

On user approval:
```
git tag -s -m "<approved message>" <tag>
```

If GPG signing fails, fall back to annotated tag:
```
git tag -a -m "<approved message>" <tag>
```

### Step 4 -- Push Tag

Present `git push origin <tag>` for confirmation.
On approval, execute the push.

### Step 5 -- Create GitHub Release

On user confirmation:
```
gh release create <tag> \
  --title "<title>" \
  --generate-notes
```

The `--generate-notes` flag is mandatory. Never
write release notes manually -- always let GitHub
generate them from commit and PR history.

Use the tag version as the title (e.g., `v0.7.0`)
unless the user changed the title during review.

Display the release URL when complete.

## Gotchas

- Never create a tag, push, or release without
  explicit user approval at each step.
- Respect the existing tag prefix convention. If
  previous tags use `v`, new tags must use `v`.
  Never mix prefixed and bare tags.
- `--generate-notes` is mandatory for GitHub
  releases. Do not manually compose release notes.
- Tag messages must not exceed 30 lines.
- If the repo has no previous tags, ask the user
  for the initial version. Do not guess.
- Verify `gh auth status` before Step 5. If not
  authenticated, inform the user and stop.
