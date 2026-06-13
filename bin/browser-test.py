#!/usr/bin/env python3
"""
범용 브라우저 검증 스크립트 — collar 글로벌 유틸리티
사용법: uv run --with patchright python3 ~/.collar/bin/browser-test.py <URL> [스크린샷경로] [--cdp=URL] [--mobile]
예시:   uv run --with patchright python3 ~/.collar/bin/browser-test.py http://localhost:3000 /tmp/test.png --cdp=http://localhost:9222

CDP 모드 주의 (collar CDP 수명 규칙):
  - browser.close() / context.close() / page.close() 금지 — 사용자의 Chrome 프로세스/탭을 파괴함
  - `with sync_playwright() as pw:` 블록 금지 — 블록 종료 시 자동으로 browser.close()가 호출됨
  - 작업 후 browser.disconnect() + pw.stop()으로 연결만 끊고 탭은 그대로 둔다
  - 직접 띄운(launch) 브라우저는 우리 소유이므로 종료 시 정리해도 된다
"""

import argparse
from patchright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('url', help='검증할 URL')
parser.add_argument('screenshot', nargs='?', default='/tmp/browser-test.png', help='스크린샷 저장 경로')
parser.add_argument('--cdp', default='', help='Chrome CDP URL (예: http://localhost:9222)')
parser.add_argument('--mobile', action='store_true', help='모바일 뷰포트(375px) 테스트')
args = parser.parse_args()

console_errors = []

# with 블록 금지 → start()/stop()으로 수동 관리해야 CDP 연결 시 Chrome이 죽지 않는다
pw = sync_playwright().start()
browser = None
launched_ctx = None
try:
    if args.cdp:
        # 기존 Chrome에 연결만 한다 — 절대 close 하지 않는다
        browser = pw.chromium.connect_over_cdp(args.cdp)
        ctx = browser.contexts[0] if browser.contexts else browser.new_context()
    else:
        # 우리가 직접 띄운 브라우저 — 종료 시 정리해도 됨
        launched_ctx = pw.chromium.launch_persistent_context(
            user_data_dir='/tmp/collar-browser-profile',
            channel='chrome',
            headless=False,
            no_viewport=True,
        )
        ctx = launched_ctx

    page = ctx.new_page()
    page.on("console", lambda m: console_errors.append(f"[{m.type}] {m.text}") if m.type in ("error", "warning") else None)
    page.on("pageerror", lambda e: console_errors.append(f"[pageerror] {e}"))

    if args.mobile:
        page.set_viewport_size({"width": 375, "height": 812})

    print(f"[이동] {args.url}")
    page.goto(args.url, wait_until="networkidle", timeout=30000)
    print(f"[완료] {page.title()} — {page.url}")

    page.screenshot(path=args.screenshot, full_page=False)
    print(f"[스크린샷] {args.screenshot}")

    if console_errors:
        print("\n[콘솔 오류/경고]")
        for e in console_errors:
            print(f"  {e}")
    else:
        print("[콘솔] 오류 없음")

finally:
    if args.cdp:
        # CDP: 연결만 끊는다. 탭/컨텍스트/브라우저 close 금지 (Chrome 보호). 탭은 그대로 둔다.
        if browser is not None:
            browser.disconnect()
    else:
        # 직접 띄운 브라우저는 우리 소유이므로 정리
        if launched_ctx is not None:
            launched_ctx.close()
    pw.stop()
