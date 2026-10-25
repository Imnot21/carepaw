# Dev Tools Setup — Claude Code + opencode

The plugins and MCP servers used to build CarePaw, so a second machine
(the laptop) can be set up the same way. Recorded 2026-10-25 from the
desktop: Claude Code 2.1.310, opencode v2.0.32.

No keys or passwords are kept here. Anything secret is set up by hand on
each machine.

---

## Already in the repo (nothing to install)

`git pull` brings these with it:

| What | Where |
|------|-------|
| Project agents (01–14) | `.claude/agents/` |
| Project skills (21: impeccable, ui-ux-pro-max, design, design-system, brand, slides, ...) | `.claude/skills/` |
| Project MCP servers: `dart`, `mobile-mcp` | `.mcp.json` |

`.mcp.json` points the `dart` server at a Flutter SDK path
(`--flutter-sdk C:\Users\six6six\Desktop\flutter`). If the laptop's
Flutter lives elsewhere, change that path locally and do not commit it.

---

## Claude Code — user plugins

Run inside a Claude Code session:

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add thedotmack/claude-mem
/plugin marketplace add JuliusBrussee/caveman

/plugin install superpowers@claude-plugins-official
/plugin install claude-mem@thedotmack
/plugin install caveman@caveman
```

| Plugin | Marketplace (GitHub) | Version here |
|--------|----------------------|--------------|
| `superpowers` | `anthropics/claude-plugins-official` | 7.0.0 |
| `claude-mem` | `thedotmack/claude-mem` (auto-update on) | 15.0.2 |
| `caveman` | `JuliusBrussee/caveman` | 4.0.1 |

Restart Claude Code after installing.

**From the claude.ai account (no install):** the `design`,
`vectorlab-ux-skills` and `anthropic-skills` sets sync in automatically
when you log in to Claude Code with the same account.

---

## Claude Code — user MCP servers

Run in a terminal:

```bash
claude mcp add --scope user memory -e MEMORY_FILE_PATH=<path-to>/memory.json -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user browsermcp -- npx -y @browsermcp/mcp@latest
```

`browsermcp` also needs the Browser MCP extension in Chrome.

---

## opencode

Config file: `~/.config/opencode/opencode.json`. Add these MCP servers:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "browsermcp": {
        "type": "local",
        "command": ["npx", "-y", "@browsermcp/mcp@latest"]
      },
      "claude-mem": {
        "type": "local",
        "command": [
          "node",
          "<HOME>/.claude/plugins/marketplaces/thedotmack/plugin/scripts/mcp-server.cjs"
        ]
      },
      "memory": {
        "type": "local",
        "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
        "environment": { "MEMORY_FILE_PATH": "<HOME>/.config/opencode/memory.json" }
      }
    }
  }
}
```

- `claude-mem` needs the Claude Code `claude-mem` plugin installed first;
  it runs that plugin's MCP script.
- Plugin `~/.config/opencode/plugins/claude-mem.js`: install it with
  `npx claude-mem install --ide opencode`, then restart opencode.
- Do **not** copy `~/.config/opencode/service.json`; it holds credentials.
  Set the service login up again on the laptop.

---

## Also needed on the laptop

- Flutter SDK (stable, Dart ^3.12) and Android SDK + emulator (`carepaw_demo` AVD).
- Node.js (for `npx` MCP servers).
- Firebase CLI: `npm i -g firebase-tools`, then `firebase login`.
- Release keystore (`android/key.properties` + `.jks`) — copied by hand
  from the backup, never through git.
