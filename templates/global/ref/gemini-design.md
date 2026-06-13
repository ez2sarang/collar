# Gemini Multimodal + Design Task Routing 상세 레퍼런스

> 글로벌 CLAUDE.md "Gemini Multimodal Integration" + "Design Task Routing (Gemini Pro)" 섹션의 상세 트리거/워크플로우.
> 핵심 규칙(gemini_vision 금지 → Read로 PNG 직접 읽기, 대용량 분석/요약은 gemini_code/gemini_summarize, 디자인 작업은 Gemini 우선)은 CLAUDE.md 본문에 있다.

## Gemini Multimodal Integration

When the gemini-mcp MCP server is available, use Gemini for:

- **Large codebase analysis**: Use `gemini_code` for reviewing large files or directories
- **Long text summarization**: Use `gemini_summarize` for long-form content
- **스크린샷 분석**: `gemini_vision` 사용 금지 — `Read` 도구로 PNG 직접 읽기 (gemini_vision은 느리고 부정확)

Available MCP tools:
- `gemini_prompt` - Text queries
- `gemini_code` - Code review and analysis
- `gemini_summarize` - Text summarization

## Design Task Routing (Gemini Pro)

For design-related tasks, prefer Gemini's capabilities:

- **UI/UX review, visual QA** → use `gemini_code` for design code review
- **Design system, brand identity, visual audit** → invoke `/design-review` or `/design-consultation`
- **Design plan review** → invoke `/plan-design-review`
- **스크린샷 분석**: `gemini_vision` 사용 금지 — `Read` 도구로 PNG 직접 읽기

### Design Code Writing with Gemini

When writing design-related code (CSS, styling, UI components, layouts, animations, responsive design), actively use Gemini as a co-pilot:

1. **Before writing**: Use `gemini_prompt` to ask Gemini for the best approach to the UI/layout problem. Include context about the framework (React, Vue, Tailwind, etc.) and the desired result.
2. **During writing**: Use `gemini_code` to review your design code for best practices, accessibility, responsive issues, and cross-browser compatibility.
3. **After writing**: Take a screenshot and use `Read` to evaluate the visual result against the intended design.

**Triggers** (when gemini-mcp is available):
- Writing or modifying CSS, SCSS, Tailwind classes, styled-components, or any styling code → consult `gemini_prompt` first for approach
- Creating UI components (buttons, cards, modals, forms, navigation) → use `gemini_code` to review the component code
- Implementing layouts (grid, flexbox, responsive breakpoints) → ask `gemini_prompt` for optimal layout strategy
- Adding animations or transitions → consult `gemini_prompt` for performance-aware animation patterns
- Fixing visual bugs or alignment issues → screenshot with browse, then `Read` to diagnose
