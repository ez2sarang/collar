# ralph — Relentless Algorithmic Loop for Harness Focus

## 목적
작업 집중도 저하 방지. 반복적인 중단(context switch) 없이 한 주제를 깊이 있게 진행.

## 키워드 트리거
- `$ralph`
- `"don't stop"`
- `"keep going"`
- `"must complete"`

## 작동 방식

1. **상태 저장** (`collar_state_write`):
   ```
   .collar/state/ralph.json:
   {
     "active": true,
     "started_at": "2026-05-17T12:00:00Z",
     "current_phase": "implementation",
     "task_summary": "사용자 입력 작업 설명",
     "focus_mode": true,
     "context_budget": 80000
   }
   ```

2. **Relentless Loop**:
   - 사용자 입력 ← → 작업 실행 ← → 진행 상태 보고
   - 각 루프에서 현재 컨텍스트 사용량 체크
   - 임계값(80%) 도달 시:
     - `.collar/session-compact.md` 생성
     - 상태 요약 저장
     - 새 세션 제안

3. **자동 격리**:
   - ralph 활성 중: 다른 스킬 진입 차단
   - 단 한 가지 주제만 진행
   - 완료될 때까지 멈추지 않음

4. **완료 기준** (다음 중 하나):
   - 사용자: `완료` 또는 `끝` 선언
   - AI: `collar_gate_check`로 조건 확인
     ```
     gates: [
       { type: 'git_clean', message: '커밋 대기' },
       { type: 'file_exists', path: '.collar/session-compact.md', message: '세션 압축' }
     ]
     ```
   - 컨텍스트 한계: 자동 종료 후 .collar/state/ralph.json 저장

## 실행 흐름

```
사용자: "$ralph 이 기능 완성해줘"
  ↓
[ralph 활성화]
collar_state_write({ active: true, current_phase: "implementation" })
  ↓
[반복 루프 시작]
  → 작업 수행 (파일 수정, 컴파일, 테스트)
  → 매 단계마다: 상태 확인 (collar_state_read)
  → 프로그레스 보고 (간결하게)
  → 컨텍스트 % 체크
  ↓
[완료 또는 컨텍스트 만료]
collar_state_write({ active: false, completed_at: "..." })
.collar/session-compact.md에 정리
```

## 설정

ralph는 설정 없이 작동합니다.
단, 다음을 확인하세요:

1. `.collar/state/` 디렉토리 쓰기 가능
2. MCP 서버 `collar_state_write/read` 등록
3. 컨텍스트 사용량 모니터링 활성화

## 주의사항

- ralph 중 중단 키워드 (`cancel`, `stop`, `pause`)는 무시됨
- 강제 종료: 사용자가 새 세션 시작 → 자동 종료
- 상태 파일이 손상되면: `collar_state_clear ralph` 로 초기화

## 예시

```
사용자: "$ralph 멀티스레드 버그 해결하자"

[ralph 시작]

→ 파일 읽기 및 분석
→ 동시성 문제 식별
→ 수정 구현
→ 테스트 작성 및 검증
→ 모든 가지 테스트 통과 확인

결과: ralph 종료, .collar/session-compact.md에 변경사항 기록
사용자: "완료"
```
