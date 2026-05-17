# collar-cli

AI harness standardization layer for Claude Code. Provides CLI tools, MCP server, skills, and role-based prompts for consistent agent orchestration.

## Installation

```bash
npm install -g collar-cli
collar setup
collar doctor
```

## Usage

### Phase 1: CLI Commands

```bash
# Setup collar globally (MCP + hooks)
collar setup

# Initialize collar in a project
cd /path/to/project
collar init

# Verify installation
collar doctor

# Update collar
collar update

# Apply global rules to all projects
collar global --force
```

### Phase 2: MCP Server

collar provides an MCP server with state management tools:

```bash
collar mcp-serve
```

Available tools:
- `collar_state_write`: Write mode state to `.collar/state/{mode}.json`
- `collar_state_read`: Read mode state
- `collar_state_clear`: Delete mode state
- `collar_state_list`: List all active states
- `collar_gate_check`: Check completion gates
- `collar_spawn_agent`: Prepare agent prompts and tasks

### Phase 3: Skills

Activate skills via keyword triggers:

- **ralph**: `$ralph` — Relentless Algorithmic Loop for Harness Focus
- **ralplan**: `$ralplan` — Rapid Algorithmic Planning via Agent Consensus
- **deep-interview**: `$deep-interview` or `"ouroboros"` — Self-Directed Knowledge Extraction

## Directory Structure

```
~/.collar/
├── skills/          # Installed skill modules
├── prompts/         # Role-based agent prompts
├── hooks/           # Hook scripts
├── state/           # Mode state files
└── plans/           # Generated plans

.collar/             # Project-level state (per project)
├── config.json
├── memory.md
├── state/
└── hooks/
```

## Architecture

### Phase 1: CLI Layer
- `collar init [path]` - Initialize projects with CLAUDE.md, AGENTS.md templates
- `collar setup` - Global installation (MCP registration + skills)
- `collar doctor` - Verify installation

### Phase 2: MCP Server
- State machine for mode management (ralph, ralplan, etc.)
- Completion gates (git clean, file exists, custom checks)
- Agent spawning with role prompts

### Phase 3: Skills System
- Ralph: Relentless task focus with state tracking
- Ralplan: Multi-agent consensus planning
- Deep-Interview: Self-reflection and pattern learning

## Development

```bash
npm install --ignore-scripts
npm run build
npm run dev          # Watch mode
npm install -g .    # Local global install
```

## Files

- `src/cli/` - CLI commands
- `src/mcp/tools/` - MCP server tools
- `src/utils/` - Shared utilities
- `src/hooks/` - Keyword trigger system
- `skills/` - Skill definitions
- `prompts/` - Role-based agent prompts
