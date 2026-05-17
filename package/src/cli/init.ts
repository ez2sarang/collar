import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync, copyFileSync, chmodSync } from 'fs';
import { join, resolve, basename } from 'path';
import chalk from 'chalk';
import { detectProjectType, getProjectConfig } from '../utils/project.js';
import { mergeSettings } from '../utils/settings.js';
import { getTemplatesDir } from '../utils/paths.js';

export async function init(targetPath?: string): Promise<void> {
  const targetDir = resolve(targetPath ?? '.');
  const projectName = basename(targetDir);
  const templatesDir = getTemplatesDir();

  console.log(chalk.bold(`🎯 collar init: ${projectName}`));
  console.log(`   대상: ${targetDir}`);
  console.log('');

  // 1. 프로젝트 타입 감지
  const projectType = detectProjectType(targetDir);
  const config = getProjectConfig(projectType);
  console.log(`📦 프로젝트 타입: ${projectType}`);

  // 2. .collar/ 디렉토리 생성
  const collarDir = join(targetDir, '.collar');
  mkdirSync(collarDir, { recursive: true });
  mkdirSync(join(collarDir, 'state'), { recursive: true });
  mkdirSync(join(collarDir, 'hooks'), { recursive: true });

  // 3. CLAUDE.md 생성 (없으면)
  const claudeMdOut = join(targetDir, 'CLAUDE.md');
  if (existsSync(claudeMdOut)) {
    console.log(chalk.yellow('⚠️  CLAUDE.md 이미 존재. 건너뜀.'));
  } else {
    const claudeMdBase = join(templatesDir, 'CLAUDE.md.base');
    if (existsSync(claudeMdBase)) {
      let content = readFileSync(claudeMdBase, 'utf-8');
      content = renderTemplate(content, projectName, config);
      writeFileSync(claudeMdOut, content, 'utf-8');
      console.log(chalk.green('✅ CLAUDE.md 생성'));
    }
  }

  // 4. AGENTS.md 생성 (없으면)
  const agentsMdOut = join(targetDir, 'AGENTS.md');
  if (existsSync(agentsMdOut)) {
    console.log(chalk.yellow('⚠️  AGENTS.md 이미 존재. 건너뜀.'));
  } else {
    const agentsMdBase = join(templatesDir, 'AGENTS.md.base');
    if (existsSync(agentsMdBase)) {
      let content = readFileSync(agentsMdBase, 'utf-8');
      content = renderTemplate(content, projectName, config);
      writeFileSync(agentsMdOut, content, 'utf-8');
      console.log(chalk.green('✅ AGENTS.md 생성'));
    }
  }

  // 5. .collar/config.json 생성 (없으면)
  const configOut = join(collarDir, 'config.json');
  if (!existsSync(configOut)) {
    const configBase = join(templatesDir, 'config.json');
    if (existsSync(configBase)) {
      copyFileSync(configBase, configOut);
    } else {
      writeFileSync(configOut, JSON.stringify({ project: projectName, type: projectType }, null, 2), 'utf-8');
    }
    console.log(chalk.green('✅ .collar/config.json 생성'));
  }

  // 6. .collar/memory.md 생성 (없으면)
  const memoryOut = join(collarDir, 'memory.md');
  if (!existsSync(memoryOut)) {
    const today = new Date().toISOString().split('T')[0];
    writeFileSync(memoryOut, `# Project Memory — ${projectName}\n마지막 업데이트: ${today}\n\n---\n\n## 발견된 패턴\n\n(아직 없음)\n\n## 작업 이력 요약\n\n(중요한 의사결정 기록)\n`, 'utf-8');
    console.log(chalk.green('✅ .collar/memory.md 생성'));
  }

  // 7. .collar/hooks 설치
  const hooksDir = join(collarDir, 'hooks');
  const hooksTemplateDir = join(templatesDir, 'collar-hooks');
  if (existsSync(hooksTemplateDir)) {
    const hookFiles = readdirSync(hooksTemplateDir).filter(f => f.endsWith('.sh'));
    for (const hookFile of hookFiles) {
      const dest = join(hooksDir, hookFile);
      if (!existsSync(dest)) {
        copyFileSync(join(hooksTemplateDir, hookFile), dest);
        chmodSync(dest, 0o755);
      }
    }
    if (hookFiles.length > 0) console.log(chalk.green(`✅ .collar/hooks 설치: ${hookFiles.length}개`));
  }

  // 8. .claude/settings.json 훅 등록
  const dotClaude = join(targetDir, '.claude');
  mkdirSync(dotClaude, { recursive: true });
  const settingsOut = join(dotClaude, 'settings.json');

  mergeSettings(settingsOut, {
    permissions: {
      allow: ['Bash(git *)', 'Bash(pnpm *)', 'Bash(npm *)', 'Bash(uv *)'],
      deny: ['Bash(rm -rf /)', 'Bash(curl * | bash)', 'Bash(wget * | sh)'],
    },
    hooks: {
      UserPromptSubmit: [
        {
          matcher: '',
          hooks: [{ type: 'command', command: 'bash .collar/hooks/collar-dispatcher.sh' }],
        },
      ],
      PostToolUse: [
        {
          matcher: 'Bash',
          hooks: [{ type: 'command', command: 'bash .collar/hooks/30-commit-guard.sh' }],
        },
      ],
      Stop: [
        {
          matcher: '',
          hooks: [{ type: 'command', command: 'bash .collar/hooks/collar-dispatcher.sh' }],
        },
      ],
    },
  } as unknown as Record<string, unknown>);
  console.log(chalk.green('✅ .claude/settings.json 훅 등록'));

  console.log('');
  console.log(chalk.bold('🎉 하네스 설치 완료!'));
}

function renderTemplate(content: string, projectName: string, config: ReturnType<typeof getProjectConfig>): string {
  const today = new Date().toISOString().split('T')[0];
  return content
    .replace(/\{\{PROJECT_NAME\}\}/g, projectName)
    .replace(/\{\{PROJECT_DESCRIPTION\}\}/g, 'TODO: 이 프로젝트가 무엇인지 한 줄로 설명하라.')
    .replace(/\{\{PROJECT_PURPOSE\}\}/g, 'TODO: 이 프로젝트의 목적을 설명하라.')
    .replace(/\{\{TECH_STACK\}\}/g, config.techStack)
    .replace(/\{\{VERIFY_COMMAND\}\}/g, config.verifyCommand)
    .replace(/\{\{DEV_COMMAND_1\}\}/g, config.devCommand1)
    .replace(/\{\{DEV_COMMAND_2\}\}/g, config.devCommand2)
    .replace(/\{\{SETUP_COMMANDS\}\}/g, config.devCommand1)
    .replace(/\{\{DOMAIN_1\}\}/g, '도메인 1')
    .replace(/\{\{AGENT_1\}\}/g, 'executor')
    .replace(/\{\{DATE\}\}/g, today);
}
