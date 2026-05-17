import { homedir } from 'os';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export const HOME = homedir();
export const COLLAR_HOME = join(HOME, '.collar');
export const CLAUDE_HOME = join(HOME, '.claude');
export const COLLAR_SKILLS_DIR = join(COLLAR_HOME, 'skills');
export const COLLAR_PROMPTS_DIR = join(COLLAR_HOME, 'prompts');
export const COLLAR_HOOKS_DIR = join(COLLAR_HOME, 'hooks');
export const COLLAR_PLANS_DIR = join(COLLAR_HOME, 'plans');
export const COLLAR_STATE_DIR = join(COLLAR_HOME, 'state');
export const GLOBAL_CLAUDE_MD = join(CLAUDE_HOME, 'CLAUDE.md');
export const GLOBAL_SETTINGS_JSON = join(CLAUDE_HOME, 'settings.json');
export const COLLAR_VERSION_FILE = join(COLLAR_HOME, '.global-version');

// dist/utils/paths.js → package root (2레벨 위)
export const PACKAGE_ROOT = join(__dirname, '..', '..');
export const PACKAGE_SKILLS_DIR = join(PACKAGE_ROOT, 'skills');
export const PACKAGE_PROMPTS_DIR = join(PACKAGE_ROOT, 'prompts');

export function getTemplatesDir(): string {
  // collar 레포 내 package/ 디렉토리의 상위에 templates/ 가 있음
  const repoRoot = join(PACKAGE_ROOT, '..');
  const templatesDir = join(repoRoot, 'templates');
  if (existsSync(templatesDir)) return templatesDir;
  // fallback: collar 레포를 찾을 수 없는 경우
  return join(COLLAR_HOME, 'templates');
}
