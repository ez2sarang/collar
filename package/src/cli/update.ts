import { execSync } from 'child_process';
import chalk from 'chalk';
import { setup } from './setup.js';
import { doctor } from './doctor.js';

export async function update(): Promise<void> {
  console.log(chalk.bold('🔄 collar update'));
  console.log('');

  // 1. 최신 버전 설치
  console.log('npm install -g collar-cli...');
  try {
    execSync('npm install -g collar-cli --ignore-scripts', { stdio: 'inherit' });
  } catch {
    console.log(chalk.yellow('⚠️  npm install 실패 (로컬 버전 유지)'));
  }

  // 2. setup 재실행
  await setup();

  // 3. doctor 실행
  await doctor();
}
