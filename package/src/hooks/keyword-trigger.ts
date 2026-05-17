import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

async function main(): Promise<void> {
  let hookData: Record<string, unknown>;
  try {
    const stdin = readFileSync('/dev/stdin', 'utf-8');
    hookData = JSON.parse(stdin) as Record<string, unknown>;
  } catch {
    process.exit(0);
  }

  if (hookData['hook_event_name'] !== 'UserPromptSubmit') process.exit(0);

  const message = (hookData['prompt'] as string | undefined) ?? '';

  const KEYWORD_MAP: Record<string, string> = {
    '$ralph': 'ralph',
    "don't stop": 'ralph',
    'keep going': 'ralph',
    'must complete': 'ralph',
    '$ralplan': 'ralplan',
    'consensus plan': 'ralplan',
    '$deep-interview': 'deep-interview',
    'interview me': 'deep-interview',
    'ouroboros': 'deep-interview',
  };

  const lowerMsg = message.toLowerCase();
  for (const [keyword, skill] of Object.entries(KEYWORD_MAP)) {
    if (lowerMsg.includes(keyword.toLowerCase())) {
      const skillPath = join(homedir(), '.collar', 'skills', skill, 'SKILL.md');
      if (existsSync(skillPath)) {
        const skillContent = readFileSync(skillPath, 'utf-8');
        process.stdout.write(`COLLAR_SKILL [${skill}]: 스킬 활성화\n\n${skillContent}\n`);
      }
      break;
    }
  }
  process.exit(0);
}

main().catch(() => process.exit(0));
