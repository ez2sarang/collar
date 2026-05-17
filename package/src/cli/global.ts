import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync, copyFileSync } from 'fs';
import { createHash } from 'crypto';
import { join } from 'path';
import chalk from 'chalk';
import {
  GLOBAL_CLAUDE_MD, COLLAR_VERSION_FILE, COLLAR_HOME, getTemplatesDir,
} from '../utils/paths.js';

interface GlobalOptions {
  force?: boolean;
  dryRun?: boolean;
}

export async function globalCmd(options: GlobalOptions): Promise<void> {
  const force = options.force ?? false;
  const dryRun = options.dryRun ?? false;

  console.log(chalk.bold('🌐 collar global'));
  if (dryRun) console.log(chalk.gray('   모드: --dry-run'));
  if (force) console.log(chalk.gray('   모드: --force'));
  console.log('');

  const templatesDir = getTemplatesDir();
  const rulesTemplate = join(templatesDir, 'global', 'CLAUDE.md.rules');
  const memoryTemplateDir = join(templatesDir, 'global', 'memory');

  // 버전 해시 계산
  const globalDir = join(templatesDir, 'global');
  const currentHash = computeHash(globalDir);
  const storedHash = existsSync(COLLAR_VERSION_FILE) ? readFileSync(COLLAR_VERSION_FILE, 'utf-8').trim() : '';

  if (!dryRun && !force && currentHash && currentHash === storedHash) {
    console.log(chalk.green(`✅ collar-global: 이미 최신 버전 (${currentHash.slice(0, 8)}) — 스킵`));
    return;
  }

  // Phase 1: CLAUDE.md 규칙 병합
  console.log('━━━ Phase 1: ~/.claude/CLAUDE.md 규칙 병합 ━━━');
  if (!existsSync(rulesTemplate)) {
    console.log(chalk.yellow(`⚠️  규칙 템플릿 없음: ${rulesTemplate}`));
  } else {
    const rulesContent = readFileSync(rulesTemplate, 'utf-8');
    if (!existsSync(GLOBAL_CLAUDE_MD)) {
      if (!dryRun) {
        mkdirSync(join(GLOBAL_CLAUDE_MD, '..'), { recursive: true });
        writeFileSync(GLOBAL_CLAUDE_MD, rulesContent, 'utf-8');
        console.log(chalk.green('✅ 전체 규칙 추가 완료'));
      } else {
        console.log('[dry-run] CLAUDE.md 신규 생성');
      }
    } else {
      const existing = readFileSync(GLOBAL_CLAUDE_MD, 'utf-8');
      const sections = parseSections(rulesContent);
      let added = 0, skipped = 0;
      let updatedContent = existing;

      for (const section of sections) {
        const title = section.split('\n')[0].replace(/^## /, '');
        if (existing.includes(title)) {
          console.log(chalk.gray(`   중복 스킵: ${title}`));
          skipped++;
        } else {
          console.log(chalk.blue(`   신규 추가: ${title}`));
          if (!dryRun) {
            updatedContent += '\n' + section;
          }
          added++;
        }
      }

      if (!dryRun && added > 0) {
        writeFileSync(GLOBAL_CLAUDE_MD, updatedContent, 'utf-8');
      }
      console.log(`\n   규칙 병합: 추가 ${added}개 / 중복 스킵 ${skipped}개`);
    }
  }

  // Phase 2: 모든 collar 프로젝트 메모리 병합
  console.log('\n━━━ Phase 2: 프로젝트 메모리 병합 (전체 collar 프로젝트) ━━━');
  if (!existsSync(memoryTemplateDir)) {
    console.log(chalk.yellow(`⚠️  메모리 템플릿 디렉토리 없음: ${memoryTemplateDir}`));
  } else {
    const templateFiles = readdirSync(memoryTemplateDir).filter(f => f.endsWith('.md'));

    // collar 관리 프로젝트 탐색 (find ~/Documents/dev -name ".collar" -type d)
    const { execSync } = await import('child_process');
    let collarProjects: string[] = [];
    try {
      const findOutput = execSync(
        `find "${process.env['HOME'] ?? ''}/Documents/dev" -name ".collar" -type d 2>/dev/null`,
        { encoding: 'utf-8' }
      ).trim();
      collarProjects = findOutput.split('\n').filter(Boolean).map(p => p.replace('/.collar', ''));
    } catch { /* fallback: 현재 프로젝트만 */ }

    // 현재 프로젝트도 포함 (Documents/dev 밖에 있는 경우 대비)
    const currentProject = process.cwd();
    if (!collarProjects.includes(currentProject)) {
      collarProjects.push(currentProject);
    }

    console.log(`   대상 프로젝트: ${collarProjects.length}개`);
    let totalAdded = 0, totalSkipped = 0;

    for (const projectDir of collarProjects) {
      const projectName = projectDir.split('/').pop() ?? projectDir;
      const encodedPath = projectDir.replace(/\//g, '-');
      const projectMemoryDir = join(process.env['HOME'] ?? '', '.claude', 'projects', encodedPath, 'memory');

      if (!dryRun) mkdirSync(projectMemoryDir, { recursive: true });

      const memoryIndex = join(projectMemoryDir, 'MEMORY.md');
      let memAdded = 0, memSkipped = 0;

      for (const templateFile of templateFiles) {
        const src = join(memoryTemplateDir, templateFile);
        const dest = join(projectMemoryDir, templateFile);

        if (existsSync(dest)) {
          memSkipped++;
        } else {
          if (!dryRun) {
            copyFileSync(src, dest);
            const templateContent = readFileSync(src, 'utf-8');
            const desc = extractFrontmatter(templateContent, 'description') ?? templateFile;
            if (!existsSync(memoryIndex)) {
              writeFileSync(memoryIndex, '# Memory Index\n\n', 'utf-8');
            }
            const indexContent = readFileSync(memoryIndex, 'utf-8');
            if (!indexContent.includes(templateFile)) {
              writeFileSync(memoryIndex, indexContent + `- [${desc}](${templateFile}) — ${desc}\n`, 'utf-8');
            }
          }
          memAdded++;
        }
      }

      const status = memAdded > 0
        ? chalk.blue(`추가 ${memAdded}개`)
        : chalk.gray(`스킵 ${memSkipped}개`);
      console.log(`   ${projectName}: ${status}`);
      totalAdded += memAdded;
      totalSkipped += memSkipped;
    }
    console.log(`\n   메모리 병합 합계: 추가 ${totalAdded}개 / 중복 스킵 ${totalSkipped}개`);
  }

  // 버전 파일 갱신
  if (!dryRun) {
    mkdirSync(COLLAR_HOME, { recursive: true });
    writeFileSync(COLLAR_VERSION_FILE, currentHash, 'utf-8');
    console.log(chalk.bold.green('\n🌐 collar global 처리 완료!'));
  } else {
    console.log(chalk.bold('\n🔍 dry-run 완료 (실제 변경 없음)'));
  }
}

function parseSections(content: string): string[] {
  const sections: string[] = [];
  let current = '';
  for (const line of content.split('\n')) {
    if (line.startsWith('## ') && current) {
      sections.push(current.trimEnd());
      current = line + '\n';
    } else {
      current += line + '\n';
    }
  }
  if (current.trim()) sections.push(current.trimEnd());
  return sections.filter(s => s.startsWith('## '));
}

function extractFrontmatter(content: string, key: string): string | null {
  const match = content.match(new RegExp(`^${key}:\\s*(.+)$`, 'm'));
  return match ? match[1].trim().replace(/^"|"$/g, '') : null;
}

function computeHash(dir: string): string {
  if (!existsSync(dir)) return '';
  try {
    const hash = createHash('md5');
    const files = readdirSync(dir, { recursive: true } as unknown as { recursive: boolean })
      .filter(f => typeof f === 'string')
      .map(f => join(dir, f as string))
      .filter(f => existsSync(f) && !readFileSync(f, 'utf-8').includes('isDirectory'))
      .sort();
    for (const file of files) {
      try {
        hash.update(readFileSync(file));
      } catch {
        // skip directories
      }
    }
    return hash.digest('hex');
  } catch { return ''; }
}
