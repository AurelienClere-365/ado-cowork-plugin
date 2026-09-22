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

## [1.2.0] — 2026-09-22

### Added
- `setup-auth.ps1` — automates the OAuthPluginVault setup for M365 Copilot (Option C):
  creates/reuses the Azure AD app registration, adds the `user_impersonation` delegated
  permission, grants admin consent, generates a client secret, patches `manifest.json`,
  bumps the version, updates `CHANGELOG.md`, and re-runs `package.ps1`. The Teams
  Developer Portal OAuth client registration step (6b) remains manual — no public API
  exists for it.
- Client secret expiry reminder printed by `setup-auth.ps1` and documented in
  `SECURITY.md` under "Secret rotation".

### Changed
- `OAuthPluginVault` is now documented as the **required** baseline authentication for
  Option C (M365 Copilot), not an optional upgrade from `authorization.type: None`.
- `SECURITY.md` — PAT-based access is now explicitly scoped as a legacy/edge-case
  fallback only, used solely when an organisation's policy disallows Azure AD auth.

---

## [Unreleased]

- Placeholder for next changes
