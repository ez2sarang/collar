import { existsSync, readFileSync, writeFileSync, mkdirSync, rmSync, readdirSync } from 'fs';
import { join } from 'path';

function getStateDir(): string {
  const local = join(process.cwd(), '.collar', 'state');
  if (existsSync(join(process.cwd(), '.collar'))) return local;
  return join(process.env['HOME'] ?? '', '.collar', 'state');
}

export function registerStateTools(): void {
  // Tools are registered via the main server handler
}

export const stateToolDefs = [
  {
    name: 'collar_state_write',
    description: 'Write state data for a named mode to .collar/state/{mode}.json',
    inputSchema: {
      type: 'object' as const,
      properties: {
        mode: { type: 'string', description: 'State mode name (e.g. ralph, ralplan)' },
        data: { type: 'object', description: 'State data to write' },
      },
      required: ['mode', 'data'],
    },
  },
  {
    name: 'collar_state_read',
    description: 'Read state data for a named mode from .collar/state/{mode}.json',
    inputSchema: {
      type: 'object' as const,
      properties: {
        mode: { type: 'string', description: 'State mode name' },
      },
      required: ['mode'],
    },
  },
  {
    name: 'collar_state_clear',
    description: 'Delete state file for a named mode',
    inputSchema: {
      type: 'object' as const,
      properties: {
        mode: { type: 'string', description: 'State mode name' },
      },
      required: ['mode'],
    },
  },
  {
    name: 'collar_state_list',
    description: 'List all active states in .collar/state/',
    inputSchema: {
      type: 'object' as const,
      properties: {},
    },
  },
];

export function handleStateTool(name: string, args: Record<string, unknown>): unknown {
  const stateDir = getStateDir();

  if (name === 'collar_state_write') {
    const mode = args.mode as string;
    const data = args.data as Record<string, unknown>;
    mkdirSync(stateDir, { recursive: true });
    const filePath = join(stateDir, `${mode}.json`);
    const payload = { ...data, _updated_at: new Date().toISOString() };
    writeFileSync(filePath, JSON.stringify(payload, null, 2), 'utf-8');
    return { success: true, path: filePath };
  }

  if (name === 'collar_state_read') {
    const mode = args.mode as string;
    const filePath = join(stateDir, `${mode}.json`);
    if (!existsSync(filePath)) return { data: null };
    try {
      return { data: JSON.parse(readFileSync(filePath, 'utf-8')) };
    } catch { return { data: null }; }
  }

  if (name === 'collar_state_clear') {
    const mode = args.mode as string;
    const filePath = join(stateDir, `${mode}.json`);
    if (existsSync(filePath)) rmSync(filePath);
    return { success: true };
  }

  if (name === 'collar_state_list') {
    if (!existsSync(stateDir)) return { modes: [] };
    const files = readdirSync(stateDir).filter(f => f.endsWith('.json'));
    const modes = files.map(f => {
      const mode = f.replace('.json', '');
      try {
        const data = JSON.parse(readFileSync(join(stateDir, f), 'utf-8'));
        return {
          mode,
          active: data.active ?? false,
          started_at: data.started_at ?? null,
          current_phase: data.current_phase ?? null,
        };
      } catch {
        return { mode, active: false, started_at: null, current_phase: null };
      }
    });
    return { modes };
  }

  throw new Error(`Unknown state tool: ${name}`);
}
