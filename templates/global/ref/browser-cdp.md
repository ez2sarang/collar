# 브라우저 자동화 — Patchright CDP 상세 레퍼런스

> 글로벌 CLAUDE.md "브라우저 자동화 — Patchright CDP 방식" 섹션의 상세 코드/명령 모음.
> 핵심 금지 규칙(Playwright MCP 금지, Chrome 전용, CDP 탭 닫기 금지)은 CLAUDE.md 본문에 있다.

## 허용: Patchright + CDP Python 스크립트

브라우저 자동화가 필요하면 **Python + Patchright + Google Chrome CDP** 방식을 사용한다.

```bash
# 기존 Chrome에 CDP로 연결 (추천)
uv run --with patchright python3 ~/.collar/bin/browser-test.py http://localhost:<PORT> /tmp/test.png --cdp=http://localhost:9222

# 새 브라우저 실행
uv run --with patchright python3 ~/.collar/bin/browser-test.py http://localhost:<PORT> /tmp/test.png

# 모바일 뷰포트
uv run --with patchright python3 ~/.collar/bin/browser-test.py http://localhost:<PORT> /tmp/test-mobile.png --mobile
```

스크린샷 확인: **Read 도구**로 `/tmp/test*.png` 직접 읽기 (gemini_vision 금지 — 느리고 부정확)

## CDP 연결 기본 패턴

```python
from patchright.sync_api import sync_playwright

pw = sync_playwright().start()
browser = pw.chromium.connect_over_cdp('http://localhost:9222')
context = browser.contexts[0] if browser.contexts else browser.new_context()
# URL 패턴으로 기존 탭 찾기
page = next((p for p in context.pages if 'target.com' in p.url), None)
if not page:
    page = context.new_page()

# ... 작업 수행 ...

# ✅ 연결만 끊기 (Chrome은 살아있음)
browser.disconnect()
pw.stop()
```

> ⚠️ **CDP 탭 닫기 금지 규칙**
> - `browser.close()` 절대 금지 — Chrome 프로세스 자체를 kill, 모든 탭 소멸
> - `context.close()` / `page.close()` 금지 — 불필요하게 탭을 파괴
> - `with sync_playwright() as pw:` 블록 금지 — 블록 종료 시 자동으로 `browser.close()` 호출됨
> - 작업 성공 후 탭은 **그대로 둘 것** — `browser.disconnect()`로 연결만 끊는다
> - 탭을 닫아야 하는 경우: 명시적으로 열었고, 다음 작업에서 불필요한 탭임을 확인한 경우만

## Chrome CDP 모드로 시작

```bash
killall "Google Chrome" 2>/dev/null; sleep 1
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-cdp-profile \
  --no-first-run &
sleep 3
```

## Cloudflare 우회

| 상황 | 방법 |
|------|------|
| 장기 스크래핑 | CDP 모드 (Chrome 열어두고 연결) |
| cf_clearance 쿠키 있음 | Patchright + 쿠키 파일 주입 |
| CF Turnstile 중간에 뜸 | iframe `input[type="checkbox"]` 자동 클릭 |
| 자동 클릭 실패 | 사용자에게 브라우저에서 직접 체크 요청 |

```python
CF_BLOCK = ['Just a moment', 'Attention Required', '봇 검증', 'cf-browser-verification']

def cf_handle(page, max_sec=180) -> bool:
    """CF 챌린지 처리 — 동적 대기, 고정 sleep 없음."""
    import time
    # 1. iframe 나타날 때까지 동적 대기 (고정 2000ms 제거)
    try:
        page.wait_for_selector('iframe[src*="challenges.cloudflare.com"]', timeout=3000)
    except Exception:
        pass
    # 2. JS로 모든 셀렉터 한 번에 탐색·클릭 (순차 click×4 제거)
    cf_frame = next((f for f in page.frames if 'challenges.cloudflare.com' in f.url), None)
    target = cf_frame or page
    target.evaluate("""() => {
        const sels = ['input[type="checkbox"]', '.ctp-checkbox-label', '#challenge-stage div', 'label',
                      '.cf-turnstile', '#challenge-form input'];
        for (const s of sels) { const el = document.querySelector(s); if (el) { el.click(); return s; } }
    }""")
    # 3. CF 해제 확인 — 500ms 폴링 (고정 5000ms 루프 대체)
    try:
        page.wait_for_function(
            "() => !document.body.innerText.includes('Just a moment') && "
            "      !document.body.innerText.includes('봇 검증')",
            timeout=max_sec * 1000, polling=500,
        )
        return True
    except Exception:
        return False

if any(s in page.content() for s in CF_BLOCK):
    cf_handle(page)
```

## 스크립트 위치 규칙

| 용도 | 위치 |
|------|------|
| 범용 브라우저 도구 | `~/.collar/bin/` |
| 프로젝트 전용 스크래퍼 | `<프로젝트>/scripts/` |
| 1회성 디버그 | `/tmp/` (재부팅 시 삭제됨) |

## 검증 체크리스트 (UI 변경 시)

```
[ ] 페이지 정상 로드 (500 에러 없음)
[ ] 핵심 UI 요소 존재
[ ] 콘솔 에러 없음
[ ] 모바일 레이아웃 확인 (375px)
STATUS: TESTED
```

**알려진 실패 패턴:**
- Oracle Cloud / AWS 콘솔 SPA → CDP에서 `Loading...` 무한 → 직접 브라우저 URL 접근 후 스크린샷
- `input()` 백그라운드 실행 → 즉시 종료 → 파일 기반 시그널로 대체
