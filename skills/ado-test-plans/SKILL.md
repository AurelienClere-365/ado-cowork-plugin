---
name: ado-test-plans
description: >
  Use when the user asks about Azure DevOps test plans, test suites, test cases, or test
  execution results. "show test results for the last build", "create a test plan for
  Sprint 12 regression", "add a test case for the login flow", "what is the pass rate for
  pipeline release-2.0", "create a test suite for authentication scenarios",
  "list all test plans in the Platform project", "write a test case for the MFA feature",
  "show failed test cases from build #512", "how many tests are in the smoke suite"
license: MIT
metadata:
  version: "1.0"
---

# ADO Test Plans

Manage Azure DevOps test plans, test suites, and test cases. Read test execution results
from pipeline builds and create structured test artefacts.

## When to use

- User wants to see test results for a build or pipeline run
- User wants to create a new test plan or test suite
- User wants to create or update test cases
- User wants to know the pass/fail rate for a release or sprint
- User is preparing a release sign-off and needs test coverage evidence

## MCP tools used

| Tool | Purpose |
|---|---|
| `testplan` | List test plans and test suites in a project |
| `testplan_show_test_results_from_build_id` | Get test execution results for a build |
| `testplan_test_plan_write` | Create or update a test plan |
| `testplan_test_suite_write` | Create or update a test suite within a plan |
| `testplan_test_case_write` | Create or update a test case |

## Workflow

### Getting test results for a build

1. Identify: build ID (if known) or pipeline name + branch.
2. If only pipeline name is known, use `ado-pipelines` skill to get the build ID first.
3. Call `testplan_show_test_results_from_build_id(buildId)` — returns pass/fail/skipped
   counts per test suite, and the list of failed test cases with error messages.
4. Present the **Test Results Summary** table.
5. List failing tests in the **Failing Tests** table.

### Listing test plans

1. Call `testplan(project)` — returns all test plans with ID, name, state, iteration,
   and suite count.
2. Present the **Test Plan List** table.

### Creating a test plan

1. Extract: project, plan name, and iteration path.
2. Call `testplan_test_plan_write(project, name, iteration)`.
3. Confirm with the new plan ID.

### Creating a test suite

1. Identify the parent test plan ID.
2. Extract: suite name, suite type (static, requirement-based, query-based).
3. Call `testplan_test_suite_write(planId, suiteName, suiteType)`.
4. Confirm with the new suite ID.

### Creating a test case

1. Identify the test suite or plan to add the test case to.
2. Extract: test case title, steps (action + expected result pairs), and any associated
   work item ID.
3. Call `testplan_test_case_write(suiteId, title, steps)`.
4. Confirm with the new test case ID.

## Output Format

### Test Results Summary

**Build #512 — release-2.0 pipeline**

| Suite | Total | Passed | Failed | Skipped | Pass rate |
|---|---|---|---|---|---|
| API Integration | 145 | 142 | 3 | 0 | 97.9% |
| Unit Tests | 312 | 312 | 0 | 0 | 100% |
| E2E Smoke | 18 | 16 | 0 | 2 | 88.9% |
| **Total** | **475** | **470** | **3** | **2** | **98.9%** |

### Failing Tests

| Test Case | Suite | Error |
|---|---|---|
| TokenExpiry_ShouldReturn401 | API Integration | UnauthorizedAccessException: Token expired |
| Login_WithExpiredMFA | API Integration | Assert.Equal failed: expected 401 got 200 |
| OrderService_NullRef | API Integration | NullReferenceException at OrderService.cs:87 |

### Test Plan List

| ID | Plan | Iteration | State | Suites |
|---|---|---|---|---|
| 5 | Sprint 12 Regression | Sprint 12 | Active | 4 |
| 3 | Release 2.0 Sign-off | Release 2.0 | Active | 7 |
| 1 | Sprint 11 Regression | Sprint 11 | Inactive | 3 |

## Notes

- Test results are associated with a build via the build definition ID and build number.
  If the user gives a pipeline name instead of a build ID, resolve it via `ado-pipelines`
  skill first.
- When creating test steps, each step has an **Action** (what the tester does) and an
  **Expected Result** (what should happen). Prompt the user for both if not provided.
- `testplan_test_case_write` creates a work item of type Test Case in addition to adding
  it to the suite — both happen in one call.

## Active context

This skill respects the session context set by the `ado-context` skill.
- If `activeProject` is set, use it automatically as the `project` parameter — do not
  ask the user to re-specify it.
- If no context is set and a project is required, invoke Workflow E of `ado-context`
  to resolve it (list projects, ask user to pick, then proceed).
