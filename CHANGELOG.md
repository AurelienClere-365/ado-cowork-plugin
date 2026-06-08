# Changelog

All notable changes to the ADO Cowork Plugin are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-06-08

### Added
- Initial release by Aurelien Clere
- 9 ASKILL-validated skills covering all ~37 Azure DevOps standard MCP tools:
  - `ado-project-discovery`, `ado-work-items`, `ado-sprints-capacity`
  - `ado-pipelines`, `ado-repositories`, `ado-pull-requests`
  - `ado-test-plans`, `ado-search`, `ado-wiki`
- End-to-end usage examples across sprint planning, pipeline triage, code review,
  and test management (`EXAMPLES.md`)
- Support for GitHub Copilot, Claude Code, Cursor, Continue.dev, Gemini CLI, JetBrains Junie
- Three deployment modes: skills-only, local MCP (stdio), Azure Connector (M365 Copilot)
- Azure DevOps pipeline (`azure-pipelines.yml`) for ASKILL validation
- ASKILL validation + packaging script (`package.ps1`)
- MIT License, Privacy Policy, Contributing guide, Security policy

---

## [Unreleased]

- Placeholder for next changes
