---
name: ado-pm-reporting
description: >
  Use when the user asks for project management reports, release readiness, sprint health,
  team velocity, backlog grooming, stakeholder updates, or retrospective publishing.
  "sprint health report", "go/no-go for the release", "release readiness check",
  "velocity trend for the last 4 sprints", "how much can we commit next sprint",
  "weekly status update for stakeholders", "backlog grooming — unrefined stories",
  "items without story points or acceptance criteria", "what slipped from the sprint",
  "cross-project visibility on a feature", "publish retrospective notes to the wiki",
  "committed vs completed points", "are we on track for the release",
  "open P1 bugs before go-live", "team capacity vs commitment", "PM dashboard",
  "prepare the project committee deck", "create a PowerPoint for the steering committee",
  "generate a presentation from ADO data", "build a slide deck for the sprint review",
  "make a PowerPoint for the release committee", "project committee presentation"
license: MIT
metadata:
  version: "1.0"
---

# ADO PM Reporting

Composite project management workflows that combine work items, sprint data, pipelines,
test results, and wiki publishing into executive-ready reports and PM artefacts.

This skill orchestrates multiple underlying MCP tool groups so the user does not need to
know which individual tool to call — describe the PM need and the skill assembles the
right calls in sequence.

## When to use

- User wants a **sprint health report** (committed vs completed, slippage, blockers)
- User wants a **go/no-go / release readiness check** (open P1 bugs, build status, test pass rate)
- User wants a **velocity trend** across past sprints to plan the next commitment
- User wants a **weekly stakeholder update** (progress, pipeline health, blockers)
- User wants to **groom the backlog** (find unrefined, unestimated, or unassigned items)
- User wants to **set up a new sprint** with capacity and carry-over items
- User wants to **publish a retrospective** to the wiki
- User needs **cross-project visibility** on a topic (e.g. duplicate initiatives)

## MCP tools used

| Tool group | Tools | Purpose |
|---|---|---|
| Work Items | `wit_query`, `wit_backlog`, `wit_work_item_write` | Query and update items for reports |
| Sprints | `work`, `work_iteration_write`, `work_capacity_write` | Iteration data and capacity |
| Pipelines | `pipelines_build` | Build health for release checks |
| Test Plans | `testplan_show_test_results_from_build_id` | Test pass rate for release checks |
| Search | `search_workitem` | Cross-project item discovery |
| Wiki | `wiki_upsert_page` | Publish retrospectives and PM notes |

---

## Workflow A — Sprint Health Report

**Triggers:** "sprint health report", "sprint status", "what slipped", "committed vs completed"

1. Call `work(project, team)` — get the active or named iteration name and date range.
2. Call `wit_query(wiql)` for all items in that iteration; group by state
   (Done/Closed = completed, Active/In Progress = in flight, New = not started).
3. Sum story points per group. Calculate completion rate = completed ÷ committed × 100.
4. Identify slipped items: items still in Active or New state at sprint end (or near end).
5. Present **Sprint Health** output. Offer to move slipped items to next sprint.

### Output — Sprint Health

**{Team} — Sprint {N} Health Report**

| Metric | Value |
|---|---|
| Committed points | 42 |
| Completed points | 35 |
| Completion rate | 83% |
| Items completed | 11 / 14 |
| Slipped items | 3 |

**Slipped items:**

| ID | Type | Title | Points | Assignee |
|---|---|---|---|---|
| 1042 | Story | Add MFA to login flow | 5 | Alice Martin |
| 1058 | Bug | Session token not refreshed | 2 | (unassigned) |

---

## Workflow B — Go/No-Go Release Readiness

**Triggers:** "go/no-go", "release readiness", "are we ready to release", "open P1 bugs before go-live"

1. Call `wit_query` for open bugs with Priority = 1 in the project. Flag count and owners.
2. Call `pipelines_build(project, null, releaseBranch)` — get latest build status on the
   release branch.
3. Get that build's ID; call `testplan_show_test_results_from_build_id(buildId)` —
   summarise pass/fail/skipped counts and failing test names.
4. Assemble a **Go/No-Go** table. Apply rule: NO-GO if any P1 bug is open OR build is
   failing; WARN if test pass rate < 98%.

### Output — Go/No-Go

**{Version} Release — Go/No-Go Assessment**

| Check | Status | Detail |
|---|---|---|
| Open P1 bugs | ⚠ 2 open | #1058 unassigned, #1063 Alice |
| Release branch build | ✅ Passing | Build #512 — 2h ago |
| Test pass rate | ✅ 98.9% | 3 failures (integration) |
| **Verdict** | **NO-GO** | Resolve P1 bugs before release |

---

## Workflow C — Velocity Trend & Sprint Commitment

**Triggers:** "velocity trend", "how much can we commit", "team velocity", "capacity vs velocity"

1. Call `work(project, team)` to list all past iterations (last N sprints as requested,
   default 4).
2. For each past iteration, call `wit_query` for items with state Done/Closed in that
   iteration path; sum story points → velocity for that sprint.
3. Calculate average velocity. Recommend commitment range = average ± 10%.
4. If capacity data is available (`work_capacity_write` was previously set), compare
   available hours vs historical throughput per point.

### Output — Velocity Trend

**{Team} — Velocity (last 4 sprints)**

| Sprint | Committed | Completed | Velocity |
|---|---|---|---|
| Sprint 9 | 38 | 36 | 36 |
| Sprint 10 | 40 | 38 | 38 |
| Sprint 11 | 45 | 40 | 40 |
| Sprint 12 | 42 | 35 | 35 |
| **Average** | — | — | **37** |

> Recommended Sprint 13 commitment: **34–39 points.**

---

## Workflow D — Stakeholder Weekly Update

**Triggers:** "weekly update", "stakeholder report", "weekly status", "progress summary"

1. Call `wit_query` for items moved to Done/Closed in the last 7 days across the project.
2. Call `pipelines_build` for the project's key pipelines — summarise pass/fail.
3. Call `wit_query` for items tagged "blocker" or in Blocked state (or flagged).
4. Draft a structured update using the three data sets.

### Output — Stakeholder Update

> **{Project} — Weekly Update (Week of {date})**
>
> **Completed ({N} items):** brief list of closed work items
> **Pipeline health:** per-pipeline pass/fail summary
> **Blockers:** open blocked items with owner

---

## Workflow E — Backlog Grooming

**Triggers:** "backlog grooming", "unrefined stories", "no story points", "no acceptance criteria",
"unassigned backlog", "items not in a sprint"

1. Build WIQL query filtering: Type = User Story, State = New,
   IterationPath = project root (not assigned to a sprint), StoryPoints = null.
2. Call `wit_query(wiql)` — return results ordered by Priority.
3. Present the **Grooming Queue** table.
4. Offer bulk actions: "Set story points on #X to N", "Assign #X to Sprint 13".

### Output — Grooming Queue

| Priority | ID | Title | Assigned To | Notes |
|---|---|---|---|---|
| 1 | 1081 | Implement SSO for mobile app | (unassigned) | No points, no sprint |
| 2 | 1085 | Add export to Excel on reports | (unassigned) | No points, no sprint |

---

## Workflow F — New Sprint Setup

**Triggers:** "set up sprint", "create next sprint", "plan Sprint N", "new iteration with capacity"

1. Call `work_iteration_write(project, name, startDate, endDate)` — create the iteration.
2. Call `work_capacity_write` for each team member with hours/day and days off.
3. If the user mentions carry-over items, call `wit_work_item_write` to update iteration
   path on each item ID.
4. Confirm iteration, total available hours, and moved items.

---

## Workflow G — Retrospective Publishing

**Triggers:** "publish retrospective", "retrospective notes", "retro to wiki", "sprint retro"

1. Extract four sections from the user's input:
   - What went well
   - What to improve
   - Team agreements (new rules/norms)
   - Action items (owner + due date)
2. Format as a structured Markdown page using the standard retro template (see below).
3. Call `wiki_upsert_page(project, wikiId, "Retrospectives/Sprint-N", content, comment)`.
4. Return the published page URL.

### Retrospective template

```markdown
# Sprint {N} Retrospective — {Team}

**Date:** {date}  **Facilitator:** {name}

## What went well
- ...

## What to improve
- ...

## Team agreements
- ...

## Action items

| Action | Owner | Due |
|---|---|---|
| ... | ... | ... |
```

---

## Workflow I — Project Committee PowerPoint Deck

**Triggers:** "prepare the committee deck", "create a PowerPoint", "slide deck for the steering committee",
"project committee presentation", "sprint review deck", "generate slides from ADO data"

This workflow pulls live ADO data, assembles it into a structured slide outline, and
hands it to **Microsoft 365 Copilot's native PowerPoint generation** (`create_presentation`)
to produce a `.pptx` file — no manual copy-paste between ADO and PowerPoint needed.

> **Availability:** PowerPoint generation requires **Microsoft 365 Copilot** (Option C —
> M365 connector deployment). In VS Code Copilot (Option B), the skill produces the full
> slide outline as structured Markdown that you can paste into PowerPoint or Copilot for
> PowerPoint manually.

### Step 1 — Gather ADO data

Run the relevant workflows first (A–H above) based on what the committee needs:

| Meeting type | Workflows to run first |
|---|---||
| Sprint review | A (sprint health) + C (velocity) |
| Release / go-live committee | B (go/no-go) + A (sprint health) |
| Quarterly steering committee | C (velocity trend) + D (stakeholder update) + E (backlog) |
| Retrospective session | G (retrospective data) |

### Step 2 — Assemble the slide outline

Structure the collected data into the slide deck blueprint below. Fill each section
from the workflow outputs:

```
Slide 1  — TITLE
  {Project name} — {Meeting type}
  {Date} | Presented by {PM name}

Slide 2  — AGENDA
  1. Sprint / Release summary
  2. Key achievements
  3. Risks & blockers
  4. Next sprint / next steps
  5. Decisions needed

Slide 3  — SPRINT / RELEASE SUMMARY (from Workflow A or B)
  • Committed: {N} pts  Completed: {N} pts  ({%} rate)
  • Build status: {pass/fail}  Test pass rate: {%}
  • Slipped items: {N}

Slide 4  — KEY ACHIEVEMENTS (top completed items from Workflow D)
  • {Title of completed work item 1}
  • {Title of completed work item 2}
  • {Title of completed work item 3}
  (limit to top 5 — choose highest priority / most visible)

Slide 5  — RISKS & BLOCKERS
  • Open P1 bugs: {list from Workflow B}
  • Blocked items: {list from Workflow D}
  • Each row: ID | Title | Owner | Mitigation

Slide 6  — VELOCITY & FORECAST (from Workflow C)
  • Velocity chart: last 4 sprints (table form if chart not available)
  • Next sprint recommendation: {N}–{N} points
  • Capacity: {total available hours}

Slide 7  — NEXT SPRINT / NEXT STEPS (from Workflow F or backlog)
  • Sprint {N}: {start}–{end}
  • Committed items (top 5 by priority)
  • Capacity allocated: {N}h

Slide 8  — DECISIONS NEEDED
  • {Item requiring committee decision 1}
  • {Item requiring committee decision 2}
  (extract from blocked items, slipped high-priority stories, or user input)

Slide 9  — THANK YOU / Q&A
```

### Step 3 — Generate the PowerPoint

**In M365 Copilot (Option C):**
Pass the assembled outline to Copilot's `create_presentation` capability:

> "Create a PowerPoint presentation from this outline using our corporate template."

Copilot will produce a `.pptx` file saved to OneDrive / SharePoint, which you can
share directly in the meeting invite.

**In VS Code Copilot (Option B):**
The skill outputs the outline as formatted Markdown. Copy it and:
- Open PowerPoint → Copilot sidebar → "Create presentation from outline" → paste
- Or use Copilot for Microsoft 365 in PowerPoint directly

### Output — Slide outline (Markdown preview)

```
# Platform Project — Release Committee  |  June 2026

## Sprint 12 Summary
- Committed: 42 pts | Completed: 35 pts | Rate: 83%
- Build: ✅ Passing | Tests: 98.9% pass
- Slipped: 3 items (moving to Sprint 13)

## Key Achievements
- Redis cache layer deployed to staging
- API rate limiting implemented
- Onboarding flow redesign — UX sign-off complete

## Risks & Blockers
| # | Title | Owner | Mitigation |
|---|---|---|---|
| 1058 | Session token not refreshed | Alice Martin | Fix in progress — due June 10 |
| 1063 | Null ref in OrderService | (unassigned) | Needs owner assignment |

## Velocity & Forecast
| Sprint | Velocity |
|---|---|
| Sprint 9 | 36 | Sprint 10 | 38 | Sprint 11 | 40 | Sprint 12 | 35 |
Average: 37 pts — Recommended commitment Sprint 13: 34–39 pts

## Next Sprint (Sprint 13 — June 9–22)
- Top 3 committed items: [SSO mobile, Export Excel, Notification prefs]
- Capacity: 124h available

## Decisions Needed
- Assign owner for bug #1063 — P1, currently unassigned
- Approve scope reduction: defer dark mode (#1092) to Sprint 14?
```

---

## Workflow H — Cross-project Feature Visibility

**Triggers:** "cross-project", "are other teams working on", "duplicate initiatives", "org-wide search for"

1. Call `search_workitem(query)` without a project filter — searches the whole organisation.
2. Group results by project.
3. Highlight active items in other projects that overlap with the user's topic.
4. Offer to link related items across projects.

---

## Notes

- These workflows are **read-heavy**: all read operations proceed without confirmation.
  Write operations (creating iterations, moving items, publishing wiki pages) are confirmed
  with the user before executing.
- Story point field name varies by process template:
  `Microsoft.VSTS.Scheduling.StoryPoints` (Agile) or `Microsoft.VSTS.Scheduling.Effort`
  (Scrum). Check with `wit_work_item` on one existing item if unsure.
- For velocity, only count items in state Done or Closed — Active items in a past iteration
  are partial completions and should be excluded or noted separately.
- When the user asks for a report covering multiple teams, run each team's data call
  separately and stack the tables vertically with the team name as a header row.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
