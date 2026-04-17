# gitlab-release

An AI agent skill that generates formatted release notes for GitLab project
tags, mimicking GitHub's release notes style. Supports Slack and Markdown
output formats.

## Requirements

- **git** — to read tags, commits, and remote configuration
- **glab** — GitLab CLI, used to query merge request data and the authenticated
  user via the API

### Installing glab

**Linux (dnf/rpm):**
```bash
sudo dnf install glab
```

**Linux (apt):**
```bash
sudo apt install glab
```

**macOS:**
```bash
brew install glab
```

**Other platforms:** see the [official install guide](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation_instructions.md).

### Creating a GitLab Personal Access Token

`glab` needs a token to authenticate against the GitLab API.

1. Go to your GitLab instance → **User Settings** → **Access Tokens**
   (e.g. `https://gitlab.com/-/user_settings/personal_access_tokens`)
2. Click **Add new token**
3. Give it a name (e.g. `glab-cli`) and set an expiry date
4. Select the **`api`** scope
5. Click **Create personal access token** and copy the value

Then authenticate glab:
```bash
glab auth login --hostname <your-gitlab-host>
```

Follow the prompts and paste your token when asked. For gitlab.com:
```bash
glab auth login
```

Verify it works:
```bash
glab api user
```

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

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for details.
