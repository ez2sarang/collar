# 런타임 환경 심층 분석
**날짜:** 2026-05-14  
**주제:** 허예찬 thesis 검증 + Claude Code Max 문제점 + 멀티-LLM 설계  
**현재 환경:** Claude Code 2.1.141 Max | codex-cli 0.121.0 | gemini CLI 0.36.0

---

## 1. 허예찬 thesis: "가벼운 프로그램이 에이전트 컨트롤에 유리하다"

### 1.1 무슨 말인가

허예찬이 팟캐스트에서 한 말의 핵심:
> "OpenAI CLI처럼 가벼운 프로그램이 에이전트 컨트롤하기 쉽다"

이걸 기술적으로 번역하면:

**무거운 런타임 (Claude Code)**
- IDE 대체 목적 설계 → 풍부하지만 무거움
- 대화형(interactive) 세션 중심
- 컨텍스트를 세션 전체에 걸쳐 누적
- 병렬 실행: 각 프로세스가 메모리와 세션 상태를 독립적으로 보유 → 병렬화 복잡

**가벼운 런타임 (codex exec)**
```bash
# codex exec = stdin → LLM → stdout, 상태 없음
cat src/function.ts | codex exec "add TypeScript types" > output.ts
echo "refactor this" | codex exec - < ./messy-code.py

# 병렬화 trivial
for f in src/*.ts; do
  codex exec "add tests" < "$f" > "tests/$(basename $f .ts).test.ts" &
done
wait
```

핵심 차이: `codex exec`은 유닉스 파이프라인 도구처럼 동작한다. 입력 → 처리 → 출력, 상태 없음.

### 1.2 현재 설치된 도구들의 실제 비대화형 모드

| 도구 | 비대화형 명령 | 특징 |
|------|-------------|------|
| `codex exec` | `codex exec "prompt"` 또는 stdin | 완전 비대화형, pipeline-first 설계 |
| `claude --print` | `claude -p "prompt"` | 나중에 추가된 기능, `--fallback-model` 지원 |
| `gemini -p` | `gemini -p "prompt" --approval-mode yolo` | 비대화형, 자동 승인 모드 있음 |

**핵심 발견:** `claude --print`에만 `--fallback-model` 옵션이 있다. Claude API가 과부하일 때 자동으로 다른 모델로 폴백할 수 있다. 이것은 중요한 설계 단서.

### 1.3 허예찬 thesis가 맞는 이유

에이전트 오케스트레이션에서 "컨트롤 가능성"의 핵심:

1. **결정론적 종료**: `codex exec`은 실행하고 종료됨. Claude Code 세션은 언제 끝나는지 모호함.
2. **출력 캡처**: stdout/stderr를 깔끔하게 파이프할 수 있음. 대화형은 터미널 이스케이프 코드 섞임.
3. **에러 핸들링**: exit code로 성공/실패 판단 가능. 대화형은 AI가 "완료" 텍스트 출력해도 실패일 수 있음.
4. **병렬화**: 10개 비대화형 프로세스 = 10개 독립 LLM 호출. 가볍고 예측 가능.
5. **재현성**: 같은 입력 → 같은 실행 경로. 세션 상태 없으니 사이드 이펙트 없음.

---

## 2. Claude Code Max 환경의 실제 문제점

**검증 기반**: 337회 실행 경험 + 14,000줄 bash 명령 로그

### 2.1 컨텍스트 오염 (Context Pollution)

**증상**: 세션이 길어질수록 이전 시도, 실패한 접근, 잘못된 전제가 쌓임.

```
세션 초반: "파일 A를 수정해줘" → 명확하게 수정
세션 중반: "파일 A를 수정해줘" → 이전에 논의했던 방향으로 잘못 수정
세션 말: 압축 발생 → 일부 컨텍스트 손실 → 혼동 증가
```

**실제 발생**: 이 세션에서도 이미 컨텍스트 압축이 1회 발생했음.

**해결책**: 작업 단위로 `--no-session-persistence` 플래그 사용. 하지만 이 옵션은 `--print` 모드에서만 작동.

### 2.2 단일 스레드 병렬화 제한

Claude Code는 기본적으로 한 세션 = 한 실행 흐름.

`run_in_background`로 에이전트를 병렬 실행하지만:
- 각 에이전트가 이 대화의 서브스레드 → 컨텍스트 공유 복잡
- 에이전트 결과 취합이 메인 세션의 컨텍스트 증가로 이어짐
- 에이전트가 많을수록 컨텍스트 = 무거워짐

**codex 방식 대비**: `codex exec`는 완전히 독립적인 프로세스 → 오케스트레이터가 결과만 모음.

### 2.3 레이트 리밋 + 비용 불투명

Max 플랜도 실제 무제한은 아님:
- 시간당 토큰 리밋 있음 (공개 안 됨)
- 리밋 히트 시: 세션 전체가 블로킹됨
- 어디까지 썼는지 실시간으로 알 수 없음
- `--max-budget-usd`는 `--print` 모드에서만 작동

**실제 증상**: 복잡한 작업 중 갑자기 응답 느려짐 → 사용자가 알 방법 없음.

### 2.4 Permission 모델 마찰

현재 선택지:
```
A) 매번 승인 요청 (기본) → 자율 작업 불가
B) --dangerously-skip-permissions → 모든 권한 개방 = 위험
```

중간 지점이 없음. Gemini CLI는 `--approval-mode auto_edit` (파일 편집만 자동 승인) 같은 세분화된 옵션이 있음.

### 2.5 단일 모델 의존성 + 폴백 없음

대화형 모드에서 Claude Sonnet 4.6이 과부하이면:
- 응답 느려짐 → 사용자가 기다려야 함
- 자동 폴백 없음

`claude --print --fallback-model claude-haiku-4-5-20251001`처럼 설정 가능하지만, **대화형 세션에서는 작동 안 함**.

### 2.6 세션 재개 복잡성

작업 중단 후 재개할 때:
- 세션 요약이 중요한 맥락을 잃을 수 있음 (이번 세션에서도 경험)
- 특히 background agent 결과가 요약에 포함되지 않을 수 있음

---

## 3. 멀티-LLM 환경 설계

### 3.1 현재 보유 LLM 스택

| LLM | 플랜 | 강점 | 현재 사용 |
|-----|------|------|---------|
| Claude Sonnet 4.6 | Max | 코드 생성, 복잡한 지시 따르기, 보안 분석 | 주력 |
| Claude Opus | Max | 아키텍처, 보안 심층 분석 | 가끔 |
| Gemini Pro | 구독 중 | 1M 컨텍스트, 멀티모달, 빠름 | 미활용 |
| OpenAI GPT/o시리즈 | Pro 구독 | 빠른 응답, 구조화 출력, 추론 | 미활용 |
| codex-cli | 설치됨 | 비대화형 파이프라인 | 미활용 |

### 3.2 각 LLM이 잘하는 것

**Claude (Sonnet/Opus):**
- 복잡한 다단계 코드 변경
- 긴 지시사항 + 제약조건 동시 처리
- 보안 취약점 분석
- collar 같은 메타 프로젝트 (자신의 환경을 이해하는 작업)

**Gemini Pro:**
- 파일이 100KB 이상인 분석 (1M 토큰 컨텍스트)
- 스크린샷/이미지 → 코드 변환
- 빠른 bulk 처리 (여러 파일 동시)
- Google Search 연동이 필요한 리서치

**OpenAI (GPT-4o/o3):**
- JSON 구조화 출력이 중요한 파이프라인
- 수학/추론 intensive 작업 (o3)
- codex exec 통한 비대화형 batch 처리
- 빠른 응답이 중요한 실시간 작업

### 3.3 라우팅 테이블 (collar 하네스 설계 기반)

```
작업 복잡도 분류:
┌─────────────────────────────────────────────────────┐
│ 단순 (검색/grep/파일 읽기)                           │
│ → codex exec / gemini -p (빠름, 저비용)             │
├─────────────────────────────────────────────────────┤
│ 표준 (코드 생성, 테스트 작성, 버그 수정)             │
│ → claude -p --print (신뢰도 높음)                   │
├─────────────────────────────────────────────────────┤
│ 대용량 파일 (100KB+)                                │
│ → gemini -p (1M 컨텍스트)                           │
├─────────────────────────────────────────────────────┤
│ 멀티모달 (스크린샷 분석, UI 리뷰)                   │
│ → gemini vision / gemini_vision MCP                 │
├─────────────────────────────────────────────────────┤
│ 아키텍처 / 보안 (중요 결정)                          │
│ → claude opus (--print 또는 대화형)                  │
├─────────────────────────────────────────────────────┤
│ Batch 처리 (여러 파일 병렬)                          │
│ → codex exec 병렬 (for loop)                        │
└─────────────────────────────────────────────────────┘
```

### 3.4 멀티-LLM 환경의 실제 문제점

**문제 1: 인증 분산**
- Claude: ~/.claude.json (claude CLI 인증)
- Gemini: $GEMINI_API_KEY (환경변수)
- OpenAI: ~/.codex/config.toml 또는 $OPENAI_API_KEY
- 관리 복잡, 각각 다른 갱신 주기

**문제 2: 출력 형식 불일치**
- Claude `-p --output-format json` → 특정 JSON 스키마
- Gemini `-p` → 다른 텍스트 형식
- codex exec → 그냥 텍스트
- 오케스트레이터가 각각 파싱해야 함

**문제 3: 비용 추적 불가**
- Claude Max: 포함된 것처럼 보이지만 rate limit 있음
- Gemini: API 사용량 추적 필요
- OpenAI: Pro 구독 vs API 호출 혼재
- 실제 비용 파악 안 됨

**문제 4: 품질 불일치**
- 같은 프롬프트도 모델마다 다른 코드 스타일
- 한 세션에서 3개 LLM이 생성한 코드 → 일관성 없음
- 코드 리뷰 어려움

---

## 4. collar가 이 복잡성을 어떻게 추상화해야 하는가

### 4.1 현재 collar (v1): 템플릿 생성기

```bash
collar-init my-project  # CLAUDE.md + AGENTS.md + settings.json 생성
```

단순하지만 런타임 선택과 완전 무관함.

### 4.2 collar v2 방향: 런타임 추상화 레이어

허예찬 thesis + 멀티-LLM 현실을 반영한 설계:

```bash
# 아이디어 (미구현):
collar run "파일 A를 분석해줘"  # 자동으로 적합한 LLM 선택
collar run --model fast "빠른 grep"  # 명시적 fast tier
collar run --model deep "아키텍처 리뷰"  # 명시적 deep tier
collar run --batch "*.ts" "타입 추가"  # 병렬 처리
```

내부적으로:
- `--model fast` → `gemini -p` 또는 `codex exec`
- `--model standard` → `claude --print -p`
- `--model deep` → `claude --print -p` with Opus
- `--batch` → `codex exec` 병렬 for loop

### 4.3 CLAUDE.md 템플릿에 반영할 라우팅 규칙

현재 collar 템플릿은 모델 라우팅을 단순히 언급만 함:
```
| 파일 검색 | explore | haiku |
```

실제 워크플로우에서 작동하려면:

```markdown
## 모델 선택 기준

작업 전 이 표를 참고해서 가장 가벼운 도구를 선택해라:

| 작업 | 도구 | 이유 |
|------|------|------|
| 파일 검색/grep | haiku 또는 gemini -p | 저비용, 빠름 |
| 코드 100줄 미만 수정 | sonnet --print | 신뢰도 |
| 파일 100KB 이상 분석 | gemini -p | 1M 컨텍스트 |
| 이미지/스크린샷 | gemini_vision | 멀티모달 |
| 아키텍처 결정 | opus | 한 번만 |
| batch 처리 | codex exec | 병렬화 |
```

### 4.4 Claude Code Max 환경에서 당장 개선할 것

지금 당장 할 수 있는 것들:

**A. `--print` 모드 활용 확대**
```bash
# 비대화형으로 단발성 작업 처리
claude -p "이 파일에서 TODO 목록 추출해줘" < src/main.ts

# fallback 설정
claude -p --fallback-model claude-haiku-4-5-20251001 "빠른 분석"
```

**B. 컨텍스트 경계 의도적으로 설정**
- 긴 작업 = 새 세션에서 시작
- `--no-session-persistence`로 임시 작업 격리

**C. gemini를 대용량 파일 전담으로 사용**
```bash
# 큰 파일은 Gemini로
gemini -p "이 로그 파일 전체에서 에러 패턴 찾아줘" --approval-mode yolo < huge-log.txt
```

**D. codex exec를 batch 작업 전담으로**
```bash
# 여러 파일 동시 타입 추가
for f in src/components/*.tsx; do
  codex exec "add proper TypeScript types to this React component" < "$f" > "src/typed/$(basename $f)" &
done
wait
```

---

## 5. gstack vs collar: 런타임 접근 비교

| 항목 | gstack | collar (현재) | collar (목표) |
|------|--------|--------------|--------------|
| 런타임 | Claude Code 전용 | Claude Code 전용 | 멀티-LLM 라우팅 |
| 비대화형 지원 | 없음 | 없음 | `collar run --print` |
| 모델 라우팅 | CLAUDE.md 문서로만 | CLAUDE.md 문서로만 | 실행 시 자동 라우팅 |
| 병렬화 | run_in_background | run_in_background | codex exec 병렬 |
| 비용 추적 | 없음 | 없음 | 태스크별 모델 선택 로그 |
| 컨텍스트 관리 | 세션 압축 의존 | 세션 압축 의존 | 작업별 clean context |

---

## 6. 핵심 결론

### 허예찬이 옳은 이유
Claude Code는 뛰어난 IDE 대체품이지만 **오케스트레이션 도구로는 무겁다**. 에이전트를 제어하려면 가벼운 `codex exec` 또는 `claude --print`가 더 적합하다.

### 지금 환경의 최대 문제
**3개의 강력한 LLM이 있는데 각자 독립적으로 존재하고 있음.** 라우팅, 폴백, 비용 최적화가 없다. collar가 이 추상화 레이어 역할을 할 수 있다.

### collar 다음 단계 제안
1. **즉시**: collar 템플릿에 LLM별 태스크 라우팅 테이블 추가 (문서 수준)
2. **단기**: `collar run` 명령어 prototype — 태스크 복잡도에 따라 적합한 CLI로 라우팅
3. **중기**: Paperclip과 연동 — 오케스트레이터가 collar를 통해 멀티-LLM 사용
