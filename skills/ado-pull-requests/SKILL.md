---
name: ado-pull-requests
description: >
  Use when the user asks about Azure DevOps pull requests, code reviews, PR comments,
  or wants to create, approve, or complete a PR. "show me my open pull requests",
  "list PRs waiting for my review", "approve PR #89", "add a review comment to PR #91",
  "create a pull request from feature/redis to main", "resolve the thread on PR #89",
  "show PR status and merge conflicts", "who reviewed PR #77", "complete PR #89 with
  squash merge", "add Alice as reviewer to PR #91"
license: MIT
metadata:
  version: "1.0"
---

# ADO Pull Requests

List, create, review, comment on, and complete Azure DevOps pull requests. Manage review
threads and track the full PR lifecycle from draft to merge.

## When to use

- User wants to see open PRs (all, assigned to them, or authored by them)
- User wants to create a new PR
- User wants to approve, reject, or add reviewers to a PR
- User wants to add a review comment or reply to a thread
- User wants to resolve or reactivate a review thread
- User wants to complete (merge) or abandon a PR

## MCP tools used

| Tool | Purpose |
|---|---|
| `repo_pull_request` | List or get pull requests |
| `repo_pull_request_write` | Create, update, approve, complete, or abandon a PR |
| `repo_pull_request_thread` | List review threads and comments on a PR |
| `repo_pull_request_thread_write` | Add, reply to, or update a review thread |

## Workflow

### Listing PRs

1. Identify filters: project, repository, status (active/completed/abandoned),
   reviewer (me), or author.
2. Call `repo_pull_request(project, repo, status, reviewerId)`.
3. Present the **PR List** table.

### Getting a single PR

1. Call `repo_pull_request(repo, prId)` — returns title, description, source/target
   branches, reviewers, status, merge status, and thread count.
2. Optionally call `repo_pull_request_thread(prId)` to show open review threads.

### Creating a PR

1. Extract: repo, source branch, target branch, title, description.
2. Extract optional: reviewers, work item links, draft status.
3. Confirm with the user (this is a write operation).
4. Call `repo_pull_request_write(create, ...)`.
5. Confirm with the new PR ID and URL.

### Approving / voting on a PR

1. Identify PR ID and vote (approve, approve with suggestions, wait for author, reject).
2. Call `repo_pull_request_write(vote, prId, vote)`.
3. Confirm the vote was recorded.

### Adding a review comment

1. Identify PR ID, file path and line (optional), and comment text.
2. Call `repo_pull_request_thread_write(prId, comment, filePath, line)`.
3. Confirm the thread was created.

### Completing a PR

1. Identify PR ID and merge strategy (merge commit, squash, rebase, rebase+squash).
2. Confirm with the user before proceeding — this is irreversible.
3. Call `repo_pull_request_write(complete, prId, mergeStrategy, deleteSourceBranch)`.
4. Confirm with the merge commit hash.

## Output Format

### PR List

| PR # | Title | Author | Source → Target | Threads | Status |
|---|---|---|---|---|---|
| 89 | feat: add Redis cache layer | Carlos Silva | feature/redis → main | 3 open | Active |
| 91 | fix: null ref in OrderService | Alice Martin | fix/null-order → main | 0 | Draft |
| 77 | chore: update dependencies | Bob Nguyen | chore/deps → main | 0 | Completed |

### Review Threads

| Thread | File | Line | Status | Comments |
|---|---|---|---|---|
| #1 | src/Cache/RedisClient.cs | 45 | Active | 2 (Bob, Alice) |
| #2 | src/Cache/RedisClient.cs | 67 | Active | 1 (Bob) |
| #3 | README.md | — | Resolved | 1 (Carlos) |

## Notes

- Only confirm write operations (create, approve, complete) with the user before executing.
  Read-only operations (list, get) can proceed without confirmation.
- When the user says "approve PR #89 with comment", call `repo_pull_request_write` for
  the vote and `repo_pull_request_thread_write` for the comment — two tool calls.
- Completing a PR that has conflicts will fail. Check `mergeStatus` from `repo_pull_request`
  first; if `conflicts`, inform the user and suggest resolving them before completing.
- Draft PRs cannot be completed until published. Call `repo_pull_request_write(publish)`
  first if the user asks to complete a draft.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
