# github-issue

An agentskills.io skill for managing GitHub issues.

## Requirements

- [gh](https://cli.github.com) (authenticated)
- [yq](https://github.com/mikefarah/yq)
- [jq](https://jqlang.github.io/jq/)

## Scripts

| Script    | Purpose                      |
|-----------|------------------------------|
| lib.sh    | shared functions (sourced)   |
| tpl.sh    | discover issue templates     |
| new.sh    | create an issue              |
| ls.sh     | list/search issues           |
| edit.sh   | update issue metadata        |
| fields.sh | set project board fields     |
| triage.sh | bulk dump for LLM analysis   |
| roadmap.sh| aggregate for planning       |
| test.sh   | behavioral tests             |

## Usage

Each script supports `--help`:

    scripts/ls.sh --help
    scripts/new.sh --title "Fix login bug" \
      --label bug --repo owner/repo

## Testing

    bash scripts/test.sh

## License

Apache-2.0
