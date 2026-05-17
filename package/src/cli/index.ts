#!/usr/bin/env node
import { program } from 'commander';
import { setup } from './setup.js';
import { init } from './init.js';
import { doctor } from './doctor.js';
import { update } from './update.js';
import { globalCmd } from './global.js';
import { mcpServe } from '../mcp/server.js';

program.name('collar').version('0.1.0').description('AI harness standardization layer for Claude Code');

program.command('setup').description('Install collar globally (MCP + hooks registration)').action(setup);
program.command('init [path]').description('Initialize collar in a project').action(init);
program.command('doctor').description('Verify collar installation').action(doctor);
program.command('update').description('Update collar and re-run setup').action(update);
program.command('global').option('--force', 'Force re-apply').description('Apply global rules to all projects').action(globalCmd);
program.command('mcp-serve').description('Start MCP server (stdio)').action(mcpServe);

program.parse();
