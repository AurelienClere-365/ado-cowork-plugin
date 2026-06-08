---
name: ado-repositories
description: >
  Use when the user asks about Azure DevOps Git repositories, branches, source files,
  commit history, or wants to create a branch. "list repos in the Platform project",
  "show the file structure of the api-gateway repo", "read the content of appsettings.json",
  "what branches exist in backend", "create a branch feature/my-feature from main",
  "show recent commits on the release/2.0 branch", "find commits by Alice last week",
  "what changed in the last merge to main", "show me the YAML pipeline file"
license: MIT
metadata:
  version: "1.0"
---

# ADO Repositories

Browse Azure DevOps Git repositories, explore files and folders, view branch lists,
read file contents, inspect commit history, and create branches.

## When to use

- User wants to list all repositories in a project
- User wants to navigate the file tree of a repository
- User wants to read the content of a specific file
- User wants to see which branches exist
- User wants to create a new branch (e.g. from main for a feature)
- User wants to see commit history for a branch or file
- User wants to find commits by a specific author or in a date range

## MCP tools used

| Tool | Purpose |
|---|---|
| `repo_repository` | List repositories or get metadata for a specific repo |
| `repo_branch` | List branches in a repository |
| `repo_create_branch` | Create a new branch from a source ref |
| `repo_file` | Read file content or list directory contents |
| `repo_search_commits` | Search commit history with filters |

## Workflow

### Listing repositories

1. Call `repo_repository(project)` — returns all repos with name, ID, default branch,
   size, and last update time.
2. Present the **Repository List** table.

### Browsing files

1. Identify: repository name and optional path.
2. Call `repo_file(repo, path, branch)` with path = `"/"` for root listing.
3. For a folder: returns child items (files and subfolders).
4. For a file: returns the raw content.
5. If the content is code, present it in a fenced code block with the correct language tag.

### Listing branches

1. Call `repo_branch(repo)` — returns all branches with name, last commit hash,
   last commit date, and author.
2. Present the **Branch List** table.

### Creating a branch

1. Identify: repo, new branch name, and source branch (default: `main`).
2. Confirm with the user before proceeding (branch creation is a write operation).
3. Call `repo_create_branch(repo, newBranchName, sourceBranch)`.
4. Confirm with the new branch name and its source commit.

### Commit history

1. Identify: repo, branch (optional), author filter (optional), date range (optional).
2. Call `repo_search_commits(repo, branch, author, fromDate, toDate, top)`.
3. Present the **Commit History** table.

## Output Format

### Repository List

| Repository | Default Branch | Last Updated | Size |
|---|---|---|---|
| api-gateway | main | 2h ago | 4.2 MB |
| identity-service | main | 1d ago | 1.8 MB |
| shared-lib | main | 3d ago | 0.6 MB |

### Branch List

| Branch | Last Commit | Author | Date |
|---|---|---|---|
| main | `a1b2c3d` | Alice Martin | 2h ago |
| feature/redis | `e4f5a6b` | Carlos Silva | 4h ago |
| release/2.0 | `c7d8e9f` | Bob Nguyen | 1d ago |

### Commit History

| Hash | Message | Author | Date |
|---|---|---|---|
| `a1b2c3d` | fix: refresh token before expiry (#1058) | Alice Martin | 2h ago |
| `b2c3d4e` | feat: add Redis cache layer | Carlos Silva | 1d ago |
| `c3d4e5f` | chore: update dependencies | Bob Nguyen | 2d ago |

## Notes

- File content returned by `repo_file` is base64-encoded for binary files. For text files,
  decode and present as a code block.
- Branch names may contain slashes (e.g. `feature/my-feature`). Pass them URL-encoded if
  the MCP tool requires it.
- Confirm branch creation before calling `repo_create_branch` — this is a write operation
  that cannot be easily undone without repo admin access.
- To read a pipeline YAML file, use `repo_file(repo, 'azure-pipelines.yml', branch)`.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
