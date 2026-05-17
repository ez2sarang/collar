import { existsSync } from 'fs';
import chalk from 'chalk';
import { execSync } from 'child_process';
import { COLLAR_SKILLS_DIR, GLOBAL_SETTINGS_JSON } from '../utils/paths.js';
import { readSettings } from '../utils/settings.js';

interface CheckResult {
  name: string;
  passed: boolean;
  message: string;
}

export async function doctor(): Promise<void> {
  console.log(chalk.bold('🩺 collar doctor'));
  console.log('');

  const checks: CheckResult[] = [];

  // 1. Node.js >= 20
  const nodeVersion = process.version;
  const nodeMajor = parseInt(nodeVersion.slice(1).split('.')[0], 10);
  checks.push({
    name: 'Node.js >= 20',
    passed: nodeMajor >= 20,
    message: `Node.js ${nodeVersion}`,
  });

  // 2. collar npm 설치 확인
  let collarInstalled = false;
  try {
    execSync('which collar', { stdio: 'ignore' });
    collarInstalled = true;
  } catch { }
  checks.push({
    name: 'collar npm 설치',
    passed: collarInstalled,
    message: collarInstalled ? 'collar 명령어 사용 가능' : 'collar 명령어 없음 (npm install -g 필요)',
  });

  // 3. ~/.collar/skills/ 존재
  const skillsExists = existsSync(COLLAR_SKILLS_DIR);
  checks.push({
    name: '~/.collar/skills/ 존재',
    passed: skillsExists,
    message: skillsExists ? COLLAR_SKILLS_DIR : '없음 (collar setup 실행 필요)',
  });

  // 4. settings.json MCP 등록
  const settings = readSettings(GLOBAL_SETTINGS_JSON);
  const mcpRegistered = !!(settings.mcpServers && (settings.mcpServers as Record<string, unknown>).collar);
  checks.push({
    name: 'MCP collar 등록',
    passed: mcpRegistered,
    message: mcpRegistered ? '등록됨' : '미등록 (collar setup 실행 필요)',
  });

  // 5. UserPromptSubmit 훅 등록
  const hooks = (settings.hooks ?? {}) as Record<string, unknown>;
  const upsHooks = hooks.UserPromptSubmit;
  const hookRegistered = Array.isArray(upsHooks) && upsHooks.length > 0;
  checks.push({
    name: 'UserPromptSubmit 훅 등록',
    passed: hookRegistered,
    message: hookRegistered ? '등록됨' : '미등록 (collar setup 실행 필요)',
  });

  // 결과 출력
  let allPassed = true;
  for (const check of checks) {
    const icon = check.passed ? chalk.green('✅') : chalk.red('❌');
    const status = check.passed ? chalk.green('PASS') : chalk.red('FAIL');
    console.log(`${icon} [${status}] ${check.name}`);
    if (!check.passed) {
      console.log(`       ${chalk.gray(check.message)}`);
      allPassed = false;
    }
  }

  console.log('');
  if (allPassed) {
    console.log(chalk.bold.green('모든 체크 통과 ✅'));
  } else {
    console.log(chalk.bold.red('일부 체크 실패 ❌'));
    console.log(chalk.gray('collar setup 을 실행하세요.'));
    process.exit(1);
  }
}
