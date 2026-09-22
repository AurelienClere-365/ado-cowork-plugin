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

- **OAuthPluginVault is required** — this is the baseline authentication for Option C,
  not an optional upgrade. `manifest.json` ships with `authorization.type:
  OAuthPluginVault` by default. M365 Copilot handles token acquisition via the standard
  plugin OAuth flow; the token is scoped to your Azure AD tenant and anonymous requests
  are rejected.
- **No secrets in source code** — `manifest.json` only contains the org-specific URL and
  the OAuthPluginVault reference ID assigned by M365 Copilot admin centre. The Azure AD
  app registration's client secret is never committed; it lives only in Azure AD and the
  Teams Developer Portal OAuth client registration.
- The built-in endpoint enforces Azure AD authentication at the platform level — no
  additional ingress rules or Easy Auth configuration needed.
- Use `setup-auth.ps1` to provision the Azure AD app registration, permission, and
  client secret instead of the Azure Portal UI — see README.md Step 6.

## Secret rotation

The Azure AD app registration created for `OAuthPluginVault` (README Step 6a) uses a
client secret with an expiry date. If the secret lapses, `mcp.dev.azure.com` silently
rejects every user's OAuth token refresh and the plugin stops working tenant-wide with no
obvious error to the end user beyond *"I don't have a way to connect to Azure DevOps from
here"*.

- `setup-auth.ps1 -SecretExpiryMonths <n>` (default 12) prints the exact expiry date when
  the secret is created or rotated — set a calendar reminder before that date.
- To rotate: re-run `setup-auth.ps1` (it reuses the existing app registration and issues a
  new secret), or create a new client secret manually in **Azure Portal → App
  registrations → ADO Cowork Plugin → Certificates & secrets**, then update the Teams
  Developer Portal OAuth client registration (6b) with the new secret value. The
  `referenceId` in `manifest.json` does not change when only the secret is rotated.
- Prefer shorter-lived secrets (6–12 months) over long-lived ones — a rotation reminder
  that fires is much cheaper than an unplanned outage.

## Least-privilege PAT scopes (legacy / edge-case fallback only)

PAT-based access is **not the recommended path** for this plugin. It exists only for
organisations whose policy disallows Azure AD-based authentication (Options B and C both
use Azure AD by default and require no PAT). If your organisation's policy forces
PAT-based access instead, grant only the scopes your use case requires. The full set
needed for all 11 skills:

| Scope | Permission | Required by |
|---|---|---|
| Work Items | Read & Write | ado-work-items, ado-sprints-capacity, ado-search |
| Code | Read & Write | ado-repositories, ado-pull-requests, ado-search |
| Build | Read & Execute | ado-pipelines |
| Test Plans | Read & Write | ado-test-plans |
| Wiki | Read & Write | ado-wiki, ado-search |
| Project and Team | Read | ado-project-discovery |

If you use only read-only skills, remove the Write scopes.
