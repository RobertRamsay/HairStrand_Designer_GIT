#!/usr/bin/env node
/** Call one Hair Strand Designer MCP tool from a terminal, for checking the link.
 *   node tools/hsd-mcp/call.mjs hsd_ping
 *   node tools/hsd-mcp/call.mjs hsd_set_params "{\"values\":{\"waviness\":40}}"
 *   node tools/hsd-mcp/call.mjs hsd_screenshot "{\"view\":\"preview\"}" --out shot.png
 * Runs bridge.mjs as an MCP server over stdio, exactly as Claude Code does.
 * Prints the result; --out saves a returned image.
 */
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { writeFileSync } from 'node:fs';

const [name, json, ...rest] = process.argv.slice(2);
if (!name) { console.log('usage: call.mjs <tool> [json args] [--out file.png]'); process.exit(2); }
const outAt = rest.indexOf('--out');
const out = outAt >= 0 ? rest[outAt + 1] : null;
const args = json && json !== '--out' ? JSON.parse(json) : {};

const here = dirname(fileURLToPath(import.meta.url));
const child = spawn(process.execPath, [join(here, 'bridge.mjs')], { stdio: ['pipe', 'pipe', 'inherit'] });
let buf = '';
const waiting = new Map();
child.stdout.on('data', d => {
  buf += d;
  let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const m = JSON.parse(buf.slice(0, i)); buf = buf.slice(i + 1);
    waiting.get(m.id)?.(m); waiting.delete(m.id);
  }
});
let seq = 0;
const rpc = (method, params) => new Promise(r => { const id = ++seq; waiting.set(id, r); child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n'); });

await rpc('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'call', version: '1' } });
child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
// Give the app a moment to (re)connect to a freshly started broker.
for (let i = 0; i < 20 && name !== 'hsd_status'; i++) {
  const s = await rpc('tools/call', { name: 'hsd_status', arguments: {} });
  if (JSON.parse(s.result.content[0].text).app_connected) break;
  await new Promise(r => setTimeout(r, 500));
}
const m = await rpc('tools/call', { name, arguments: args });
for (const c of m.result.content) {
  if (c.type === 'text') console.log(m.result.isError ? 'ERROR: ' + c.text : c.text);
  if (c.type === 'image' && out) { writeFileSync(out, Buffer.from(c.data, 'base64')); console.log('image saved to', out); }
}
child.kill();
process.exitCode = m.result.isError ? 1 : 0;
