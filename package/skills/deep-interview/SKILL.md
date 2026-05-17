# deep-interview — Ouroboros: Self-Directed Knowledge Extraction

## 목적
AI가 자기 자신의 성능을 분석하고, 개선점을 발견하고, 패턴을 학습하는 피드백 루프.

## 키워드 트리거
- `$deep-interview`
- `"interview me"`
- `"ouroboros"`

## 작동 방식

### Phase 1: 자기 성찰 (Self-Reflection)

AI가 최근 작업을 분석:

```
collar_state_read("current_session")
→ 지난 작업 이력 검토
→ 성공한 패턴 식별
→ 실패한 접근 방식 분석
```

질문 예시:
- "이 작업에서 가장 효율적인 단계는?"
- "반복된 실수는 무엇인가?"
- "다음 번 같은 작업에 어떻게 개선할 것인가?"

### Phase 2: 지식 추출 (Knowledge Extraction)

패턴을 구조화된 형식으로 저장:

```
~/.collar/prompts/ (역할별 프롬프트 개선)
~/.claude/CLAUDE.md (글로벌 규칙 학습)
.collar/memory.md (프로젝트별 패턴)
```

### Phase 3: 피드백 루프 (Feedback Loop)

다음 세션에서 학습한 패턴 적용:

```
[세션 시작] → CLAUDE.md 로드 → 저장된 패턴 적용 → 작업 수행
```

## 실행 흐름

```
사용자: "$deep-interview 지난 작업을 분석해줘"
  ↓
[deep-interview 활성화]
collar_state_write({ active: true, current_phase: "reflection" })
  ↓
[Phase 1: 자기 성찰]
→ .collar/session-compact.md 분석
→ git log 검토
→ .collar/memory.md 확인
  ↓
[Phase 2: 지식 추출]
→ 반복 패턴 식별
→ 성공/실패 원인 분석
→ 개선 전략 수립
  ↓
[Phase 3: 저장 및 적용]
→ .collar/memory.md 업데이트
→ ~/.claude/CLAUDE.md 개선 제안
→ 프롬프트 최적화
  ↓
[최종 보고서]
"다음 세션부터 적용할 개선사항 3가지"
```

## 설정

deep-interview는 설정 없이 작동합니다.
단, 다음을 확인하세요:

1. `.collar/session-compact.md` 존재 여부
2. `.collar/memory.md` 쓰기 가능
3. `~/.claude/CLAUDE.md` 읽기 가능
4. git log 접근 가능

## 출력 형식

최종 보고서:

```
## 자기 성찰 결과

### 성공 패턴 (다음에 반복할 것)
- ...

### 실패 패턴 (피할 것)
- ...

### 개선 제안 (즉시 적용)
1. [CLAUDE.md 개선 제안]
2. [프롬프트 최적화]
3. [프로세스 개선]
```

## 주의사항

- deep-interview 중 외부 입력 무시 (자기 성찰에만 집중)
- 학습 결과 저장 후: `collar_state_clear deep-interview`
- 민감한 정보(API 키, 토큰) 자동 마스킹

## 예시

```
사용자: "$deep-interview"

[분석 중]

→ 지난 3개 세션 검토
→ TypeScript 타입 에러 반복 발견
→ git commit 전 검증 누락 패턴 발견

결과:
✅ 성공: 멀티 에이전트 병렬 처리 (매우 효율)
❌ 실패: 타입 체크 건너뛰기 (문제 재발)

개선안:
1. CLAUDE.md에 "TypeScript strict mode 필수" 추가
2. 커밋 전 자동 타입 체크 프로세스 추가
3. 다음 세션부터 적용

"개선사항이 저장되었습니다."
```

## 기술 세부사항

### 메모리 저장 구조

```
.collar/memory.md:
## 자기 성찰 기록 (2026-05-17)

### 패턴: TypeScript 타입 에러
- 원인: 컴파일 후 검증하는 대신 추측으로 코드 작성
- 해결책: 실시간 타ype checker 사용 (tsc --watch)
- 적용: 즉시

### 패턴: 커밋 전 테스트 누락
- 원인: 작업 완료 후 검증 게을리함
- 해결책: 커밋 전 자동 gating (pre-commit hook)
- 적용: 다음 프로젝트부터
```

### 프롬프트 개선

```
~/.collar/prompts/executor.md에 추가:

## 타입 안정성 (2026-05-17 추가)
- 모든 변수에 명시적 타입 지정
- 컴파일 후 실행 (tsc 성공 필수)
- 타입 에러 하나도 무시하지 말 것
```
