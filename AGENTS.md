# AGENTS.md - CarePaw

See `CLAUDE.md` for full project overview, architecture, and workflows.

## Memory - MUST USE

You have a persistent knowledge-graph memory via MCP `memory_*` tools. Use it every session to remember chats.

**At session start:**
1. Call `memory_read_graph` or `memory_search_nodes` to retrieve relevant past context (user prefs, project decisions, ongoing work).
2. If `CarePaw_User` / project entities exist, factor them into your answers.

**During work, record:**
- a) Basic identity / environment (OS, Flutter version, paths)
- b) Project decisions (architecture, package choices, module status)
- c) User preferences (communication style, workflow)
- d) Goals / todos in progress
- e) Relationships between people, systems, modules

**At session end / on new facts:**
- `memory_create_entities` for new people/orgs/events (e.g. `CarePaw_User`, `CarePaw_Project`)
- `memory_create_relations` to link them
- `memory_add_observations` to append facts to existing entities
- Never delete medical-record-like history silently - update via new observations.

Memory file: `C:\Users\six6six\.config\opencode\memory\memory.jsonl` (shared across projects - do not move).
