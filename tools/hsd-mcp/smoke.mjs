#!/usr/bin/env node
/** Smoke test: runs bridge.mjs as an MCP server over stdio and calls the tools.
 *   node tools/hsd-mcp/smoke.mjs                 read-only checks
 *   node tools/hsd-mcp/smoke.mjs --edit <dir>    also edits the hair, generates two
 *                                                maps, exports them and saves /
 *                                                reloads a project, all inside <dir>.
 * Needs Hair Strand Designer running with its MCP link on (-mcp or Ctrl+Shift+F10).
 * --edit CHANGES THE HAIR IN THE APP (and so the autosave): back up
 * %LOCALAPPDATA%\HairStrand_Designer\Autosave.txt first if it matters.
 * Prints results, never the pairing key.
 */
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { existsSync, statSync } from 'node:fs';

const here = dirname(fileURLToPath(import.meta.url));
const editAt = process.argv.indexOf('--edit');
const edit = editAt >= 0;
const workDir = edit ? process.argv[editAt + 1] : null;
if (edit && !workDir) { console.log('usage: smoke.mjs --edit <folder>'); process.exit(2); }

const child = spawn(process.execPath, [join(here, 'bridge.mjs')], { stdio: ['pipe', 'pipe', 'inherit'] });
let buf = '';
const waiting = new Map();
child.stdout.on('data', d => {
  buf += d;
  let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i); buf = buf.slice(i + 1);
    const m = JSON.parse(line);
    waiting.get(m.id)?.(m); waiting.delete(m.id);
  }
});
let seq = 0;
const rpc = (method, params) => new Promise(r => { const id = ++seq; waiting.set(id, r); child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n'); });
const call = async (name, args = {}) => {
  const m = await rpc('tools/call', { name, arguments: args });
  const c = m.result.content;
  const text = c[0].text;
  const images = c.filter(x => x.type === 'image');
  let value; try { value = JSON.parse(text); } catch { value = text; }
  return { error: m.result.isError, value, images: images.length, imageBytes: images[0] ? images[0].data.length * 0.75 : 0 };
};
const show = (label, r) => console.log(label.padEnd(18), r.error ? 'ERROR: ' + r.value : JSON.stringify(r.value).slice(0, 400), r.images ? `[+image ${Math.round(r.imageBytes / 1024)} KB]` : '');
const fail = msg => { console.log('FAIL', msg); process.exitCode = 1; };
const expect = (label, r, ok = !r.error) => { show(label, r); if (!ok) fail(label); return r; };

await rpc('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'smoke', version: '1' } });
child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
const tools = await rpc('tools/list', {});
console.log('tools', tools.result.tools.length);

let st;
for (let i = 0; i < 40; i++) {
  st = await call('hsd_status');
  if (st.value.app_connected) break;
  await new Promise(r => setTimeout(r, 1000));
}
show('status', st);
if (!st.value.app_connected) { fail('Hair Strand Designer did not connect'); child.kill(); process.exit(); }

let ping = expect('ping', await call('hsd_ping'));
expect('describe', await call('hsd_describe'));
expect('get_state', await call('hsd_get_state'));
expect('bad param', await call('hsd_set_params', { values: { nonsense: 3 } }), true);

if (edit) {
  if (ping.value.start_screen) expect('start_session', await call('hsd_start_session', { load_autosave: false }));
  expect('set global', await call('hsd_set_params', { values: { strands: 40, waviness: 35, clump_amount: 20, clump_count: 5, wave_freq_min: 30, wave_freq_max: 35 } }));
  expect('set set 3', await call('hsd_set_params', { set: 3, values: { length: 1900, thickness_min: 3, thickness_max: 6, seed: 4242, x_offset: 100 } }));
  expect('min>max refused', await call('hsd_set_params', { values: { thickness_min: 9, thickness_max: 4 } }), true);
  expect('colours', await call('hsd_set_colours', { background: '200A05', variation1: '6B4423', variation2: '8A5A2B', root: '2A1810', tip: 'C8A070' }));
  expect('colour set 3', await call('hsd_set_colours', { set: 3, tip: 'F0D090' }));
  expect('options', await call('hsd_set_options', { ao_width: 'wide', preview_quality: 'slow' }));
  const state = expect('get_state', await call('hsd_get_state'));
  const s3 = state.value.sets[3];
  if (s3.overrides.length !== 1900 || s3.seed !== 4242 || s3.colour_overrides.tip !== 'F0D090') fail('set 3 overrides not as set: ' + JSON.stringify(s3));
  if (state.value.globals.waviness !== 35 || state.value.sets[0].overrides.waviness !== undefined) fail('global waviness not applied');
  const shot = expect('preview shot', await call('hsd_screenshot', { view: 'preview', size: 512, wait_for_preview: true }));
  if (shot.images !== 1) fail('no preview image');
  expect('window shot', await call('hsd_screenshot', { view: 'window' }));
  expect('maps', await call('hsd_set_maps', { rgb_mask: false, normal: false, mask: true, color: true, id: false, depth: false, flow: false, ao: false, frizz: false }));
  const gen = expect('generate', await call('hsd_generate', { timeout_seconds: 240 }));
  if (!gen.value.finished) fail('render did not finish');
  const cshot = expect('colour map shot', await call('hsd_screenshot', { view: 'color', size: 512 }));
  if (cshot.images !== 1) fail('no colour map image');
  const ex = expect('export', await call('hsd_export_maps', { folder: workDir, name: 'smoke', overwrite: true }));
  for (const f of ['smoke_Color.png', 'smoke_Mask.png']) {
    const p = join(workDir, f);
    if (!existsSync(p) || statSync(p).size < 10000) fail('missing or tiny ' + p); else console.log('  wrote', f, Math.round(statSync(p).size / 1024), 'KB');
  }
  expect('export again (no overwrite)', await call('hsd_export_maps', { folder: workDir, name: 'smoke' }), true);
  const proj = join(workDir, 'smoke_project.txt');
  expect('save', await call('hsd_save_project', { path: proj, overwrite: true }));
  expect('change after save', await call('hsd_set_params', { values: { waviness: 80 } }));
  expect('load refused', await call('hsd_load_project', { path: proj }), true);
  expect('load', await call('hsd_load_project', { path: proj, replace_current: true }));
  const back = expect('state after load', await call('hsd_get_state'));
  if (back.value.globals.waviness !== 35) fail('load did not restore waviness 35: ' + back.value.globals.waviness);
  const b3 = back.value.sets[3];
  if (b3.seed !== 4242 || b3.colour_overrides.tip !== 'F0D090' || back.value.globals.clump_amount !== 20) fail('load did not restore set 3 / clumping: ' + JSON.stringify(b3));
  expect('reset set 3', await call('hsd_reset_overrides', { set: 3 }));
  const after = expect('state after reset', await call('hsd_get_state'));
  if (Object.keys(after.value.sets[3].overrides).length) fail('set 3 still has overrides');
}
child.kill();
console.log(process.exitCode ? 'SMOKE FAILED' : 'SMOKE OK');
