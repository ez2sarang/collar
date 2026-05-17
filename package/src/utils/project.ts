import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

export type ProjectType = 'nextjs' | 'react' | 'nodejs-api' | 'nodejs' | 'python' | 'rust' | 'go' | 'swift' | 'kotlin' | 'java' | 'bash' | 'generic';

export function detectProjectType(targetDir: string): ProjectType {
  const pkgJson = join(targetDir, 'package.json');
  if (existsSync(pkgJson)) {
    try {
      const content = readFileSync(pkgJson, 'utf-8');
      if (content.includes('"next"')) return 'nextjs';
      if (content.includes('"react"')) return 'react';
      if (content.includes('"express"') || content.includes('"fastify"') || content.includes('"hono"')) return 'nodejs-api';
      return 'nodejs';
    } catch { return 'nodejs'; }
  }
  if (existsSync(join(targetDir, 'pyproject.toml')) ||
      existsSync(join(targetDir, 'requirements.txt')) ||
      existsSync(join(targetDir, 'setup.py'))) return 'python';
  if (existsSync(join(targetDir, 'Cargo.toml'))) return 'rust';
  if (existsSync(join(targetDir, 'go.mod'))) return 'go';
  if (existsSync(join(targetDir, 'Package.swift'))) return 'swift';
  if (existsSync(join(targetDir, 'build.gradle.kts')) || existsSync(join(targetDir, 'settings.gradle.kts'))) return 'kotlin';
  if (existsSync(join(targetDir, 'pom.xml')) || existsSync(join(targetDir, 'build.gradle'))) return 'java';
  if (existsSync(join(targetDir, 'Makefile')) || existsSync(join(targetDir, 'makefile'))) return 'bash';
  return 'generic';
}

export function getProjectConfig(type: ProjectType): {
  techStack: string;
  verifyCommand: string;
  devCommand1: string;
  devCommand2: string;
  domainTable: string;
} {
  switch (type) {
    case 'nextjs':
    case 'react':
    case 'nodejs-api':
    case 'nodejs':
      return {
        techStack: 'Node.js / TypeScript',
        verifyCommand: 'pnpm typecheck && pnpm test:run && pnpm build',
        devCommand1: 'pnpm dev',
        devCommand2: 'pnpm build',
        domainTable: '| UI 컴포넌트/페이지 | frontend | sonnet |\n| API 라우트/서비스 | backend | sonnet |',
      };
    case 'python':
      return {
        techStack: 'Python',
        verifyCommand: 'uv run pytest && uv run mypy .',
        devCommand1: 'uv run python -m app',
        devCommand2: 'uv build',
        domainTable: '| 비즈니스 로직 | executor | sonnet |\n| 데이터/DB | database | sonnet |',
      };
    case 'rust':
      return {
        techStack: 'Rust',
        verifyCommand: 'cargo test && cargo clippy && cargo build --release',
        devCommand1: 'cargo run',
        devCommand2: 'cargo build --release',
        domainTable: '| 코어 로직 | executor | sonnet |',
      };
    case 'go':
      return {
        techStack: 'Go',
        verifyCommand: 'go test ./... && go vet ./... && go build ./...',
        devCommand1: 'go run .',
        devCommand2: 'go build -o bin/app .',
        domainTable: '| 비즈니스 로직 | executor | sonnet |',
      };
    case 'swift':
      return {
        techStack: 'Swift',
        verifyCommand: 'swift build && swift test',
        devCommand1: 'swift run',
        devCommand2: 'swift build -c release',
        domainTable: '| 앱 로직 | executor | sonnet |\n| UI (SwiftUI) | designer | sonnet |',
      };
    case 'kotlin':
      return {
        techStack: 'Kotlin',
        verifyCommand: './gradlew test && ./gradlew build',
        devCommand1: './gradlew run',
        devCommand2: './gradlew build',
        domainTable: '| 비즈니스 로직 | executor | sonnet |\n| Android UI | designer | sonnet |',
      };
    case 'java':
      return {
        techStack: 'Java',
        verifyCommand: './mvnw test && ./mvnw build',
        devCommand1: './mvnw spring-boot:run',
        devCommand2: './mvnw package',
        domainTable: '| 비즈니스 로직 | executor | sonnet |',
      };
    case 'bash':
      return {
        techStack: 'Bash / Shell',
        verifyCommand: 'bash -n bin/*.sh && shellcheck bin/*.sh 2>/dev/null',
        devCommand1: 'bash script.sh',
        devCommand2: 'make 2>/dev/null || bash script.sh',
        domainTable: '| 스크립트 로직 (bin/) | executor | sonnet |',
      };
    default:
      return {
        techStack: '(직접 기입)',
        verifyCommand: '# 검증 명령어를 직접 입력하세요',
        devCommand1: '# 실행 명령어',
        devCommand2: '# 빌드 명령어',
        domainTable: '| 도메인 | 에이전트 | 모델 |',
      };
  }
}
