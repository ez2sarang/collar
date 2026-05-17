import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { COLLAR_PROMPTS_DIR } from '../../utils/paths.js';

export const spawnToolDefs = [
  {
    name: 'collar_spawn_agent',
    description: 'Prepare role prompt + task message for spawning an agent via Claude Agent() tool',
    inputSchema: {
      type: 'object' as const,
      properties: {
        role: { type: 'string', description: 'Agent role (executor, architect, verifier, planner, critic)' },
        task: { type: 'string', description: 'Task description for the agent' },
      },
      required: ['role', 'task'],
    },
  },
];

export function handleSpawnTool(name: string, args: Record<string, unknown>): unknown {
  if (name !== 'collar_spawn_agent') throw new Error(`Unknown spawn tool: ${name}`);

  const role = args.role as string;
  const task = args.task as string;
  const promptPath = join(COLLAR_PROMPTS_DIR, `${role}.md`);

  let rolePrompt = '';
  if (existsSync(promptPath)) {
    rolePrompt = readFileSync(promptPath, 'utf-8');
  } else {
    rolePrompt = `You are a ${role} agent. Complete the assigned task carefully and thoroughly.`;
  }

  return {
    role_prompt: rolePrompt,
    task,
    combined_message: `${rolePrompt}\n\nTask: ${task}`,
  };
}
