import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { stateToolDefs, handleStateTool } from './tools/state.js';
import { gateToolDefs, handleGateTool } from './tools/gate.js';
import { spawnToolDefs, handleSpawnTool } from './tools/spawn.js';

export async function mcpServe(): Promise<void> {
  const server = new Server(
    { name: 'collar', version: '0.1.0' },
    { capabilities: { tools: {} } }
  );

  const allTools = [...stateToolDefs, ...gateToolDefs, ...spawnToolDefs];

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: allTools,
  }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    const safeArgs = (args ?? {}) as Record<string, unknown>;

    try {
      let result: unknown;
      if (stateToolDefs.some(t => t.name === name)) {
        result = handleStateTool(name, safeArgs);
      } else if (gateToolDefs.some(t => t.name === name)) {
        result = handleGateTool(name, safeArgs);
      } else if (spawnToolDefs.some(t => t.name === name)) {
        result = handleSpawnTool(name, safeArgs);
      } else {
        throw new Error(`Unknown tool: ${name}`);
      }
      return { content: [{ type: 'text' as const, text: JSON.stringify(result) }] };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return { content: [{ type: 'text' as const, text: JSON.stringify({ error: message }) }], isError: true };
    }
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
}
