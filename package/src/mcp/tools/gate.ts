import { existsSync, readFileSync } from 'fs';
import { execSync } from 'child_process';
import { join } from 'path';

export const gateToolDefs = [
  {
    name: 'collar_gate_check',
    description: 'Check multiple gate conditions. Use before declaring completion.',
    inputSchema: {
      type: 'object' as const,
      properties: {
        gates: {
          type: 'array',
          description: 'List of gate conditions to check',
          items: {
            type: 'object',
            properties: {
              type: {
                type: 'string',
                enum: ['file_exists', 'state_active', 'git_clean', 'git_pushed', 'custom'],
              },
              path: { type: 'string' },
              mode: { type: 'string' },
              command: { type: 'string' },
              message: { type: 'string' },
            },
            required: ['type', 'message'],
          },
        },
      },
      required: ['gates'],
    },
  },
];

interface Gate {
  type: 'file_exists' | 'state_active' | 'git_clean' | 'git_pushed' | 'custom';
  path?: string;
  mode?: string;
  command?: string;
  message: string;
}

function getStateDir(): string {
  const local = join(process.cwd(), '.collar', 'state');
  if (existsSync(join(process.cwd(), '.collar'))) return local;
  return join(process.env['HOME'] ?? '', '.collar', 'state');
}

export function handleGateTool(name: string, args: Record<string, unknown>): unknown {
  if (name !== 'collar_gate_check') throw new Error(`Unknown gate tool: ${name}`);

  const gates = args.gates as Gate[];
  const results: Array<{ gate: string; passed: boolean; message: string }> = [];

  for (const gate of gates) {
    let passed = false;
    try {
      switch (gate.type) {
        case 'file_exists':
          passed = existsSync(gate.path ?? '');
          break;
        case 'git_clean': {
          const status = execSync('git status --porcelain', { encoding: 'utf-8' }).trim();
          passed = status === '';
          break;
        }
        case 'git_pushed': {
          try {
            const unpushed = execSync('git log @{u}..HEAD --oneline', { encoding: 'utf-8' }).trim();
            passed = unpushed === '';
          } catch {
            passed = true; // 업스트림 없으면 통과
          }
          break;
        }
        case 'state_active': {
          const stateDir = getStateDir();
          const filePath = join(stateDir, `${gate.mode}.json`);
          if (existsSync(filePath)) {
            const data = JSON.parse(readFileSync(filePath, 'utf-8'));
            passed = data.active === true;
          }
          break;
        }
        case 'custom': {
          execSync(gate.command ?? 'true', { stdio: 'ignore' });
          passed = true;
          break;
        }
      }
    } catch {
      passed = false;
    }
    results.push({ gate: gate.type, passed, message: passed ? 'OK' : gate.message });
  }

  return {
    passed: results.every(r => r.passed),
    results,
  };
}
