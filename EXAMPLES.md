# Usage Examples — ADO Cowork Plugin

The ADO Cowork Plugin is designed for **Project Managers** who need live Azure DevOps
data without leaving their AI assistant — and for developers and functional consultants
who want the same.

Project Manager workflows start at [Example 8](#for-project-managers). Developer and
functional examples are [Examples 1–7](#for-developers--functional-consultants).

---

## The Workflow

```
Business request  ──►  Cowork skill      ──►  ADO MCP tools     ──►  Structured result
(plain English)         (routes intent)        (Azure DevOps API)     (in chat window)
```

---

## Quick navigation

| # | Example | Audience | Skill |
|---|---|---|---|
| 0 | Org & project selection / context setup | All | ado-context |
| 0E | Register a new customer org (guest access) | Consultant | ado-context |
| 0F | Org dashboard — check access to all orgs | All | ado-context |
| 8 | Sprint health: end-of-sprint report | **PM** | ado-pm-reporting |
| 10 | Release readiness: go/no-go | **PM** | ado-pm-reporting |
| 9 | Team capacity: set up sprint | **PM** | ado-sprints-capacity |
| 14 | Velocity trend & commit forecast | **PM** | ado-pm-reporting |
| 11 | Backlog grooming | **PM** | ado-work-items |
| 12 | Stakeholder weekly update | **PM** | ado-pm-reporting |
| 13 | Cross-project search | **PM** | ado-search |
| 15 | Sprint retrospective to wiki | **PM** | ado-wiki |
| 16 | Project committee PowerPoint deck | **PM** | ado-pm-reporting |
| 1 | Sprint planning: triage unestimated | PM / Dev | ado-sprints-capacity |
| 2 | Pipeline triage: find build errors | Dev | ado-pipelines |
| 3 | Code review: list open PRs | Dev | ado-pull-requests |
| 4 | Work item creation from bug | Dev | ado-work-items |
| 5 | Wiki: write an ADR | Dev / Functional | ado-wiki |
| 6 | Search: find class usages | Dev | ado-search |
| 7 | Test plans: check build results | Dev / QA | ado-test-plans |

---

## For Developers & Functional Consultants

---

## Example 0 — Organisation & project selection

### Prompt A — first session, single org, multiple projects

> I want to work on the Platform project.

### What happens

1. `ado-context` skill activates.
2. Only one ADO org is configured in `mcp.json` — org selection is skipped.
3. Calls `core_list_projects` and finds: Finance Modules, Mobile App, Platform.
4. "Platform" matches exactly one project — sets context silently.

### Result

> **Active context set:**
> - Organisation: contoso
> - Project: **Platform** (ID: abc-123-def-456)
>
> All ADO commands this session will use this project automatically.
> To change: "use project Mobile App" or "change organisation".

---

### Prompt B — multiple orgs, switch mid-session

> Switch to the fabrikam organisation and use the eInvoicing project.

### What happens

1. `ado-context` skill activates.
2. Matches `fabrikam` to the `ADO-Fabrikam` mcp.json entry.
3. Calls `core_list_projects` on that server.
4. Matches "eInvoicing" to one project — sets context.

### Result

> **Active context updated:**
> - Organisation: fabrikam (MCP server: ADO-Fabrikam)
> - Project: **eInvoicing** (ID: xyz-789)
>
> Switched from contoso/Platform. All subsequent commands use fabrikam/eInvoicing.

---

### Prompt C — filter from a large org

> List all projects in contoso that contain "finance".

### What happens

1. `ado-context` skill calls `core_list_projects` on `ADO-Contoso`.
2. Filters results where name contains "finance" (case-insensitive).
3. Returns the matches and offers to set one as active.

### Result

> **Projects matching "finance" in contoso:**
>
> | # | Project | State |
> |---|---|---|
> | 1 | Finance Modules | Active |
> | 2 | Finance Reporting | Active |
>
> Which project would you like to use? Reply with the name or number.

---

### Prompt D — check and reset context

> Which project am I in?

### Result

> **Active context:**
> - Organisation: contoso
> - Project: Platform (ID: abc-123-def-456)
>
> To switch: "use project [name]" or "change organisation".

---

### Prompt E — register a new customer organisation (guest access)

> I am a consultant and I have guest access to the Contoso Azure DevOps. Add it so I
> can work on their projects.

### What happens

1. `ado-context` skill activates Workflow F.
2. Asks for the org name (or extracts "contoso" from the prompt).
3. Generates the mcp.json entry and explains where to add it.
4. Explains the one-time Azure AD guest sign-in step.
5. After user confirms they’ve added the entry and reloaded VS Code, calls
   `core_list_projects` on the new server to verify access.

### Result

> **Add this entry to your `mcp.json`** (`%APPDATA%\Code\User\mcp.json`):
>
> ```jsonc
> "ADO-Contoso": {
>     "url": "https://mcp.dev.azure.com/contoso",
>     "type": "http"
> }
> ```
>
> After saving, run **Developer: Reload Window** (Ctrl+Shift+P).
>
> **First-time sign-in:** VS Code will open a browser prompt for the Contoso Azure AD
> tenant. Accept the guest sign-in. This happens once — the token is cached.
>
> Once added and reloaded, say: **"use org contoso"** to switch to it.

---

### Prompt F — org dashboard (check access to all organisations)

> Show me all my ADO organisations and tell me which ones I can access.

### What happens

1. `ado-context` skill activates Workflow G.
2. Reads all `https://mcp.dev.azure.com/` entries from mcp.json.
3. Calls `core_list_projects` on each silently.
4. Builds the dashboard from the results.

### Result

```
ADO Organisation Dashboard
─────────────────────────────────────────────────────
  #   Organisation      Type         Projects   Status
─────────────────────────────────────────────────────
  1   contoso           Home              3       ✅ Accessible
  2   fabrikam          Customer          5       ✅ Accessible
  3   contoso           Customer          —       ❌ Auth error
─────────────────────────────────────────────────────
  2 of 3 orgs accessible. 1 requires authentication.
```

> **contoso** is not accessible. Try: `Azure: Sign In to Tenant` →
> enter `contoso.onmicrosoft.com` (or ask your contact for the tenant domain).
>
> Which org would you like to use? Reply with the name or number.

---

## For Project Managers

## Example 8 — Sprint health: end-of-sprint status report

### Prompt

> Show me all work items in the current sprint for the "Platform" team that have no
> story points. Group them by type.

### What happens

1. `ado-sprints-capacity` skill activates.
2. Lists active iteration for the Platform team via `work`.
3. Queries `wit_backlog` filtered to the current iteration path.
4. Filters items where `Story Points` is null or 0.
5. Returns a grouped table.

### Result

| Type | ID | Title | Assigned To |
|---|---|---|---|
| User Story | 1042 | Add MFA to login flow | (unassigned) |
| Bug | 1058 | Session token not refreshed | Alice Martin |
| Task | 1071 | Write ADR for auth service | Bob Nguyen |

> 3 unestimated items found in sprint "Sprint 12". Assign story points via:
> "Set story points on #1042 to 5."

---

## Example 2 — Pipeline triage: find what broke the build

### Prompt

> The last build on the `main` branch of `api-gateway` failed. Show me the errors.

### What happens

1. `ado-pipelines` skill activates.
2. Fetches latest build for `api-gateway` main branch via `pipelines_build`.
3. Retrieves the failing task log via `pipelines_build_log`.
4. Extracts and summarises error lines.

### Result

**Build #456 — FAILED** (triggered 10 min ago, 2m 14s)

Failed step: `dotnet test`

```
error: Test run failed.
  FAILED  AuthServiceTests.TokenExpiry (0.23s)
    System.UnauthorizedAccessException: Token expired before validation
    at AuthService.ValidateToken() line 87
```

> 1 test failure in `AuthServiceTests`. Linked work item suggestion:
> "Create a bug for this failure." — would you like me to do that?

---

## Example 3 — Code review: list my open PRs

### Prompt

> Show me all open pull requests assigned to me as reviewer in the `backend` repository.

### What happens

1. `ado-pull-requests` skill activates.
2. Calls `repo_pull_request` with reviewer filter.
3. Returns a summary table with PR status, conflicts, and thread count.

### Result

| PR | Title | Author | Branch | Threads | Status |
|---|---|---|---|---|---|
| #89 | feat: add Redis cache layer | Carlos Silva | feature/redis | 3 open | Ready |
| #91 | fix: null ref in OrderService | Alice Martin | fix/null-order | 0 | Draft |

> 2 PRs awaiting your review. To approve #89: "Approve PR #89 with comment 'LGTM'."

---

## Example 4 — Work item creation: new bug from a build failure

### Prompt

> Create a bug titled "Session token not refreshed — AuthService line 87" in the
> Platform project, assign to Alice Martin, link to user story #42, and mark it P1.

### What happens

1. `ado-work-items` skill activates.
2. Creates the bug via `wit_work_item_write` with title, priority, and area.
3. Assigns the work item.
4. Links to #42 via `wit_work_item_link_write` (Parent relation).

### Result

> Bug **#1072** created successfully.
>
> - Title: Session token not refreshed — AuthService line 87
> - Assigned to: Alice Martin
> - Priority: 1 (P1)
> - Linked to: #42 (Parent)
> - State: New

---

## Example 5 — Wiki: write an Architecture Decision Record

### Prompt

> Write an ADR for our decision to use Redis for session caching. Title:
> "ADR-007 Redis for session caching". Put it under the Architecture wiki, page
> path: Architecture/ADRs/ADR-007.

### What happens

1. `ado-wiki` skill activates.
2. Upserts the page via `wiki_upsert_page` at the specified path.
3. Returns the new page URL.

### Result

> Wiki page created: **Architecture/ADRs/ADR-007 Redis for session caching**
> URL: https://dev.azure.com/YOUR_ORG/Platform/_wiki/wikis/Platform.wiki/...
>
> Page content written (ADR template with context, decision, consequences).

---

## Example 6 — Search: find all usages of a class across repos

### Prompt

> Find all files that reference `TokenService` in our Azure DevOps repositories.

### What happens

1. `ado-search` skill activates.
2. Calls `search_code` with query `TokenService`.
3. Returns matches grouped by repository and file.

### Result

| Repository | File | Line | Match |
|---|---|---|---|
| api-gateway | src/Auth/AuthService.cs | 87 | `var svc = new TokenService(config)` |
| identity-service | tests/TokenServiceTests.cs | 23 | `TokenService svc = fixture.Create()` |
| shared-lib | src/Interfaces/ITokenService.cs | 5 | `public interface ITokenService` |

---

## Example 7 — Test plans: check test results for latest release build

### Prompt

> What is the test pass rate for the latest build of pipeline `release-2.0`?

### What happens

1. `ado-test-plans` skill activates.
2. Fetches latest build ID via `pipelines_build`.
3. Calls `testplan_show_test_results_from_build_id`.
4. Summarises pass/fail/skipped counts.

### Result

**Build #512 — release-2.0 pipeline**

| Suite | Total | Passed | Failed | Skipped | Pass rate |
|---|---|---|---|---|---|
| API Integration | 145 | 142 | 3 | 0 | 97.9% |
| Unit Tests | 312 | 312 | 0 | 0 | 100% |
| E2E Smoke | 18 | 16 | 0 | 2 | 88.9% |

> 3 integration test failures. Show failed tests? — "Yes, list the failing test cases."

---

---

# Project Manager Examples

## For Project Managers

---

## Example 8 — Sprint health: end-of-sprint status report

### Prompt

> Give me a sprint health report for the "Platform" team for Sprint 12.
> I need: total committed vs completed points, remaining open items, and any items
> that slipped to the next sprint.

### What happens

1. `ado-sprints-capacity` skill activates for the iteration overview.
2. `ado-work-items` skill queries `wit_backlog` for Sprint 12 items grouped by state.
3. Compares completed (Done/Closed) vs committed (all items in the sprint) story points.
4. Identifies items still in Active/New state as slippage candidates.

### Result

**Sprint 12 — Platform Core — Health Report**

| Metric | Value |
|---|---|
| Committed story points | 42 |
| Completed story points | 35 |
| Completion rate | 83% |
| Items completed | 11 / 14 |
| Items slipped | 3 |

**Slipped items (still open at sprint end):**

| ID | Type | Title | Points | Assignee |
|---|---|---|---|---|
| 1042 | Story | Add MFA to login flow | 5 | Alice Martin |
| 1058 | Bug | Session token not refreshed | 2 | (unassigned) |
| 1071 | Task | Write ADR for auth service | — | Bob Nguyen |

> Slipped items: move to Sprint 13?
> "Move items #1042, #1058, #1071 to Sprint 13."

---

## Example 9 — Team capacity planning: set up a new sprint

### Prompt

> Set up Sprint 13 for the Platform Core team. It runs from June 9 to June 22.
> Alice has 1 day off, Bob is full. Also move the 3 slipped items from Sprint 12.

### What happens

1. `ado-sprints-capacity` skill creates the iteration via `work_iteration_write`.
2. Sets capacity per member via `work_capacity_write` (Alice: adjusted, Bob: full).
3. `ado-work-items` skill calls `wit_work_item_write` to update iteration path on #1042, #1058, #1071.

### Result

> **Sprint 13 created** (June 9 – June 22, 10 working days)
>
> Capacity set:
> - Alice Martin — 6h/day, 1 day off → 54h available
> - Bob Nguyen — 7h/day, 0 days off → 70h available
> - Team total → 124h available
>
> Work items #1042, #1058, #1071 moved to Sprint 13.

---

## Example 10 — Release readiness: go/no-go checklist

### Prompt

> We are planning to release v2.0 next week. Give me a go/no-go status:
> open P1 bugs, any failing pipelines on the release branch, and test pass rate
> for the release-2.0 pipeline.

### What happens

1. `ado-work-items` skill runs a WIQL query via `wit_query` for open bugs with Priority=1
   in the Platform project.
2. `ado-pipelines` skill fetches the latest build on the `release/2.0` branch.
3. `ado-test-plans` skill calls `testplan_show_test_results_from_build_id` for that build.
4. Results are assembled into a go/no-go summary.

### Result

**v2.0 Release — Go/No-Go Assessment**

| Check | Status | Detail |
|---|---|---|
| Open P1 bugs | ⚠ 2 open | #1058 (unassigned), #1063 (Alice) |
| Release branch build | ✅ Passing | Build #512 — succeeded 2h ago |
| Test pass rate | ✅ 98.9% | 3 failures in integration suite |

> **Recommendation: NO-GO** — 2 P1 bugs must be resolved before release.
> Assign #1058: "Assign bug #1058 to Alice Martin and set due date to June 10."

---

## Example 11 — Backlog grooming: prioritise and assign unrefined items

### Prompt

> Show me all user stories in the Platform backlog that have no acceptance criteria,
> no story points, and are not yet assigned to a sprint. Sort by priority.

### What happens

1. `ado-work-items` skill calls `wit_query` with WIQL filtering on type=User Story,
   state=New, IterationPath not set, StoryPoints=null.
2. Returns results ordered by Priority field.

### Result

| Priority | ID | Title | Assigned To |
|---|---|---|---|
| 1 | 1081 | Implement SSO for mobile app | (unassigned) |
| 2 | 1085 | Add export to Excel on reports | (unassigned) |
| 2 | 1089 | Notification preferences centre | Bob Nguyen |
| 3 | 1092 | Dark mode support | (unassigned) |

> 4 unrefined stories found. To add acceptance criteria to #1081:
> "Update story #1081 description with acceptance criteria: [your criteria here]."

---

## Example 12 — Stakeholder update: weekly progress summary

### Prompt

> Write a brief weekly progress update for my stakeholders covering the Platform project.
> Include: items completed this week, active pipeline status, and any blockers.

### What happens

1. `ado-work-items` skill queries `wit_query` for items moved to Done in the last 7 days.
2. `ado-pipelines` skill fetches latest build statuses for all Platform pipelines.
3. `ado-work-items` queries for items tagged "blocker" or in Blocked state.
4. The assistant drafts the update from the structured data.

### Result

> **Platform Project — Weekly Update (Week of June 2–8)**
>
> **Completed this week (8 items):**
> - ✅ #1044 — Redis cache layer deployed to staging
> - ✅ #1051 — API rate limiting implemented
> - ✅ #1053 — Onboarding flow redesign — UX sign-off done
> *(+ 5 tasks)*
>
> **Pipeline health:**
> - `api-gateway` main — ✅ passing
> - `identity-service` main — ✅ passing
> - `release-2.0` — ⚠ 3 integration test failures (being investigated)
>
> **Blockers:**
> - #1058 — Session token refresh bug — unassigned, P1

---

## Example 13 — Cross-project search: find all work items mentioning a feature

### Prompt

> Search across all projects for work items that mention "SSO" or "single sign-on".
> I want to know if other teams are working on the same thing.

### What happens

1. `ado-search` skill activates.
2. Calls `search_workitem` with query `"SSO OR single sign-on"` without a project filter
   (searches org-wide).
3. Returns matches grouped by project.

### Result

| Project | ID | Type | Title | State |
|---|---|---|---|---|
| Platform | 1081 | Story | Implement SSO for mobile app | New |
| Mobile App | 234 | Epic | Single Sign-On — Phase 2 | Active |
| Finance Modules | 88 | Task | Evaluate SSO provider options | Done |

> 3 items across 2 active projects. The Mobile App team has an active Epic (#234) — consider
> linking work items or scheduling a cross-team sync.
> "Link story #1081 to epic #234 as Related."

---

## Example 14 — Iteration planning: check team velocity trend

### Prompt

> What was the Platform Core team's velocity for the last 4 sprints? I need to estimate
> how much we can commit to Sprint 13.

### What happens

1. `ado-sprints-capacity` skill fetches past iterations via `work`.
2. `ado-work-items` skill queries `wit_query` for items completed (state=Done/Closed)
   per iteration, summing story points.
3. Calculates average velocity and suggests a commitment range.

### Result

**Platform Core — Velocity (last 4 sprints)**

| Sprint | Committed | Completed | Velocity |
|---|---|---|---|
| Sprint 9 | 38 | 36 | 36 |
| Sprint 10 | 40 | 38 | 38 |
| Sprint 11 | 45 | 40 | 40 |
| Sprint 12 | 42 | 35 | 35 |

> **Average velocity: 37 points.** Recommended Sprint 13 commitment: **34–39 points**
> (±5% buffer for Alice's day off).

---

## Example 16 — Project committee: generate a PowerPoint deck from ADO data

### Prompt

> I have a release committee call tomorrow for v2.0. Pull the data from ADO and prepare
> a PowerPoint presentation: sprint health, go/no-go status, key achievements, risks,
> and the next sprint plan.

### What happens

1. `ado-pm-reporting` skill activates.
2. Runs **Workflow A** (sprint health) — committed vs completed points, slipped items.
3. Runs **Workflow B** (go/no-go) — open P1 bugs, build status, test pass rate.
4. Runs **Workflow D** (stakeholder update) — top completed items this week.
5. Runs **Workflow C** (velocity) — last 4 sprints, Sprint 13 recommendation.
6. Assembles the 9-slide outline from the collected data.
7. In **M365 Copilot**: hands the outline to `create_presentation` with the corporate
   template → produces a `.pptx` saved to OneDrive.
   In **VS Code Copilot**: outputs the formatted Markdown outline for manual paste into
   PowerPoint Copilot sidebar.

### Result (M365 Copilot)

> **PowerPoint created:** `Platform v2.0 Release Committee — June 2026.pptx`
> Saved to: OneDrive / Sites / Platform / Shared Documents
>
> **9 slides generated:**
> 1. Title — Platform Project — Release Committee · June 2026
> 2. Agenda
> 3. Sprint 12 Summary (83% completion, 3 slipped, build ✅, tests 98.9%)
> 4. Key Achievements (Redis cache, rate limiting, onboarding redesign)
> 5. Risks & Blockers (2 open P1 bugs with owners and mitigations)
> 6. Velocity & Forecast (avg 37 pts → recommend 34–39 for Sprint 13)
> 7. Next Sprint — Sprint 13 (June 9–22, 124h capacity, top 3 items)
> 8. Decisions Needed (assign owner for #1063, scope defer for dark mode)
> 9. Q&A
>
> Share the file: "Send the deck to the committee distribution list."

### Result (VS Code Copilot — slide outline)

```markdown
# Platform Project — Release Committee | June 2026

## Sprint 12 Summary
- Committed: 42 pts | Completed: 35 pts | Rate: 83%
- Build: ✅ Passing | Tests: 98.9% pass rate
- Slipped: 3 items → moving to Sprint 13

## Key Achievements
- Redis cache layer deployed to staging
- API rate limiting implemented
- Onboarding flow redesign — UX sign-off complete

## Risks & Blockers
| # | Title | Owner | Mitigation |
|---|---|---|---|
| 1058 | Session token not refreshed | Alice Martin | Fix due June 10 |
| 1063 | Null ref in OrderService | (unassigned) | Needs owner |

## Velocity & Forecast
Avg velocity: 37 pts — Recommended Sprint 13 commitment: 34–39 pts

## Next Sprint — Sprint 13 (June 9–22)
- Capacity: 124h | Top items: SSO mobile, Export Excel, Notification prefs

## Decisions Needed
- Assign owner for bug #1063 (P1, unassigned)
- Approve: defer dark mode (#1092) to Sprint 14?
```

> Paste this outline into PowerPoint → Copilot sidebar → "Create presentation from outline".

---

## Example 15 — Wiki: publish sprint retrospective notes

### Prompt

> Publish our Sprint 12 retrospective to the wiki. Page path: Retrospectives/Sprint-12.
> What went well: Redis rollout was smooth, CI pipeline now under 3 minutes.
> What to improve: P1 bugs need an owner within 24h — add this as a team agreement.
> Action items: Bob to document the on-call rotation by June 15.

### What happens

1. `ado-wiki` skill activates.
2. Formats the content as a structured Markdown retrospective page.
3. Calls `wiki_upsert_page` at `Retrospectives/Sprint-12`.

### Result

> Wiki page created: **Retrospectives/Sprint-12**
>
> Content published with sections: What went well, What to improve, Team agreements,
> Action items (owner + due date).
> URL: https://dev.azure.com/YOUR_ORG/Platform/_wiki/wikis/Platform.wiki/...
