# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x (current) | Yes |

## Reporting a vulnerability

**Do not open a public GitHub Issue for security vulnerabilities.**

Please report security issues by emailing the maintainer directly:

- Aurelien Clere — via [LinkedIn](https://www.linkedin.com/in/aurelien-clere/)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix (optional)

We will acknowledge receipt within 72 hours and aim to release a fix within 14 days
for confirmed critical issues.

## Security design

This plugin does not handle credentials directly. Depending on the deployment mode:

### Local MCP (Option B)

- Authentication uses your **Azure AD session** managed by VS Code — no PAT needed.
- If your organisation restricts the native MCP endpoint to PAT-based access, store the
  PAT only in your local `mcp.json` and ensure that file is excluded from version control
  via `.gitignore`. Never commit a PAT.

### Azure Connector (Option C)

Azure DevOps exposes a built-in MCP endpoint at `https://mcp.dev.azure.com/{orgName}`.
No custom server or Key Vault is required.

- **OAuthPluginVault** — M365 Copilot handles token acquisition via the standard plugin
  OAuth flow. The token is scoped to your Azure AD tenant; anonymous requests are rejected.
- **No secrets in source code** — `manifest.json` only contains the org-specific URL and
  the OAuthPluginVault reference ID assigned by M365 Copilot admin centre.
- The built-in endpoint enforces Azure AD authentication at the platform level — no
  additional ingress rules or Easy Auth configuration needed.

## Least-privilege PAT scopes (fallback / org policy)

If your organisation requires PAT-based access instead of Azure AD, grant only the
scopes your use case requires. The full set needed for all 9 skills:

| Scope | Permission | Required by |
|---|---|---|
| Work Items | Read & Write | ado-work-items, ado-sprints-capacity, ado-search |
| Code | Read & Write | ado-repositories, ado-pull-requests, ado-search |
| Build | Read & Execute | ado-pipelines |
| Test Plans | Read & Write | ado-test-plans |
| Wiki | Read & Write | ado-wiki, ado-search |
| Project and Team | Read | ado-project-discovery |

If you use only read-only skills, remove the Write scopes.
