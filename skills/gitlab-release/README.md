# gitlab-release

AI agent skill for creating GitLab releases and generating formatted
release notes in Slack or Markdown.

## What it does

- Detects the last tag and suggests the next semver version
- Builds a signed annotated tag from your commits
- Pushes the tag to GitLab
- Generates formatted release notes with MR numbers and authors
- Outputs in Slack or Markdown format

## Requirements

- `git`
- [`glab`](https://gitlab.com/gitlab-org/cli) — authenticated via `glab auth login`

## Usage

### Full flow — create tag + release notes

Invoke with no arguments. The skill detects the last tag, suggests
the next semver version, builds the annotation, creates the signed
tag, pushes it, and generates formatted release notes:

    /gitlab-release

### Notes only — existing tag

If the tag already exists and you only want the release notes:

    /gitlab-release v1.2.0
    /gitlab-release v1.2.0 markdown

## Output formats

| Format     | Description                                           |
|------------|-------------------------------------------------------|
| `slack`    | Plain text with `@mentions` and `!MR` links (default) |
| `markdown` | Markdown with hyperlinks                              |

## Flow

```
1. Detect last tag → suggest semver bump → ask approval
2. Build tag annotation from commits (conventional prefix stripped)
3. Create signed tag + push → ask approval at each step
4. Gather MR numbers and authors in parallel (glab)
5. Format and display release notes
6. Ask user to review and apply any changes
```

Steps 1–3 are skipped when an existing tag is provided.

## Semver detection

Commit prefixes determine the version bump:

| Prefix in any commit       | Bump  |
|----------------------------|-------|
| `BREAKING CHANGE`, `!:`    | major |
| `feat:`                    | minor |
| `fix:`, `docs:`, `chore:`… | patch |

The skill respects your existing tag prefix convention (`v1.0.0` vs `1.0.0`).

## Conventional prefix stripping

Commit subjects are cleaned before use in the tag annotation and
release notes. The prefix and optional scope are removed:

```
feat(mcp): Add meet-notes sync tools  →  Add meet-notes sync tools
fix: Correct jira.context tool names  →  Correct jira.context tool names
```

## Example output (Slack)

```
New Release: myproject v1.2.0

  @alice released this today

  https://gitlab.example.com/org/myproject/-/tags/v1.2.0
  https://gitlab.example.com/org/myproject/-/commit/abc1234

  What's Changed

  • Add configurable backup strategy by @bob in !42
  • Correct jira.context tool names by @carol in !41
  • Add comprehensive test suite by @bob in !40

  Full Changelog: https://gitlab.example.com/org/myproject/-/compare/v1.1.0...v1.2.0
```

## Example output (Markdown)

```markdown
# New Release: myproject v1.2.0

> @alice released this today

- [Tag v1.2.0](https://gitlab.example.com/org/myproject/-/tags/v1.2.0)
- [Commit abc1234](https://gitlab.example.com/org/myproject/-/commit/abc1234)

## What's Changed

- Add configurable backup strategy by @bob in [!42](https://gitlab.example.com/org/myproject/-/merge_requests/42)
- Correct jira.context tool names by @carol in [!41](https://gitlab.example.com/org/myproject/-/merge_requests/41)
- Add comprehensive test suite by @bob in [!40](https://gitlab.example.com/org/myproject/-/merge_requests/40)

**Full Changelog:** [v1.1.0...v1.2.0](https://gitlab.example.com/org/myproject/-/compare/v1.1.0...v1.2.0)
```

## Install

```bash
lola mod add https://github.com/mrbrandao/git-release.git
lola install git-release
```

## License

Apache-2.0
