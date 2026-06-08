---
name: ado-search
description: >
  Use when the user wants to search across Azure DevOps — across code files, wiki pages,
  or work items — using keywords or natural language. "find all usages of TokenService
  in code", "search for ADR-007 in the wiki", "find work items mentioning Redis",
  "where is the connection string defined", "search for open bugs related to authentication",
  "find all files containing TODO comments", "search wiki for deployment guide",
  "find work items with tag security in the Platform project"
license: MIT
metadata:
  version: "1.0"
---

# ADO Search

Search across Azure DevOps code repositories, wiki pages, and work items using keywords
or natural language. Returns ranked results with context snippets.

## When to use

- User wants to find code that references a specific class, method, or string
- User wants to find a wiki page by keyword or topic
- User wants to find work items matching a description or keyword (without writing WIQL)
- User is doing an impact analysis and needs to find all references across repos

## MCP tools used

| Tool | Purpose |
|---|---|
| `search_code` | Full-text search across all code in the organisation's repositories |
| `search_wiki` | Full-text search across all wiki pages in the organisation |
| `search_workitem` | Full-text search across work items (title, description, comments) |

## Workflow

### Code search

1. Extract the search term(s) from the user request.
2. Identify optional filters: project, repository, file extension, branch.
3. Call `search_code(query, project, repo, fileExtension)`.
4. Group results by repository and file.
5. Present the **Code Search Results** table with file path, line number, and context snippet.

### Wiki search

1. Extract the search term(s).
2. Identify optional filter: project.
3. Call `search_wiki(query, project)`.
4. Present the **Wiki Search Results** table with page title, project, and excerpt.

### Work item search

1. Extract the search term(s) or topic.
2. Identify optional filters: project, work item type, state.
3. Call `search_workitem(query, project, type, state)`.
4. Present the **Work Item Search Results** table.

### Combined search

When the user's intent spans multiple areas (e.g. "find everything related to Redis"),
run all three tools in sequence and present results grouped by type (Code, Wiki,
Work Items).

## Output Format

### Code Search Results

| Repository | File | Line | Match |
|---|---|---|---|
| api-gateway | src/Auth/AuthService.cs | 87 | `var svc = new TokenService(config)` |
| identity-service | tests/TokenServiceTests.cs | 23 | `TokenService svc = fixture.Create()` |
| shared-lib | src/Interfaces/ITokenService.cs | 5 | `public interface ITokenService` |

> 3 results across 3 repositories.

### Wiki Search Results

| Page | Project | Excerpt |
|---|---|---|
| Architecture/ADRs/ADR-007 | Platform | "...decided to use Redis for session caching because..." |
| Operations/Runbooks/Cache | Platform | "...flush Redis cache via `redis-cli FLUSHDB`..." |

### Work Item Search Results

| ID | Type | Title | State | Project |
|---|---|---|---|---|
| 1042 | Story | Add MFA to login flow | Active | Platform |
| 1058 | Bug | Session token not refreshed | New | Platform |
| 1063 | Task | Evaluate Redis Sentinel setup | Done | Platform |

## Notes

- `search_code` searches the default branch of each repository unless a branch is specified.
- Results from `search_code` are ranked by relevance; the most relevant files appear first.
- For large result sets (>20 items), present the top 10 and offer to show more.
- When doing impact analysis, use `search_code` first to find all call sites, then offer
  to create a work item tracking the change.
- `search_workitem` is faster than constructing a WIQL query for keyword-based searches;
  use `ado-work-items` `wit_query` when the user needs precise field-based filtering.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, scope searches to that project by default. For cross-project
  searches, the user can explicitly say "search across all projects" to override.
- If no context is set, `search_code` and `search_wiki` require a project — invoke
  Workflow E of `ado-context` to resolve it. `search_workitem` can run org-wide without
  a project; mention this to the user if no context is set.
