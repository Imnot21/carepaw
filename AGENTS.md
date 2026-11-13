# AGENTS.md - CarePaw

**Read `docs/OPENCODE_HANDOFF.md` first.** It records what was done, the user's decisions, and the open to-do list (last Claude Code session: 2026-11-03).
Then see `CLAUDE.md` for the full project overview, architecture, and workflows. Track progress in `docs/CHAPTER1_ALIGNMENT.md`.

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
