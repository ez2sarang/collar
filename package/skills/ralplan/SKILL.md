# ralplan — Rapid Algorithmic Planning via Agent Consensus

## 목적
복잡한 멀티 에이전트 계획 수립. 각 전문가(executor, architect, verifier)의 관점 통합.

## 키워드 트리거
- `$ralplan`
- `"consensus plan"`

## 작동 방식

1. **계획 단계**:
   - 사용자 요구사항 분석
   - 작업 분해 (구체적 단계로)
   - 각 단계별 담당 에이전트 지정

2. **에이전트 병렬 상담**:
   ```
   Architect: 설계 타당성 검토
   Executor:  구현 가능성 분석
   Verifier:  검증 방법 제시
   ```

3. **합의 기반 최종 계획**:
   - 각 전문가 피드백 통합
   - 리스크 식별 및 완화 전략
   - 최종 실행 순서 확정

4. **계획 저장**:
   ```
   .collar/plans/{timestamp}-{project}.md
   내용: 단계별 작업 + 담당자 + 검증 기준
   ```

## 실행 흐름

```
사용자: "$ralplan 이 대규모 리팩토링 계획해줘"
  ↓
[ralplan 활성화]
collar_state_write({ active: true, current_phase: "planning" })
  ↓
[병렬 상담 요청]
→ collar_spawn_agent(role: "architect", task: "...")
→ collar_spawn_agent(role: "executor", task: "...")
→ collar_spawn_agent(role: "verifier", task: "...")
  ↓
[에이전트 피드백 수집]
  ↓
[합의 기반 계획 수립]
  ↓
[계획 문서 생성]
.collar/plans/ 저장
  ↓
[사용자에게 제시]
"계획 완료. 진행할까요?"
```

## 설정

ralplan은 설정 없이 작동합니다.
단, 다음을 확인하세요:

1. `.collar/plans/` 디렉토리 쓰기 가능
2. MCP 서버 `collar_spawn_agent` 등록
3. 에이전트 역할 프롬프트 설치:
   - `~/.collar/prompts/architect.md`
   - `~/.collar/prompts/executor.md`
   - `~/.collar/prompts/verifier.md`

## 출력 형식

최종 계획은 마크다운 표 형식:

| 단계 | 설명 | 담당 | 검증 기준 |
|------|------|------|----------|
| 1 | ... | executor | ... |
| 2 | ... | architect | ... |

## 주의사항

- ralplan 중 작업 시작 금지 (계획만 수립)
- 계획 변경 필요 시: `$ralplan --revise` 로 재계획
- 상태 파일이 손상되면: `collar_state_clear ralplan` 로 초기화

## 예시

```
사용자: "$ralplan TypeScript 마이그레이션 전략"

[ralplan 시작]

→ Architect: "단계별 의존성 관리 전략"
→ Executor: "JS to TS 변환 도구 추천"
→ Verifier: "타입 커버리지 70% 이상 확보"

최종 계획:
1. 설정 파일 마이그레이션 (tsconfig.json)
2. 핵심 모듈 변환 (executor 담당)
3. 타입 커버리지 검증 (verifier 담당)
4. 남은 모듈 점진적 변환

"계획 완료. 진행할까요? (Y/N)"
```
