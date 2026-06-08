---
name: ado-pipelines
description: >
  Use when the user asks about Azure DevOps build or release pipelines, CI/CD status,
  build logs, pipeline definitions, artifacts, or wants to trigger a run.
  "what failed in the last build", "show me the build log for pipeline api-gateway",
  "trigger a build on the main branch", "list all pipeline definitions in the Platform project",
  "download the artifact from build #456", "why did the CI fail", "create a new pipeline",
  "show pipeline run history for release-2.0", "how long does the build take on average",
  "queue a new run with custom variables"
license: MIT
metadata:
  version: "1.0"
---

# ADO Pipelines

Read pipeline status, inspect build logs, trigger runs, manage pipeline definitions,
and download artifacts for Azure DevOps CI/CD pipelines.

## When to use

- User wants to know if a build passed or failed
- User wants to read error output from a failing build
- User wants to trigger (queue) a new pipeline run
- User wants to list available pipeline definitions in a project
- User wants to download or inspect a pipeline artifact
- User wants to create or update a pipeline definition (YAML)

## MCP tools used

| Tool | Purpose |
|---|---|
| `pipelines_build` | List builds / get the latest build for a pipeline or branch |
| `pipelines_build_log` | Retrieve the log output of a specific build task |
| `pipelines_run` | Queue (trigger) a new pipeline run |
| `pipelines_write` | Create or update a pipeline definition |
| `pipelines_definition` | Get the full YAML definition of a pipeline |
| `pipelines_artifact` | List or download artifacts produced by a build |

## Workflow

### Getting the latest build status

1. Identify: project name and either pipeline name or repository+branch.
2. Call `pipelines_build(project, pipelineName, branch)` — returns the latest N builds
   with status (succeeded, failed, running, cancelled) and duration.
3. Present the **Build Status** table.

### Reading build logs (failure triage)

1. Call `pipelines_build` to get the failing build ID.
2. Call `pipelines_build_log(buildId)` — returns the structured task timeline with each
   step's result (succeeded / failed / skipped) and log URL.
3. Focus on the first failed step. Extract error lines (lines containing `error:`,
   `Error`, `FAILED`, `Exception`).
4. Present the **Failure Summary** with the failing step name and extracted error lines.
5. Offer to create a bug work item from the failure.

### Triggering a run

1. Identify: project, pipeline name/ID, branch, and any variable overrides.
2. Call `pipelines_run(project, pipelineId, branch, variables)`.
3. Confirm with the new run ID and a link to the run page.

### Listing pipeline definitions

1. Call `pipelines_definition(project)` — returns all defined pipelines with ID, name,
   folder, and default branch.
2. Present as a **Pipeline Definitions** table.

### Downloading an artifact

1. Identify build ID and artifact name.
2. Call `pipelines_artifact(buildId, artifactName)` — returns the artifact download URL
   or file list.
3. Present the artifact content or URL.

## Output Format

### Build Status

| Build # | Pipeline | Branch | Status | Duration | Started |
|---|---|---|---|---|---|
| 456 | api-gateway | main | Failed | 2m 14s | 10 min ago |
| 455 | api-gateway | main | Succeeded | 2m 07s | 2h ago |
| 454 | api-gateway | feature/redis | Succeeded | 1m 58s | 4h ago |

### Failure Summary

**Build #456 — api-gateway / main — FAILED**

| Step | Result | Duration |
|---|---|---|
| Restore NuGet packages | Succeeded | 0m 23s |
| Build | Succeeded | 0m 51s |
| Run unit tests | **Failed** | 0m 58s |

```
error: Test run failed.
  FAILED  AuthServiceTests.TokenExpiry (0.23s)
    System.UnauthorizedAccessException: Token expired before validation
    at AuthService.ValidateToken() line 87
```

### Pipeline Definitions

| ID | Name | Folder | Default Branch |
|---|---|---|---|
| 12 | api-gateway | \Backend | main |
| 17 | identity-service | \Backend | main |
| 23 | release-2.0 | \Release | release/2.0 |

## Notes

- `pipelines_build` returns builds in reverse-chronological order. To get a specific build,
  pass the build ID directly.
- Log lines can be very long. Truncate to the first 50 error lines; offer to show more
  if the user asks.
- When triggering a run, always confirm the branch and variables with the user before
  calling `pipelines_run` — a misfire on a release pipeline can be disruptive.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
