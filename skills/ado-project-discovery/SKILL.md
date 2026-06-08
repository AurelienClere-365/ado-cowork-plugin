---
name: ado-project-discovery
description: >
  Use when the user asks about Azure DevOps projects, teams, organisation structure, or wants
  to list what projects or teams exist. "list my ADO projects", "what projects are in my
  organisation", "show teams in the Platform project", "which team owns the backend workload",
  "find the project for the mobile app", "how many teams does the Finance project have",
  "who is in the Cloud Infra team"
license: MIT
metadata:
  version: "1.0"
---

# ADO Project Discovery

List and explore Azure DevOps projects and team structure across an organisation.

## When to use

- User wants to know which projects exist in their ADO organisation
- User needs to find the right project before creating work items or browsing repos
- User wants to see the teams inside a project
- User is onboarding and needs an overview of the organisation structure

## MCP tools used

| Tool | Purpose |
|---|---|
| `core_list_projects` | List all projects in the organisation |
| `core_list_project_teams` | List all teams within a specific project |

## Workflow

1. **List projects.** Call `core_list_projects` to get the full project list with IDs, names,
   state (active/deleted), and visibility.

2. **Filter if needed.** If the user named a specific project, match by name (case-insensitive).
   If ambiguous, present the full list and ask the user to confirm.

3. **List teams (if asked).** Call `core_list_project_teams(projectId)` to get team names,
   team IDs, and descriptions. Present as a flat table.

4. **Surface next steps.** After listing, suggest follow-up actions the user can take:
   browse repos, create work items, check pipelines in the project.

## Output Format

### Projects

| Project | State | Visibility | ID |
|---|---|---|---|
| Platform | Active | Private | abc-123 |
| Mobile App | Active | Private | def-456 |
| Finance Modules | Active | Private | ghi-789 |

### Teams in a project

| Team | Description |
|---|---|
| Platform Core | Owns backend services and infra |
| Platform QA | Quality assurance and test automation |
| Platform DevOps | Pipeline and environment management |

## Notes

- Use the project name and ID returned here as inputs to other skills
  (`ado-work-items`, `ado-pipelines`, `ado-repositories`, etc.).
- If the organisation has a large number of projects (>20), ask the user for a keyword
  to filter before presenting results.
- `core_list_projects` returns projects across all process templates (Agile, Scrum, CMMI).

## Active context

This skill also powers the implicit context resolution used by all other skills.
- After listing and selecting a project here, the result can be passed to `ado-context`
  to store it as the session-wide active project.
- Suggest: "To avoid specifying the project every time, say: 'set active project Platform'."
