# Privacy Policy — ADO Cowork Plugin

**Last updated: 2026**

## What data this plugin processes

The ADO Cowork Plugin provides AI assistant skills that call the Azure DevOps MCP server
on your behalf. Queries and responses travel between your AI assistant and your own
Azure DevOps organisation.

- **No personal data is collected, stored, or transmitted by the plugin authors.**
- When using the Local MCP mode (Option B), all traffic stays between your machine and
  your Azure DevOps organisation — the plugin authors have zero visibility.
- When using the Azure Connector (Option C), the MCP adapter runs inside your own Azure
  subscription. The authors have no access to your deployment, logs, or queries.

## What the plugin does NOT do

- It does not transmit data to any third-party service other than the AI assistant
  you are already using (GitHub Copilot, Claude, etc.) and your Azure DevOps organisation.
- It does not log queries, responses, or work item content.
- It does not share data outside your organisation's Azure DevOps tenant.

## PAT tokens and credentials

When using Local MCP mode, a Personal Access Token (PAT) is stored in your local
`mcp.json` configuration file. This file is excluded from version control via `.gitignore`.
**Never commit your PAT to a repository.**

For the Azure Connector mode, credentials are stored in Azure Key Vault and injected via
OAuthPluginVault — they are never written to disk or included in source code.

## Third-party AI assistants

When you use this plugin with an AI assistant (GitHub Copilot, Claude Code, Cursor, etc.),
your queries are subject to that assistant's own privacy policy. The plugin authors have
no control over, or access to, those services.
