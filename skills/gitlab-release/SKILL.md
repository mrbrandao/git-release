---
name: gitlab-release
description: >-
  Create GitLab releases: detect the next semver tag, build a signed
  annotated tag, push it, then generate formatted release notes with
  MR numbers and authors in Slack or Markdown format.
  Activate on: /gitlab-release, create a release, tag and release,
  generate release notes. SKIP: if user wants GitHub releases.
license: Apache-2.0
compatibility: Requires git and glab CLI authenticated via glab auth login.
metadata:
  author: Igor Brandao <mrbrandao@proton.me>
  version: "2.0.0"
  kind: skill
permissions:
  allow:
    - "Bash(git tag:*)"
    - "Bash(git push:*)"
    - "Bash(git log:*)"
    - "Bash(git remote get-url:*)"
    - "Bash(glab api user:*)"
    - "Bash(glab api projects/:id/repository/commits:*)"
---

# gitlab-release

Create GitLab releases and generate formatted release notes.

## Instructions

### Step 1 — Parse Arguments

Parse `$ARGUMENTS` for `<tag> [slack|markdown]`. Format defaults to `slack`.

- Tag provided → skip to Step 5 (notes only)
- No tag → continue to Step 2

### Step 2 — Detect & Suggest Tag

```bash
git tag --sort=-creatordate | head -1          # latest tag
git log <latest>..HEAD --no-merges --oneline   # commits since
```

If no commits since latest tag → inform user and stop.

Suggest semver bump from conventional commit prefixes:
- `BREAKING CHANGE` or `!:` anywhere → **major**
- Any `feat:` → **minor**
- Only `fix:`, `docs:`, `chore:`, etc. → **patch**

Respect existing prefix convention (`v` or bare). Present suggestion, ask
approval. Use user's version if changed.

### Step 3 — Build Tag Annotation

```bash
git log <previous_tag>..<tag> --no-merges --pretty=format:"%s"
```

Strip conventional prefix from each subject:
```
regex: ^(feat|fix|docs|chore|refactor|test|ci|perf|build|revert)(\(.+\))?!?:\s*
```
Capitalise first letter. Format:
```
<tag>

- <cleaned bullet>
- <cleaned bullet>
```
Max 30 lines, wrap at 72 chars. Present for approval — user may edit.
**Keep these bullets in memory for Step 5.**

### Step 4 — Create & Push Tag

On approval:
```bash
git tag -s -m "<message>" <tag>
# GPG fallback:
git tag -a -m "<message>" <tag>
```

Detect remote:
```bash
git remote get-url upstream 2>/dev/null || git remote get-url origin
```

Present push command for confirmation, then execute:
```bash
git push <remote> <tag>
```

### Step 5 — Gather Release Data

Launch 2 subagents in parallel:

**Subagent A — Project metadata:**
```bash
git tag --sort=-creatordate | grep -A1 "^<tag>$" | tail -1    # previous_tag
git remote get-url upstream 2>/dev/null || git remote get-url origin
git log -1 --format='%h' <tag>                                  # commit_hash
glab api user | python3 -c "import json,sys; print(json.load(sys.stdin)['username'])"
```

*Notes-only path only:* also fetch and strip commit subjects:
```bash
git log <previous_tag>..<tag> --no-merges --pretty=format:"%s"
```
Apply same prefix-stripping regex as Step 3 and capitalise.

Return: `previous_tag`, `gitlab_host`, `repo_path`, `project_name`,
`commit_hash`, `gitlab_user`, and `display_bullets` (notes-only path only).

**Subagent B — MR attribution:**
```bash
git log <previous_tag>..<tag> --no-merges --pretty=format:"%H"
```
For each SHA, in parallel:
```bash
for sha in <sha1> <sha2> ...; do
  (glab api "projects/:id/repository/commits/$sha/merge_requests" 2>/dev/null \
    | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('$sha', d[0]['iid'], d[0]['author']['username']) if d else print('$sha NOMR')
") &
done
wait
```
`NOMR` fallback: `git log -1 --format='%an' <sha>` — use lowercase first name.

Return: ordered list of `{ iid, author_username }` per commit.

**Display text:**
- Full flow → bullets from Step 3 memory, matched to attribution by index
- Notes only → `display_bullets` from Subagent A, matched by index

### Step 6 — Format & Display

Display inside a code block.

**Slack** (default):
```
New Release: <project_name> <tag>

  @<gitlab_user> released this today

  https://<gitlab_host>/<repo_path>/-/tags/<tag>
  https://<gitlab_host>/<repo_path>/-/commit/<commit_hash>

  What's Changed

  • <bullet> by @<author> in !<iid>
  • <bullet> by @<author>

  Full Changelog: https://<gitlab_host>/<repo_path>/-/compare/<previous_tag>...<tag>
```

**Markdown:**
```markdown
# New Release: <project_name> <tag>

> @<gitlab_user> released this today

- [Tag <tag>](https://<gitlab_host>/<repo_path>/-/tags/<tag>)
- [Commit <commit_hash>](https://<gitlab_host>/<repo_path>/-/commit/<commit_hash>)

## What's Changed

- <bullet> by @<author> in [!<iid>](https://<gitlab_host>/<repo_path>/-/merge_requests/<iid>)
- <bullet> by @<author>

**Full Changelog:** [<previous_tag>...<tag>](https://<gitlab_host>/<repo_path>/-/compare/<previous_tag>...<tag>)
```

Omit `in !<iid>` when no MR found. Omit attribution for unmatched bullets.

### Step 7 — User Review

Ask:
> "Does this look good? Let me know if you'd like to change anything."

Apply changes and re-display if requested.

## Gotchas

- Never create a tag, push, or release without explicit user approval.
- Respect the existing tag prefix convention — never mix `v1.0.0` and `1.0.0`.
- If no commits since last tag, stop — do not create an empty release.
- Tag messages must not exceed 30 lines.
- `glab auth login` must be authenticated before running.
