# gitlab-release

An AI agent skill that generates formatted release notes for GitLab project
tags, mimicking GitHub's release notes style. Supports Slack and Markdown
output formats.

## Installation

### Via LoLa (recommended)

```bash
lola mod add https://github.com/mrbrandao/gitlab-release
lola install gitlab-release
```

### Via LeGambiArt Marketplace

```bash
lola market add LeGambiArt https://raw.githubusercontent.com/LeGambiArt/lola-market/refs/heads/main/lola-market.json
lola install gitlab-release
```

### Manual Installation (without LoLa)

```bash
mkdir -p .claude/skills/gitlab-release
curl -o .claude/skills/gitlab-release/SKILL.md \
  https://raw.githubusercontent.com/mrbrandao/gitlab-release/main/SKILL.md
```

## Usage

Inside any GitLab repository, invoke the skill:

```
/gitlab-release v1.2.0
```

Specify output format (defaults to `slack`):

```
/gitlab-release v1.2.0 slack
/gitlab-release v1.2.0 markdown
```

If no tag is provided, the skill shows recent tags and prompts you to pick one:

```
/gitlab-release
```

## Example Output (Slack)

```
New Release: my-project v1.2.0

  @username released this today

  https://gitlab.com/org/my-project/-/tags/v1.2.0
  https://gitlab.com/org/my-project/-/commit/abc1234

  What's Changed

  • feat: add new feature by @alice in !42
  • fix: resolve edge case by @bob in !43

  Full Changelog: https://gitlab.com/org/my-project/-/compare/v1.1.0...v1.2.0
```

## Requirements

- **git** — to read tags, commits, and remote configuration
- **glab** — GitLab CLI, used to query merge request data via the API
  ([install instructions](https://gitlab.com/gitlab-org/cli))

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for details.
