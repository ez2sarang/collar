import { existsSync, mkdirSync, copyFileSync, readdirSync } from 'fs';
import { join } from 'path';
import chalk from 'chalk';
import {
  COLLAR_HOME, COLLAR_SKILLS_DIR, COLLAR_PROMPTS_DIR, COLLAR_HOOKS_DIR,
  GLOBAL_SETTINGS_JSON, PACKAGE_SKILLS_DIR, PACKAGE_PROMPTS_DIR,
} from '../utils/paths.js';
import { mergeSettings } from '../utils/settings.js';

export async function setup(): Promise<void> {
  console.log(chalk.bold('🎯 collar setup'));
  console.log('');

  // 1. ~/.collar/skills/ 생성 + 패키지 내 skills/ 복사
  mkdirSync(COLLAR_SKILLS_DIR, { recursive: true });
  if (existsSync(PACKAGE_SKILLS_DIR)) {
    const skillDirs = readdirSync(PACKAGE_SKILLS_DIR);
    for (const skillDir of skillDirs) {
      const src = join(PACKAGE_SKILLS_DIR, skillDir);
      const dest = join(COLLAR_SKILLS_DIR, skillDir);
      mkdirSync(dest, { recursive: true });
      const files = readdirSync(src);
      for (const file of files) {
        copyFileSync(join(src, file), join(dest, file));
      }
    }
    console.log(chalk.green('✅ ~/.collar/skills/ 설치'));
  } else {
    console.log(chalk.yellow('⚠️  skills/ 디렉토리 없음 (패키지 루트 확인 필요)'));
  }

  // 2. ~/.collar/prompts/ 생성 + 복사
  mkdirSync(COLLAR_PROMPTS_DIR, { recursive: true });
  if (existsSync(PACKAGE_PROMPTS_DIR)) {
    const promptFiles = readdirSync(PACKAGE_PROMPTS_DIR);
    for (const file of promptFiles) {
      copyFileSync(join(PACKAGE_PROMPTS_DIR, file), join(COLLAR_PROMPTS_DIR, file));
    }
    console.log(chalk.green('✅ ~/.collar/prompts/ 설치'));
  } else {
    console.log(chalk.yellow('⚠️  prompts/ 디렉토리 없음'));
  }

  // 3. ~/.collar/hooks/ 생성
  mkdirSync(COLLAR_HOOKS_DIR, { recursive: true });

  // 4. ~/.claude/settings.json에 MCP 서버 등록 (딥 머지)
  mergeSettings(GLOBAL_SETTINGS_JSON, {
    mcpServers: {
      collar: {
        command: 'collar',
        args: ['mcp-serve'],
        type: 'stdio',
      },
    },
  } as unknown as Record<string, unknown>);
  console.log(chalk.green('✅ ~/.claude/settings.json MCP 등록'));

  // 5. UserPromptSubmit 훅 등록 (딥 머지)
  mergeSettings(GLOBAL_SETTINGS_JSON, {
    hooks: {
      UserPromptSubmit: [
        {
          matcher: '',
          hooks: [
            {
              type: 'command',
              command: `node ${COLLAR_HOOKS_DIR}/keyword-trigger.mjs`,
            },
          ],
        },
      ],
    },
  } as unknown as Record<string, unknown>);
  console.log(chalk.green('✅ ~/.claude/settings.json 훅 등록'));

  console.log('');
  console.log(chalk.bold('collar setup 완료!'));
  console.log('  collar doctor  # 설치 확인');
}
