---
name: ado-context
description: >
  Use when the user wants to select, switch, or filter an Azure DevOps organisation or
  project before running other commands. This skill establishes the active session context
  (org + project) that all other ADO Cowork skills consume automatically.
  "use org contoso", "switch to project Platform", "set active project",
  "change organisation", "which project am I in", "select a project", "list my projects",
  "show available organisations", "filter projects by name", "use the Finance project",
  "I want to work on the Mobile App project", "change ADO context", "what is my current org",
  "switch ADO organisation", "pick a project from the list",
  "add customer organisation", "I have guest access to a customer tenant",
  "register a new ADO org", "add org contoso", "access client DevOps",
  "I am a guest in the Fabrikam organisation", "show all my organisations",
  "which orgs do I have access to", "org dashboard", "check org access"
license: MIT
metadata:
  version: "1.1"
---

# ADO Context — Organisation & Project Selection

Establishes the active **organisation** and **project** for the current session so that
every subsequent skill call uses them automatically — no need to re-specify the project
on every prompt.

Supports **multiple organisations across different Azure AD tenants**, including customer
organisations where you have been added as a guest or external collaborator.

---

## When to use

- User is starting a session and hasn't specified which org/project to work in
- User wants to switch to a different project mid-session
- User has multiple ADO organisations (their own + customer tenants) and needs to pick one
- User wants to add a new customer organisation they have guest access to
- User wants to see an overview of all configured organisations and their accessibility
- A skill is asking for a project parameter and none is set
- User asks "which project am I in?" or "change to project X"

---

## Concepts

### Organisation vs Project

| Term | What it is | Example |
|---|---|---|
| **Organisation** | The ADO tenant — top level. One MCP server entry per org. | `contoso`, `fabrikam` |
| **Project** | A team project inside an org. One org can have dozens. | `Platform`, `Mobile App`, `Finance` |

### Home org vs Customer / Guest org

You can have access to multiple Azure DevOps organisations across different Azure AD tenants:

| Type | What it means | Auth |
|---|---|---|
| **Home org** | Your own Azure AD tenant — the one your VS Code account belongs to | Automatic via VS Code Azure session |
| **Customer org** | A client's Azure AD tenant — you were added as a **guest user** or **external collaborator** | VS Code prompts for the customer tenant on first access; subsequent calls reuse the cached token |
| **Partner org** | Another internal org in your own company (different ADO org name, same AAD tenant) | Automatic — same auth as home org |

Each organisation must have **one entry** in `mcp.json` pointing to
`https://mcp.dev.azure.com/{orgName}`. The Azure DevOps MCP server then uses the VS Code
Azure AD session to authenticate — it automatically handles guest-account token exchange
when the org belongs to a different tenant.

### Session context

Once set, the active org + project are stored as session variables and passed silently
to every ADO MCP tool call for the rest of the conversation:

```
activeOrg:       contoso                ← org name (URL segment)
activeMcpServer: ADO-Contoso            ← the mcp.json server key to route tool calls to
activeOrgType:   home | customer        ← informational label
activeProject:   Platform               ← project name
activeProjectId: abc-123-def-456        ← project GUID (from core_list_projects)
```

---

## Workflow A — Select organisation

**Triggers:** "use org X", "change organisation", "switch ADO organisation",
"show my organisations", "list orgs", "which orgs do I have"

1. Present all configured ADO organisations — those are every `mcp.json` server entry
   whose URL starts with `https://mcp.dev.azure.com/`:

   | # | Label | Organisation | Tenant type |
   |---|---|---|---|
   | 1 | ADO-Contoso | contoso | Home |
   | 2 | ADO-Fabrikam | fabrikam | Customer |

   > Label the tenant type based on whether the org name segment matches the user's own
   > AAD tenant. If unknown, show "—" and let the user label it via Workflow F.

2. If the user named an org explicitly, match it (case-insensitive on the org name segment
   or on the mcp.json key label).
3. Confirm the selection:
   > **Active organisation: contoso** (ADO-Contoso · Home tenant)
4. Automatically proceed to Workflow B (project selection) unless the user only asked
   to set the org.

> If only one ADO org is configured, skip this step and go directly to Workflow B.

> If the user names an org that is **not in mcp.json**, do not fail silently — offer
> to register it via Workflow F instead.

---

## Workflow B — List and select project

**Triggers:** "list my projects", "select a project", "use project X",
"switch project", "set active project", "filter projects"

1. Call `core_list_projects` on the active org's MCP server.
2. Present the full project list:

   | # | Project | State | Visibility |
   |---|---|---|---|
   | 1 | Finance Modules | Active | Private |
   | 2 | Mobile App | Active | Private |
   | 3 | Platform | Active | Private |

3. **If the user named a project** — match by name (case-insensitive, partial match allowed).
   If multiple projects match, present only the matches and ask to confirm.
4. **If no project is named** — present the full list and ask the user to pick by name or
   number.
5. Set the session context:
   - `activeProject` = project name
   - `activeProjectId` = project ID (GUID)
6. Confirm: **"Active project set to: Platform (ID: abc-123). All subsequent commands
   will use this project automatically."**

---

## Workflow C — Filter projects by keyword

**Triggers:** "filter projects", "find projects containing X", "search for project"

1. Call `core_list_projects`.
2. Filter the results client-side by the keyword (name contains, case-insensitive).
3. If 1 match — set it automatically and confirm.
4. If 2–5 matches — present and ask user to confirm.
5. If 0 matches — present the full list and ask the user to pick.

---

## Workflow D — Show or reset active context

**Triggers:** "which project am I in", "what is my active context",
"what org am I using", "reset context", "clear project"

**Show context:**

> **Active context:**
> - Organisation: contoso (mcp server: ADO-Contoso)
> - Project: Platform (ID: abc-123-def-456)
>
> All ADO Cowork commands are currently scoped to this project.
> To switch: "use project Mobile App" or "change organisation".

**Reset context:**

Clear `activeOrg`, `activeMcpServer`, `activeProject`, `activeProjectId`.
The next ADO command that needs a project will trigger Workflow B again.

---

## Workflow E — Implicit context resolution (called by other skills)

When another skill needs a `project` parameter and no context is set:

1. Call `core_list_projects` silently.
2. If **1 project exists** — use it automatically, mention it in the response:
   > "Using the only project in this organisation: **Platform**."
3. If **2–5 projects exist** — present the list and ask the user to pick before proceeding.
4. If **>5 projects exist** — ask the user to name the project or use
   "set active project" first.
5. Once resolved, store as session context so subsequent calls don't re-prompt.

---

## Output format — Context confirmation

Always confirm context changes with a clear banner:

```
Active context updated
  Organisation : contoso  (Home tenant)
  MCP server   : ADO-Contoso
  Project      : Platform
  Project ID   : abc-123-def-456

All ADO commands this session will use this project.
To change: "use project [name]" or "change organisation".
```

---

## Workflow F — Register a new customer / guest organisation

**Triggers:** "add org X", "I have guest access to org X", "register customer org",
"add a new ADO organisation", "I am a consultant at client Y",
"access client DevOps", "add customer tenant"

Use this when the user wants to work in an ADO organisation that is **not yet in their
mcp.json** — typically a customer tenant they have been invited to as a guest or
external collaborator.

### Step 1 — Collect the org name

Ask the user for the ADO organisation name. This is the slug that appears in the browser
URL when they open the customer's Azure DevOps:

```
https://dev.azure.com/contoso      →  org name: contoso
https://dev.azure.com/fabrikam-eu  →  org name: fabrikam-eu
```

If the user already gave the org name in their prompt, use it directly.

### Step 2 — Generate the mcp.json snippet

Produce the JSON entry to add to the `servers` block of `mcp.json`:

```jsonc
// Add this entry inside the "servers": { } block of mcp.json
"ADO-Contoso": {
    "url": "https://mcp.dev.azure.com/contoso",
    "type": "http"
}
```

> **Naming convention for the key:** `ADO-{OrgName}` with PascalCase, e.g.
> `ADO-Contoso`, `ADO-FabrikamEu`, `ADO-AdatumEu`.

### Step 3 — Explain where to add it

> **Where to add this entry:**
>
> Open: `%APPDATA%\Code\User\mcp.json`  (Windows)
> or:   `~/.config/Code/User/mcp.json` (macOS / Linux)
>
> Add the snippet inside the `"servers": { }` block, alongside your existing entries.
> Save the file, then run **Developer: Reload Window** in the VS Code command palette
> (Ctrl+Shift+P → Reload Window).

### Step 4 — Explain the guest authentication flow

> **First-time authentication for a guest org:**
>
> When you first call a tool that targets the new org, VS Code may open a browser
> window asking you to sign in with the **customer tenant account** (or confirm your
> guest access). This is a one-time step — VS Code caches the token and subsequent
> calls are silent.
>
> If the browser does not open automatically, run:
> `Azure: Sign In to Tenant` in the command palette and enter the customer tenant ID
> or domain (e.g. `contoso.onmicrosoft.com`).

### Step 5 — Verify access (after reload)

After the user confirms they have added the entry and reloaded VS Code, call
`core_list_projects` on the new server. If successful, show the project list and
offer to set the active project via Workflow B.

If the call fails with an auth error:
> "Authentication failed for org `contoso`. You may need to sign in to the customer
> tenant first. Run: `Azure: Sign In to Tenant` → enter `contoso.onmicrosoft.com`
> (or ask your customer contact for the tenant domain / ID)."

---

## Workflow G — Organisation dashboard (all orgs + access status)

**Triggers:** "show all my organisations", "org dashboard", "check org access",
"which orgs do I have access to", "list all ADO orgs", "org overview"

Shows a real-time snapshot of every configured ADO organisation and whether it is
currently accessible from this session.

### Steps

1. Enumerate all `https://mcp.dev.azure.com/` entries from the user's `mcp.json`.
2. For each org, call `core_list_projects` silently.
3. Present the dashboard:

```
ADO Organisation Dashboard
──────────────────────────────────────────────────────────────
  #   Organisation      MCP server key            Projects   Status
──────────────────────────────────────────────────────────────
  1   contoso           ADO-Contoso                   3       ✅ Accessible
  2   fabrikam          ADO-Fabrikam                  5       ✅ Accessible
  3   contoso           ADO-Contoso                   —       ❌ Auth error
──────────────────────────────────────────────────────────────
  2 of 3 orgs accessible. 1 requires authentication.
```

4. For any org showing ❌:
   > "Organisation `contoso` is not accessible. Possible causes:
   > - Guest invitation has not been accepted yet
   > - Token for the customer tenant has expired — run `Azure: Sign In to Tenant`
   > - The org name in mcp.json may be incorrect (`https://mcp.dev.azure.com/contoso`)"

5. Offer to set the active org to any ✅ org from the list.

---

## Notes

- The context is **session-scoped** — it resets when the conversation ends. Users who
  always work in the same project can prefix their first message with
  "Use org contoso, project Platform" to set it immediately.
- If the user's `mcp.json` contains only one `https://mcp.dev.azure.com/` entry, skip
  Workflow A and go directly to project selection.
- Project IDs (GUIDs) returned by `core_list_projects` are stable — they can be bookmarked
  or reused across sessions.
- Team selection (within a project) is handled by the `ado-project-discovery` skill.
  This skill handles org and project only.
- When the user says something like "use the Platform project", do not ask for confirmation
  if the name matches exactly one project — set it silently and confirm in the response.
- **Guest account caveats:** A guest user in a customer tenant can only see the projects
  and teams they have been explicitly granted access to — not necessarily all projects in
  the org. `core_list_projects` returns only the projects the authenticated identity can
  see. If a project is missing, the customer's ADO admin needs to grant access.
- **Security:** Never include PATs or tenant IDs in conversation output beyond what is
  needed to guide the user. The mcp.json file should be gitignored (it already is in
  this plugin's `.gitignore`).
