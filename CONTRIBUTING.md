# Contributing to ADO Cowork Plugin

Thank you for your interest in contributing! This plugin helps developers and project
managers interact with Azure DevOps using natural-language AI prompts.

## Ways to contribute

| Type | What to do |
|---|---|
| Bug report | Open a GitHub Issue using the Bug template |
| Feature request | Open a GitHub Issue using the Feature template |
| New skill | Follow the guide below |
| Improve an example | Edit `EXAMPLES.md` |
| Fix documentation | Edit `README.md` or skill files directly |

---

## Adding a new SKILL

1. **Create the folder** under `skills/`:
   ```
   skills/ado-<your-topic>/
   ```

2. **Create `SKILL.md`** with this exact frontmatter:
   ```yaml
   ---
   name: ado-<your-topic>
   description: |
     One-line trigger sentence.
     WHEN: "phrase 1", "phrase 2", "phrase 3".
   license: MIT
   metadata:
     version: "1.0"
   ---
   ```
   The `name` value must exactly match the folder name.

3. **Write the skill body** — describe which MCP tools are used, the step-by-step
   workflow, output format tables, and 1-3 prompt/response examples in the style of
   `EXAMPLES.md`.

4. **Register the skill** in `manifest.json` under `agentSkills`:
   ```json
   "skills/ado-<your-topic>"
   ```

5. **Run `package.ps1`** — all P001-P008 validation checks must pass before creating
   a pull request.

---

## Code style

- PowerShell scripts: strict mode, `Set-StrictMode -Version Latest`, UTF-8 with BOM.
- YAML: 2-space indentation.
- Markdown: ATX headings (`#`), pipe tables, fenced code blocks with language tag.

---

## Pull request checklist

- [ ] `package.ps1` runs with no `[FAIL]` lines
- [ ] New or updated skill has a `description:` trigger clause with at least 5 WHEN phrases
- [ ] `manifest.json` updated if new skill added
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] No secrets or PAT tokens in any committed file
