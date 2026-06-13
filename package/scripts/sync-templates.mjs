#!/usr/bin/env node
// build 시 레포의 templates/ 를 패키지 루트로 복사한다.
// npm 배포 tarball이 templates/ 를 포함해 `collar global`/`collar init`이
// node_modules 설치 환경에서도 동작하도록 보장한다 (getTemplatesDir 1순위).
import { cpSync, existsSync, rmSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const packageRoot = join(__dirname, '..');
const repoTemplates = join(packageRoot, '..', 'templates');
const dest = join(packageRoot, 'templates');

if (!existsSync(repoTemplates)) {
  console.warn('[sync-templates] 레포 templates/ 없음 — 스킵 (이미 배포된 패키지일 수 있음)');
  process.exit(0);
}

if (existsSync(dest)) rmSync(dest, { recursive: true, force: true });
cpSync(repoTemplates, dest, { recursive: true });
console.log('[sync-templates] templates/ → package/templates 복사 완료');
