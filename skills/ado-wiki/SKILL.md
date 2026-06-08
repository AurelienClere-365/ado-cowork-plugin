---
name: ado-wiki
description: >
  Use when the user wants to read, write, or update Azure DevOps wiki pages. "show the
  deployment guide in the wiki", "write an ADR to the Architecture wiki", "update the
  onboarding page with the new repo setup steps", "create a wiki page for the Redis
  caching decision", "list all wiki pages in the Platform project", "what wikis exist in
  this project", "add a section to the runbook page", "publish meeting notes to the wiki"
license: MIT
metadata:
  version: "1.0"
---

# ADO Wiki

Read and write Azure DevOps wiki pages. Browse wiki structure, read page content, and
create or update pages with Markdown content.

## When to use

- User wants to read a specific wiki page
- User wants to list wiki pages in a project
- User wants to create a new wiki page
- User wants to update an existing wiki page (append section, replace content, etc.)
- User wants to publish notes, ADRs, runbooks, or documentation to the wiki

## MCP tools used

| Tool | Purpose |
|---|---|
| `wiki` | List wikis in a project, or list pages within a wiki |
| `wiki_upsert_page` | Create or update a wiki page (create if not exists, update if exists) |

## Workflow

### Listing wikis and pages

1. Call `wiki(project)` — returns all wikis in the project with name, type
   (project wiki or code wiki), and wiki ID.
2. If the user asks for pages, call `wiki(project, wikiId, path)` to list child pages
   under a given path.
3. Present the **Wiki List** or **Page Tree** table.

### Reading a page

1. Identify: project, wiki name/ID, and page path.
2. Call `wiki(project, wikiId, pagePath)` with content=true.
3. Return the page content as Markdown.

### Writing or updating a page

1. Identify: project, wiki ID, page path, and content.
2. If updating an existing page, read the current content first via `wiki` (if the user
   wants to append or merge — not overwrite).
3. Confirm with the user what will be written, especially for updates to existing pages.
4. Call `wiki_upsert_page(project, wikiId, pagePath, content, comment)`.
5. Confirm with the new/updated page URL.

### Writing an Architecture Decision Record (ADR)

When the user asks to write an ADR, use the following template:

```markdown
# ADR-NNN <Title>

**Date:** YYYY-MM-DD
**Status:** Accepted

## Context

<Why this decision was needed>

## Decision

<What was decided>

## Consequences

<What are the trade-offs and downstream impacts>
```

Fill the template from the user's description, then upsert the page at
`Architecture/ADRs/ADR-NNN <Title>`.

## Output Format

### Wiki List

| Wiki | Type | ID |
|---|---|---|
| Platform.wiki | Project wiki | wiki-abc-123 |
| api-gateway.wiki | Code wiki | wiki-def-456 |

### Page Tree (under Architecture/)

```
Architecture/
├── ADRs/
│   ├── ADR-001 Use PostgreSQL
│   ├── ADR-002 API Gateway pattern
│   └── ADR-007 Redis for session caching
├── Diagrams/
└── Decisions Log
```

### Page written confirmation

> Wiki page **created/updated**: `Architecture/ADRs/ADR-007 Redis for session caching`
> URL: https://dev.azure.com/YOUR_ORG/Platform/_wiki/wikis/Platform.wiki/42

## Notes

- `wiki_upsert_page` uses ETag-based optimistic concurrency. If the page was edited
  concurrently, the tool returns a conflict error — read the latest version and re-apply
  the change.
- Page paths use `/` as separator and should NOT start with `/` for most MCP implementations.
- When creating a page in a path where parent folders do not exist, `wiki_upsert_page`
  typically creates the parent pages automatically. Verify with the returned URL.
- Code wikis are backed by a Git repository — changes appear as commits in that repo.
- Always use proper Markdown in page content: headings (`#`), code blocks (` ``` `),
  tables, and bullet lists render correctly in the ADO wiki viewer.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
