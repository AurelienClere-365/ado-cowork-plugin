---
name: ado-sprints-capacity
description: >
  Use when the user asks about sprint planning, iterations, team capacity, or wants to
  create or update iteration schedules. "what is the current sprint", "show team capacity
  for Sprint 12", "create a new iteration called Sprint 13", "set Alice's capacity to 6
  hours per day", "how many days are left in the current sprint", "list all iterations in
  the release plan", "update the sprint end date", "who has remaining capacity this sprint"
license: MIT
metadata:
  version: "1.0"
---

# ADO Sprints & Capacity

Manage Azure DevOps iterations (sprints), team capacity settings, and sprint planning
boards. Read current sprint status and write capacity or iteration changes.

## When to use

- User wants to see current and upcoming iterations for a team
- User wants to create a new iteration / sprint
- User wants to set or update team member capacity for a sprint
- User is doing sprint planning and needs capacity vs. committed work analysis
- User wants to move work items to a different iteration

## MCP tools used

| Tool | Purpose |
|---|---|
| `work` | Get sprint/iteration board and current work overview for a team |
| `work_capacity_write` | Set or update daily capacity for a team member in a sprint |
| `work_iteration_write` | Create or update an iteration (sprint) definition |

## Workflow

### Getting the current sprint overview

1. Call `work(project, team)` to get the active iteration: name, start date, end date,
   total working days, and the team's committed work items.
2. Derive capacity utilisation: committed story points vs. total available hours if
   capacity is set.
3. Present the **Sprint Overview** table.

### Listing iterations

1. Call `work(project, team)` — returns the current, past, and upcoming iterations.
2. Present as an **Iterations** table with state (active / past / future) and date ranges.

### Creating a new iteration

1. Extract: project, iteration name, start date, end date from the user request.
2. Call `work_iteration_write(project, name, startDate, endDate)`.
3. Confirm creation and surface the option to assign work items to the new sprint.

### Setting team capacity

1. Identify: project, team, sprint name, team member name, and hours per day.
2. Call `work_capacity_write(project, team, iterationId, memberId, hoursPerDay, daysOff)`.
3. Confirm the update with the new capacity value.

## Output Format

### Sprint Overview

| Field | Value |
|---|---|
| Sprint | Sprint 12 |
| Start | 2026-05-26 |
| End | 2026-06-08 |
| Working days | 10 |
| Team | Platform Core |

### Team Capacity

| Member | Capacity (h/day) | Days off | Available (h) |
|---|---|---|---|
| Alice Martin | 6 | 0 | 60 |
| Bob Nguyen | 7 | 1 | 63 |
| Carlos Silva | 6 | 2 | 48 |
| **Team total** | — | — | **171** |

### Iterations

| Iteration | State | Start | End |
|---|---|---|---|
| Sprint 11 | Past | 2026-05-12 | 2026-05-25 |
| Sprint 12 | Active | 2026-05-26 | 2026-06-08 |
| Sprint 13 | Future | 2026-06-09 | 2026-06-22 |

## Notes

- Iteration IDs (GUIDs) are needed for `work_capacity_write`; retrieve them from `work`.
- When capacity is not yet set for a sprint, `work` returns zero for all members. Prompt
  the user to set capacity before doing a sprint commitment analysis.
- Date format for `work_iteration_write`: ISO 8601 (`YYYY-MM-DD`).

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
