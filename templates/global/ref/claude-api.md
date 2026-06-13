# Anthropic API Tool Use 상세 레퍼런스

> 글로벌 CLAUDE.md "Anthropic API Tool Use" 섹션의 상세 패턴/코드.
> Claude API 앱(코드가 `anthropic` / `@anthropic-ai/sdk` import) 작성 시 `/claude-api` 스킬 또는 아래 패턴 사용.
> 핵심 설계 규칙(1 tool = 1 atomic action, description이 호출 시점 결정, 도구는 무엇이든 가능)은 CLAUDE.md 본문에 있다.

## Tool Registration Flow

```
User code → [tools + messages] → Claude
Claude → [tool_use block] → User code
User code → [executes tool locally] → result
User code → [tool_result] → Claude
Claude → [final answer] → User code
```

## Tool Definition Structure

```python
{
    "name": "tool_name",           # Claude uses this to call it
    "description": "When exactly to use this tool, in what situation",  # most important
    "input_schema": {
        "type": "object",
        "properties": {
            "param": {"type": "string", "description": "..."}
        },
        "required": ["param"]
    }
}
```

## Agent Loop Pattern

```python
messages = [{"role": "user", "content": user_input}]
while True:
    response = client.messages.create(model=..., tools=tools, messages=messages)
    if response.stop_reason != "tool_use":
        break
    # execute all tool_use blocks
    tool_results = []
    for block in response.content:
        if block.type == "tool_use":
            result = execute_tool(block.name, block.input)
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": result
            })
    messages.append({"role": "assistant", "content": response.content})
    messages.append({"role": "user", "content": tool_results})
```

## Design Rules

- One tool = one atomic action. Never bundle multiple actions in one tool.
- `description` determines when Claude calls the tool. Be specific: "Use when user asks X" > "Does X".
- Tools can be anything: file I/O, DB queries, web requests, shell commands, external APIs.
