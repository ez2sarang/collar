# 작업 이력 자동 기록 — LLM Logs API 상세 레퍼런스

> 글로벌 CLAUDE.md "작업 이력 자동 기록 — LLM Logs API" 섹션의 상세 명령/필드.
> 핵심 규칙(작업 완료 시점마다 best-effort POST, 서버 꺼져도 작업 중단 안 함)은 CLAUDE.md 본문에 있다.

## 기록 시점

- 사용자 요청에 대한 작업이 완전히 끝났을 때 (코드 수정, 파일 생성, 분석, 설명 등 모든 유형)
- 커밋 완료 직후 (커밋이 포함된 작업이면 커밋 후 기록)
- 에러로 작업이 종료됐을 때도 `status: "error"` 로 기록

## 기록 방법

```bash
curl -s --max-time 3 -X POST http://localhost:3999/api/llm-logs \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "anthropic",
    "model": "<현재_모델_ID>",
    "status": "success",
    "prompt": "<사용자_요청_한줄_요약>",
    "response": "<수행한_작업_한줄_요약>"
  }' || true
```

## 필드 작성 규칙

| 필드 | 필수 | 작성 방법 |
|------|------|-----------|
| `provider` | ✅ | 항상 `"anthropic"` |
| `model` | ✅ | 현재 모델 ID (예: `"claude-sonnet-4-6"`) |
| `status` | — | `"success"` 또는 `"error"` |
| `prompt` | — | 사용자 요청을 30자 이내로 요약 (한국어 OK) |
| `response` | — | 수행한 작업 요약 (파일명, 변경 내용 등) |
| `input_tokens` | — | 알 수 있으면 기록, 모르면 생략 |
| `output_tokens` | — | 알 수 있으면 기록, 모르면 생략 |
| `duration_ms` | — | 알 수 있으면 기록, 모르면 생략 |

## 예시

```bash
# 코드 수정 완료 후
curl -s --max-time 3 -X POST http://localhost:3999/api/llm-logs \
  -H "Content-Type: application/json" \
  -d '{"provider":"anthropic","model":"claude-sonnet-4-6","status":"success","prompt":"collar-init .npmrc 생성 추가","response":"bin/collar-init에 .npmrc 생성 로직 추가, 테스트 완료"}' || true

# 에러 발생 시
curl -s --max-time 3 -X POST http://localhost:3999/api/llm-logs \
  -H "Content-Type: application/json" \
  -d '{"provider":"anthropic","model":"claude-sonnet-4-6","status":"error","prompt":"collar-init 실행","response":"템플릿 경로 오류로 실패"}' || true
```

## 주의

- `--max-time 3`: 서버 응답 없으면 3초 후 포기 (작업 블로킹 방지)
- `|| true`: curl 실패해도 셸 오류로 전파 안 됨
- 작업 중간이 아닌 **완료 시점에만** 기록 (중간 기록 금지)
