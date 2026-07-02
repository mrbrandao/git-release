# git-release

AI agent skills for creating releases on GitHub
and GitLab. Follows semver and conventional commits.

## Skills

### github-release

Create signed semver tags and GitHub releases with
auto-generated release notes.

- Detects or suggests the next semver tag
- Generates a signed annotated tag with changelog
- Pushes the tag and creates a GitHub release
- Uses GitHub's generate release notes feature

**Requirements:** `git`, `gh` (GitHub CLI)

### gitlab-release

Generate formatted release notes for GitLab tags.
Outputs in Slack or Markdown format.

- Gathers commits and MR authors between tags
- Formats release notes mimicking GitHub style
- Supports Slack and Markdown output

**Requirements:** `git`, `glab` (GitLab CLI)

## Install

```bash
lola mod add https://github.com/mrbrandao/git-release.git
lola install git-release
```

## License

Apache-2.0
