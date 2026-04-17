---
name: gitlab-release
description: >-
  Generate release notes for a GitLab project tag.
  Use when the user wants to create release notes, changelogs, or version
  announcements for a GitLab repository tag.
license: GPL-3.0-or-later
compatibility: Requires git and glab CLI.
metadata:
  author: Igor Brandao <mrbrandao@proton.me>
  version: "1.1"
permissions:
  allow:
    - "Bash(git tag --sort=-creatordate:*)"
    - "Bash(git remote get-url:*)"
    - "Bash(git log:*)"
    - "Bash(glab api user:*)"
    - "Bash(glab api projects/:id/repository/commits:*)"
---

# gitlab-release

Generate formatted release notes for GitLab tags, mimicking GitHub's release
notes style. Outputs in Slack or Markdown format.

## Instructions

### Step 1 - Parse Arguments

Parse `$ARGUMENTS` for `<tag> [slack|markdown]`.

- If a tag is provided, use it as the target tag.
- If no tag is provided, run `git tag --sort=-creatordate | head -5` to show
  the 5 most recent tags and ask the user which tag to use.
- The format defaults to `slack` if not specified.

### Step 2 - Gather Release Data

Use 2 subagents in parallel via the Agent tool (both `general-purpose` type):

**Subagent A — Project metadata:**
- Find the previous tag: `git tag --sort=-creatordate | grep -A1 "^<tag>$" | tail -1`
- Detect remote URL: `git remote get-url upstream 2>/dev/null || git remote get-url origin`
- Extract GitLab host and repository path from the remote URL.
- Get project name from the repo path (last segment).
- Get the short commit hash: `git log -1 --format='%h' <tag>`
- Get the current GitLab username: `glab api user | python3 -c "import json,sys; print(json.load(sys.stdin)['username'])"`

Return: `previous_tag`, `gitlab_host`, `repo_path`, `project_name`, `commit_hash`, `gitlab_user`

**Subagent B — Commits and authors:**
- Get commits between previous tag and target tag, skipping merge commits:
  `git log <previous_tag>..<tag> --no-merges --pretty=format:"%H %s"`
- Run all MR lookups in parallel using a bash loop with `&` and `wait`:
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
- Each line of output is `<sha> <iid> <username>`. If a line contains `NOMR`,
  fall back to the git commit author:
  `git log -1 --format='%an' <sha>` and use the lowercase first name.

Return: a list of `{ message, author_username, mr_number }` for each commit.

### Step 3 - Format and Display

Using the results from both subagents, format the release notes and display
them immediately inside a code block.

**Slack format** (default):
```
New Release: <project_name> <tag>

  @<gitlab_user> released this today

  https://<gitlab_host>/<repo_path>/-/tags/<tag>
  https://<gitlab_host>/<repo_path>/-/commit/<commit_hash>

  What's Changed

  • <commit_message> by @<author> in !<mr_number>
  • <commit_message> by @<author>

  Full Changelog: https://<gitlab_host>/<repo_path>/-/compare/<previous_tag>...<tag>
```

**Markdown format:**
```markdown
# New Release: <project_name> <tag>

> @<gitlab_user> released this today

- [Tag <tag>](https://<gitlab_host>/<repo_path>/-/tags/<tag>)
- [Commit <commit_hash>](https://<gitlab_host>/<repo_path>/-/commit/<commit_hash>)

## What's Changed

- <commit_message> by @<author> in [!<mr_number>](https://<gitlab_host>/<repo_path>/-/merge_requests/<mr_number>)
- <commit_message> by @<author>

**Full Changelog:** [<previous_tag>...<tag>](https://<gitlab_host>/<repo_path>/-/compare/<previous_tag>...<tag>)
```

Notes:
- Use `glab api user` for `<gitlab_user>` (the authenticated GitLab username).
- Omit the `in !<mr_number>` portion when no MR was found for a commit.

### Step 4 - User Review

After displaying the release notes, ask the user:

> "Does this look good? Let me know if you'd like to change the project name,
> wording, or anything else."

If the user requests changes, apply them and re-display the updated notes.
