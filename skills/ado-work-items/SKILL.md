---
name: ado-work-items
description: >
  Use when the user wants to create, read, update, or manage Azure DevOps work items —
  including bugs, user stories, tasks, epics, features, and PBIs.
  "create a bug for the login timeout issue", "update story #42 to In Progress",
  "add a comment to work item #55", "link bug #77 to user story #42",
  "show me the backlog for the Platform project", "what work items are assigned to me",
  "run a work item query for open bugs in Sprint 12", "attach a file to work item #99",
  "close all resolved bugs in the Mobile App project", "set the story points on task #88 to 3"
license: MIT
metadata:
  version: "1.0"
---

# ADO Work Items

Create, read, update, link, comment, and query Azure DevOps work items. Supports all
work item types: User Story, Bug, Task, Epic, Feature, PBI, Issue.

## When to use

- User wants to create a new work item (any type)
- User wants to update fields on an existing work item (state, assignee, story points, etc.)
- User wants to add a comment or resolve a comment thread
- User wants to link two work items (Parent/Child, Related, Blocks, Duplicate)
- User wants to browse the product backlog
- User wants to run a saved or ad-hoc WIQL query
- User wants to attach a file or screenshot to a work item

## MCP tools used

| Tool | Purpose |
|---|---|
| `wit_work_item` | Read a work item by ID |
| `wit_work_item_write` | Create or update a work item |
| `wit_work_item_comment_write` | Add a comment to a work item |
| `wit_work_item_link_write` | Add a link between two work items |
| `wit_work_item_attachment` | Attach a file to a work item |
| `wit_backlog` | List work items in a project/team backlog |
| `wit_query` | Run a WIQL query or saved query |

## Workflow

### Reading a work item

1. Call `wit_work_item(id)` — returns all fields: title, state, assignee, area, iteration,
   story points, tags, description, and comment count.
2. Present the key fields in the **Work Item Detail** format below.

### Creating a work item

1. Extract required fields from the user's request: work item type, title, project.
2. Extract optional fields: description, assignee, area path, iteration path, story points,
   priority, tags, acceptance criteria.
3. Call `wit_work_item_write` with the field patch document.
4. Confirm creation with the new ID and a deep link to the work item.

### Updating a work item

1. Identify the work item ID from the user's request.
2. Identify the field(s) to change.
3. Call `wit_work_item_write(id, patchDocument)` with only the changed fields.
4. Confirm the update.

### Linking work items

1. Identify source ID, target ID, and link type (Parent, Child, Related, Blocks, Duplicate).
2. Call `wit_work_item_link_write(sourceId, targetId, linkType)`.
3. Confirm the link was created.

### Backlog

1. Identify project and team name.
2. Call `wit_backlog(project, team)` to get the ordered backlog.
3. Apply optional filters (type, state, assignee) in the result.
4. Present as a **Backlog** table.

### Query

1. If the user provides a saved query name, call `wit_query(queryName)`.
2. If the user describes criteria in plain English, build a WIQL WHERE clause and call
   `wit_query(wiql)`.
3. Return results as a table (ID, Type, Title, State, Assignee).

## Output Format

### Work Item Detail

| Field | Value |
|---|---|
| ID | 1042 |
| Type | User Story |
| Title | Add MFA to login flow |
| State | Active |
| Assigned To | Alice Martin |
| Story Points | 5 |
| Iteration | Sprint 12 |
| Area | Platform/Auth |
| Tags | security, auth |

### Backlog

| # | ID | Type | Title | State | Points | Assignee |
|---|---|---|---|---|---|---|
| 1 | 1042 | Story | Add MFA to login flow | Active | 5 | Alice |
| 2 | 1058 | Bug | Session token not refreshed | New | — | — |
| 3 | 1071 | Task | Write ADR for auth service | Active | 2 | Bob |

### Query results

| ID | Type | Title | State | Assignee |
|---|---|---|---|---|
| 1058 | Bug | Session token not refreshed | New | (unassigned) |
| 1063 | Bug | Null ref in OrderService | Active | Alice Martin |

## Notes

- When creating linked items in one user request (e.g. "create a bug and link it to #42"),
  create the work item first, capture the new ID, then call `wit_work_item_link_write`.
- Story Points field name varies by process template: `Microsoft.VSTS.Scheduling.StoryPoints`
  (Agile) or `Microsoft.VSTS.Scheduling.Effort` (Scrum). Use `wit_work_item` on an existing
  item first to confirm the correct field name.
- To bulk-update multiple items, iterate `wit_work_item_write` calls; there is no bulk API.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
