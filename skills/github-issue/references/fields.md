# GitHub Issue Fields Reference

Quick reference for `gh` CLI field names and
project board fields accessible via GraphQL.

## Issue Metadata (gh issue create/edit)

| Flag        | Values              |
|-------------|---------------------|
| --title     | free text           |
| --body      | free text           |
| --label     | comma-separated     |
| --assignee  | GitHub username     |
| --milestone | milestone name      |
| --type      | Bug, Feature, Task  |
| --state     | open, closed        |

## Project Fields (fields.sh via GraphQL)

| Field     | Type         | Common Values      |
|-----------|--------------|--------------------|
| Priority  | singleSelect | High, Medium, Low  |
| Effort    | singleSelect | High, Medium, Low  |
| Status    | singleSelect | Todo, In Progress, |
|           |              | Done               |
| Iteration | iteration    | Iteration 1, 2, ...|

## gh issue list --json fields

Queryable fields for --json flag:
number, title, body, state, labels, assignees,
milestone, createdAt, updatedAt, closedAt, url,
author, comments.
