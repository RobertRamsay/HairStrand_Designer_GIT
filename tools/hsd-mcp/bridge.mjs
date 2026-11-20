/** Hair Strand Designer MCP bridge (adapted from the Amiga Dev Machine's adm-mcp).
 * Node built-ins only; no npm install. MCP stdio is separate from the
 * private, loopback-only app protocol: one shared broker (--broker) owns
 * 127.0.0.1:5180, Hair Strand Designer (obj_mcp) connects to it, and every MCP
 * client talks to the broker. The app reads the same pairing key file, so
 * there is no pairing step. Never log secrets. No automatic edit retries.
 * The commands themselves live in the app: scripts/mcpCommands/mcpCommands.gml.
 */
import net from 'node:net';
import { SharedClient } from './shared-client.mjs';
import { randomBytes, timingSafeEqual } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const VERSION = '1.0.0';
export const MAX_FRAME = 65536;
export const PROTOCOLS = ['2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05'];
const isObject = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const has = (v, k) => Object.prototype.hasOwnProperty.call(v, k);
const validId = v => typeof v === 'string' || (Number.isSafeInteger(v) && v !== null);

/** Byte-level LF framing: split UTF-8 and several messages per packet work. */
export class Lines {
  constructor(onLine, max = MAX_FRAME) {
    this.onLine = onLine; this.max = max; this.parts = []; this.size = 0;
    this.decoder = new TextDecoder('utf-8', { fatal: true });
  }
  push(chunk) {
    let start = 0;
    for (let i = 0; i < chunk.length; i++) {
      if (chunk[i] !== 10) continue;
      this.append(chunk.subarray(start, i));
      const bytes = Buffer.concat(this.parts, this.size);
      this.parts = []; this.size = 0;
      const line = this.decoder.decode(bytes);
      if (line.trim()) this.onLine(line);
      start = i + 1;
    }
    this.append(chunk.subarray(start));
  }
  append(part) {
    if (!part.length) return;
    if (this.size + part.length > this.max) throw new Error('Frame too large');
    this.parts.push(Buffer.from(part)); this.size += part.length;
  }
}

/** The app's save area (GameMaker's game_save_id): %LOCALAPPDATA%\HairStrand_Designer. */
export function defaultTokenFile(env = process.env) {
  const base = env.LOCALAPPDATA || join(homedir(), 'AppData', 'Local');
  return join(base, 'HairStrand_Designer', 'mcp', 'token');
}

export function loadConfig(env = process.env) {
  const port = Number(env.HSD_MCP_PORT ?? 5180);
  if (!Number.isInteger(port) || port < 1024 || port > 65535) {
    throw new Error('HSD_MCP_PORT must be an integer from 1024 to 65535.');
  }
  const tokenFile = env.HSD_MCP_TOKEN_FILE || defaultTokenFile(env);
  let token;
  try { token = readFileSync(tokenFile, 'utf8').trim(); }
  catch (error) {
    if (error.code !== 'ENOENT') throw error;
    mkdirSync(dirname(tokenFile), { recursive: true, mode: 0o700 });
    const generated = randomBytes(32).toString('hex');
    try { writeFileSync(tokenFile, generated + '\n', { flag: 'wx', mode: 0o600 }); }
    catch (writeError) { if (writeError.code !== 'EEXIST') throw writeError; }
    token = readFileSync(tokenFile, 'utf8').trim();
  }
  if (!/^[0-9a-f]{64}$/.test(token)) throw new Error('Invalid local pairing-key file.');
  return { port, token, tokenFile };
}

function tokenMatches(value, expected) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value)
    && timingSafeEqual(Buffer.from(value, 'hex'), Buffer.from(expected, 'hex'));
}

/** The broker: one authenticated app connection, one outstanding app command. */
export class EditorLink {
  // 60 s: one render frame or 4096 PNG write can block the app for many seconds.
  constructor({ port, token, timeoutMs = 60000, heartbeatMs = 2000, log = () => {} }) {
    this.port = port; this.token = token; this.timeoutMs = timeoutMs;
    this.heartbeatMs = heartbeatMs; this.log = log;
    this.socket = null; this.pending = null; this.seq = 0;
    this.sockets = new Set(); this.lastSeen = 0; this.clients = new Set();
    this.server = net.createServer(socket => this.accept(socket));
    this.server.maxConnections = 32;
    this.server.on('error', error => this.log(`Listener error: ${error.code ?? 'unknown'}`));
    this.heartbeat = null;
  }
  async start() {
    await new Promise((resolveReady, reject) => {
      const failed = error => reject(error);
      this.server.once('error', failed);
      this.server.listen({ host: '127.0.0.1', port: this.port, exclusive: true }, () => {
        this.server.off('error', failed); resolveReady();
      });
    });
    this.port = this.server.address().port;
    this.heartbeat = setInterval(() => {
      if (!this.socket) return;
      if (Date.now() - this.lastSeen > 60000) {
        this.drop('Hair Strand Designer heartbeat timed out. The last change may have completed; inspect before retrying.');
      } else this.send({ event: 'heartbeat' });
    }, this.heartbeatMs);
    this.heartbeat.unref();
  }
  accept(socket) {
    if (this.sockets.size >= 32) { socket.destroy(); return; }
    this.sockets.add(socket);
    socket.setNoDelay(true);
    let isClient = false;
    const calls = new Map();
    let lastClientId = 0;
    const authTimer = setTimeout(() => socket.destroy(), 5000);
    const lines = new Lines(line => {
      const message = JSON.parse(line);
      if (!isObject(message)) throw new Error('Invalid message');
      if (isClient) {
        if (message.event === 'cancel') { this.cancel(calls.get(message.id)); return; }
        if (!Number.isSafeInteger(message.id) || message.id <= lastClientId || calls.size >= 8) { socket.destroy(); return; }
        lastClientId = message.id;
        const callId = Symbol('client-call'); calls.set(message.id, callId);
        const finish = reply => {
          calls.delete(message.id);
          if (socket.destroyed) return;
          const data = JSON.stringify({ id: message.id, ...reply }) + '\n';
          if (socket.writableLength > MAX_FRAME * 4) { socket.destroy(); return; }
          socket.write(data);
        };
        Promise.resolve().then(() => {
          if (message.method === 'status') return this.status();
          const args = validateArgs('hsd_' + message.method, message.args ?? {});
          return this.call(message.method, args, callId);
        }).then(result => finish({ ok: true, result }), error => finish({ ok: false, error: error.message }));
        return;
      }
      if (socket !== this.socket && message.event === 'client' && message.protocol === 2 && tokenMatches(message.token, this.token)) {
        clearTimeout(authTimer); isClient = true; this.clients.add(socket);
        socket.write(JSON.stringify({ event: 'client_ready', protocol: 2 }) + '\n'); return;
      }
      if (socket !== this.socket) {
        if (message.event !== 'hello' || message.protocol !== 1 || !tokenMatches(message.token, this.token)) {
          socket.destroy(); return;
        }
        // A restarted app replaces a stale connection.
        if (this.socket) this.drop('Hair Strand Designer reconnected. An in-flight change may have completed; inspect before retrying.');
        clearTimeout(authTimer);
        this.socket = socket; this.seq = 0; this.lastSeen = Date.now();
        this.send({ event: 'ready', protocol: 1 });
        return;
      }
      this.lastSeen = Date.now();
      if (message.event === 'heartbeat') return;
      if (!Number.isSafeInteger(message.id) || typeof message.ok !== 'boolean') throw new Error('Invalid editor response');
      if (this.pending?.seq === message.id) {
        const pending = this.pending; this.pending = null;
        clearTimeout(pending.timer);
        if (message.ok && isObject(message.result)) pending.resolve(message.result);
        else pending.reject(new Error(typeof message.error === 'string' ? message.error : 'Invalid result from Hair Strand Designer'));
      }
    });
    socket.on('data', chunk => { try { lines.push(chunk); } catch { socket.destroy(); } });
    socket.on('error', () => {});
    socket.on('close', () => {
      clearTimeout(authTimer); this.sockets.delete(socket); this.clients.delete(socket);
      for (const callId of calls.values()) this.cancel(callId);
      if (this.socket === socket) {
        this.socket = null;
        this.rejectPending('Hair Strand Designer disconnected. An in-flight change may have completed; inspect before retrying.');
      }
    });
  }
  send(message) {
    if (!this.socket || this.socket.destroyed) return false;
    const data = JSON.stringify({ ...message, token: this.token }) + '\n';
    if (Buffer.byteLength(data) > 32768 || this.socket.writableLength > MAX_FRAME) {
      this.drop('App output queue exceeded limit.'); return false;
    }
    this.socket.write(data);
    return true;
  }
  status() {
    return { bridge: 'hair-strand-designer-mcp', version: VERSION,
      app_connected: !!this.socket && !this.socket.destroyed,
      command_pending: !!this.pending, host: '127.0.0.1', port: this.port,
      note: 'Use hsd_ping to check the running app answers. Hair Strand Designer connects by itself within a few seconds once its MCP link is on (Ctrl+Shift+F10 in the app, or launch it with -mcp). Never paste pairing keys into chat.' };
  }
  request(method, args, callId) {
    if (!this.socket || this.socket.destroyed) return Promise.reject(new Error(
      'Hair Strand Designer is not connected. Start it and switch its MCP link on (Ctrl+Shift+F10, or launch it with -mcp); it connects within a few seconds.'));
    if (this.pending) return Promise.reject(new Error('Another Hair Strand Designer command is still pending.'));
    const seq = ++this.seq;
    return new Promise((resolveResult, reject) => {
      const timer = setTimeout(() => this.drop(
        'Hair Strand Designer did not answer in time. The change may have completed; check with hsd_get_state before retrying.'), this.timeoutMs);
      this.pending = { seq, callId, resolve: resolveResult, reject, timer };
      if (!this.send({ id: seq, method, args })) this.rejectPending('Could not send the command to Hair Strand Designer.');
    });
  }
  async requestWhenFree(method, args, callId) {
    for (let i = 0; i < 100 && this.pending; i++) await new Promise(r => setTimeout(r, 20));
    return this.request(method, args, callId);
  }
  /** A tool call. Most are one command; a few wait for the app to finish
   * something that takes many frames (a render, an export, a save) by polling
   * a read-only status command. Bridge-only arguments are not sent to the app. */
  async call(method, args, callId) {
    const { timeout_seconds, wait, wait_for_preview, ...appArgs } = args;
    const deadline = Date.now() + (timeout_seconds ?? 300) * 1000;
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    const poll = async (statusMethod, busy) => {
      let last;
      for (;;) {
        // The app may briefly drop and rejoin the link during a long render:
        // keep asking until the deadline instead of failing the whole call.
        try { last = await this.requestWhenFree(statusMethod, {}, callId); }
        catch (error) {
          if (Date.now() > deadline) throw error;
          await sleep(1000); continue;
        }
        if (!busy(last)) return last;
        if (Date.now() > deadline) return { ...last, timed_out: true };
        await sleep(500);
      }
    };
    if (method === 'screenshot' && wait_for_preview) {
      const ping = await poll('ping', p => !p.preview_ready && !p.start_screen);
      const shot = await this.requestWhenFree('screenshot', appArgs, callId);
      return ping.timed_out ? { ...shot, preview_wait_timed_out: true } : shot;
    }
    const first = await this.request(method, appArgs, callId);
    if (method === 'generate' && wait !== false) {
      const done = await poll('generate_status', s => s.rendering);
      return { ...first, finished: !done.timed_out, status: done };
    }
    if (method === 'export_maps') {
      const done = await poll('export_status', s => s.active);
      return { ...first, finished: !done.timed_out, result: done };
    }
    if (method === 'save_project' || method === 'load_project') {
      const key = method === 'save_project' ? 'save_pending' : 'load_pending';
      await sleep(100);
      const done = await poll('ping', p => p[key]);
      return { ...first, finished: !done.timed_out };
    }
    return first;
  }
  rejectPending(message) {
    if (!this.pending) return;
    const p = this.pending; this.pending = null;
    clearTimeout(p.timer); p.reject(new Error(message));
  }
  drop(message) {
    this.rejectPending(message);
    const socket = this.socket; this.socket = null;
    socket?.destroy();
  }
  cancel(callId) {
    if (this.pending && this.pending.callId === callId) {
      this.drop('Request cancelled; a started edit cannot be rolled back remotely. Inspect before retrying.');
    }
  }
  async close() {
    clearInterval(this.heartbeat);
    this.drop('Bridge closed.');
    for (const socket of this.sockets) socket.destroy();
    await new Promise(resolveClosed => this.server.close(() => resolveClosed()));
  }
}

// ---------------------------------------------------------------- tool schemas

const schema = (properties = {}, required = []) => ({ type: 'object', properties, required, additionalProperties: false });
const annotations = (readOnly, idempotent = readOnly, destructive = false) => ({
  readOnlyHint: readOnly, destructiveHint: destructive, idempotentHint: idempotent, openWorldHint: false,
});
const setProperty = { type: 'integer', minimum: -1, maximum: 10,
  description: 'Strand set 0-10. Leave out (or -1) to change the global value, which every set follows unless it overrides it.' };
const hexColour = { type: 'string', pattern: '^#?[0-9A-Fa-f]{6}$', description: 'Hex RRGGBB, e.g. "6B4423".' };
const pathProperty = { type: 'string', minLength: 3, maxLength: 400, pattern: '^[^\\u0000-\\u001f"*?<>|]+$' };
const timeout = { type: 'integer', minimum: 5, maximum: 1800, description: 'How long to wait, in seconds (default 300).' };
const MAPS = ['rgb_mask', 'normal', 'mask', 'color', 'id', 'depth', 'flow', 'ao', 'frizz'];
const mapFlags = Object.fromEntries(MAPS.map(m => [m, { type: 'boolean' }]));

export const TOOLS = [
  { name: 'hsd_status', description: 'Bridge and connection status. Does not contact Hair Strand Designer.',
    inputSchema: schema(), annotations: annotations(true) },
  { name: 'hsd_ping', description: 'Ask the running Hair Strand Designer to answer: version, whether it is busy (and why), start screen showing, render / export / save in progress, whether the preview has finished drawing, whether the maps are stale, demo version.',
    inputSchema: schema(), annotations: annotations(true) },
  { name: 'hsd_describe', description: 'Reference: every parameter name with its range, whether it can be set per strand set, and what it does; the colour names; the maps; the options; the usual workflow. Read this before the first change.',
    inputSchema: schema(), annotations: annotations(true) },
  { name: 'hsd_get_state', description: 'The current hair: every global parameter value, colours, each set\'s overrides (parameters, colours, seed, position), options, map states and the last project file.',
    inputSchema: schema(), annotations: annotations(true) },
  { name: 'hsd_start_session', description: 'Dismiss the start screen, as its buttons do: load_autosave=true is LOAD AUTOSAVE (the last session), false is GET STARTED (fresh). Nothing else works while the start screen is up.',
    inputSchema: schema({ load_autosave: { type: 'boolean' } }), annotations: annotations(false, false) },
  { name: 'hsd_set_params', description: 'Move sliders. values is {name: number} (names and ranges from hsd_describe; values are rounded and clamped). Without set, each value is global and copies into every set that has not overridden it; with set (0-10) it overrides that set only. clear (needs set) drops that set\'s overrides so it follows the global again. Also seed (global = every set, like F1; with set = that set only) and x_offset / y_offset (per set, map pixels). Marks the maps stale; the preview redraws by itself (hsd_screenshot wait_for_preview=true shows it).',
    inputSchema: schema({ set: setProperty, values: { type: 'object' },
      clear: { type: 'array', maxItems: 40, items: { type: 'string', minLength: 1, maxLength: 40 } } }),
    annotations: annotations(false, true) },
  { name: 'hsd_set_colours', description: 'Set colours (hex RRGGBB). variation1 / variation2 are the two body tones, root and tip tint the ends, background is behind the hair (global only). Without set they are global (sets that override keep theirs); with set they override that set. clear (needs set) drops that set\'s colour overrides.',
    inputSchema: schema({ set: setProperty, background: hexColour, variation1: hexColour, variation2: hexColour, root: hexColour, tip: hexColour,
      clear: { type: 'array', maxItems: 4, items: { type: 'string', enum: ['variation1', 'variation2', 'root', 'tip'] } } }),
    annotations: annotations(false, true) },
  { name: 'hsd_reset_overrides', description: 'Put one set (or every set, when set is left out) back to the global values: sliders, clumping and colours, as F4 / F5 do. Per-set seeds and positions are kept unless include_seed_and_position=true.',
    inputSchema: schema({ set: setProperty, include_seed_and_position: { type: 'boolean' } }), annotations: annotations(false, true, true) },
  { name: 'hsd_set_options', description: 'Options: strand_type single | multi (multi twists each fibre; curl 0-1), ao_width thin | default | wide | extreme, id_mode per_strand | per_set, flow_flip_x / flow_flip_y / flow_blue / flow_hue, preview_quality fast | med | slow | dyna, preview_update live | busy, preview_smooth, solo_set (-1 all, 0-10 one set in the preview).',
    inputSchema: schema({ strand_type: { type: 'string', enum: ['single', 'multi'] }, curl: { type: 'number', minimum: 0, maximum: 1 },
      ao_width: { type: 'string', enum: ['thin', 'default', 'wide', 'extreme'] }, id_mode: { type: 'string', enum: ['per_strand', 'per_set'] },
      flow_flip_x: { type: 'boolean' }, flow_flip_y: { type: 'boolean' }, flow_blue: { type: 'boolean' }, flow_hue: { type: 'boolean' },
      preview_quality: { type: 'string', enum: ['fast', 'med', 'slow', 'dyna'] }, preview_update: { type: 'string', enum: ['live', 'busy'] },
      preview_smooth: { type: 'boolean' }, solo_set: { type: 'integer', minimum: -1, maximum: 10 } }),
    annotations: annotations(false, true) },
  { name: 'hsd_set_maps', description: 'Choose which 4096x4096 maps Generate makes (the tick boxes): rgb_mask, normal, mask, color, id, depth, flow, ao, frizz. true enables, false disables; maps not named are left as they are.',
    inputSchema: schema(mapFlags), annotations: annotations(false, true) },
  { name: 'hsd_generate', description: 'Render the enabled maps that are due, at 4096x4096 (the G key). Waits until the render finishes (wait=false returns at once; hsd_generate_status then reports progress). force=true redraws maps that are already up to date. Takes from a few seconds to a minute or more, depending on strands, length and maps.',
    inputSchema: schema({ force: { type: 'boolean' }, wait: { type: 'boolean' }, timeout_seconds: timeout }), annotations: annotations(false, false) },
  { name: 'hsd_generate_status', description: 'Whether a render is running, which set it is drawing, and each map\'s state (off, due, generated).',
    inputSchema: schema(), annotations: annotations(true) },
  { name: 'hsd_export_maps', description: 'Write generated maps as 4096x4096 PNG files <folder>/<name><suffix>.png (suffixes _RGBMask, _Normal, _Mask, _Color, _ID, _Depth, _Flow, _AO, _Frizz, as the S key uses). maps limits which (default: every generated one). Existing files are kept unless overwrite=true. Waits until every file is written. Not available in the demo.',
    inputSchema: schema({ folder: pathProperty, name: { type: 'string', minLength: 1, maxLength: 80, pattern: '^[A-Za-z0-9 _.-]+$' },
      maps: { type: 'array', maxItems: 9, items: { type: 'string', enum: MAPS } }, overwrite: { type: 'boolean' }, timeout_seconds: timeout },
      ['folder', 'name']), annotations: annotations(false, false) },
  { name: 'hsd_save_project', description: 'Save the project file (.txt, the S key without its dialog): every setting, per-set overrides, colours, clumping and seeds. Existing files are kept unless overwrite=true. Not available in the demo.',
    inputSchema: schema({ path: pathProperty, overwrite: { type: 'boolean' } }, ['path']), annotations: annotations(false, true) },
  { name: 'hsd_load_project', description: 'Load a project file (the L key without its dialog). It REPLACES the hair now in the app (the autosave keeps the previous state only until the next change), so ask the user first and pass replace_current=true.',
    inputSchema: schema({ path: pathProperty, replace_current: { type: 'boolean' } }, ['path']), annotations: annotations(false, false, true) },
  { name: 'hsd_screenshot', description: 'A picture, returned as an image. view: preview (the hair preview canvas, default), window (the whole app as the user sees it), or a map name (the 4096 map scaled down; shows the last render). size 256-2048 (default 1024). wait_for_preview=true first waits until the preview has finished growing in.',
    inputSchema: schema({ view: { type: 'string', enum: ['preview', 'window', ...MAPS] }, size: { type: 'integer', minimum: 256, maximum: 2048 },
      wait_for_preview: { type: 'boolean' }, timeout_seconds: timeout }), annotations: annotations(true) },
];

export function validateArgs(name, value = {}) {
  const tool = TOOLS.find(t => t.name === name);
  if (!tool) throw new Error('Unknown tool.');
  if (!isObject(value)) throw new Error('Tool arguments must be an object.');
  function check(spec, v, key, depth = 0) {
    if (depth > 32) throw new Error('Invalid ' + key + ': nested too deeply.');
    if (!spec.type && !spec.enum) { jsonValue(v, key, depth); return; }
    if (spec.type === 'object' && !spec.properties) {
      if (!isObject(v)) throw new Error('Invalid ' + key + '.');
      jsonValue(v, key, depth); return;
    }
    if (spec.enum && !spec.enum.includes(v)) throw new Error('Invalid ' + key + ': one of ' + spec.enum.join(', ') + '.');
    if (spec.type === 'object') {
      if (!isObject(v)) throw new Error('Invalid ' + key + '.');
      for (const k of Object.keys(v)) if (!has(spec.properties, k)) throw new Error('Unexpected argument: ' + k);
      for (const k of spec.required ?? []) if (!has(v, k)) throw new Error('Missing argument: ' + k);
      for (const [k, x] of Object.entries(v)) check(spec.properties[k], x, k, depth + 1);
    } else if (spec.type === 'array') {
      if (!Array.isArray(v) || v.length < (spec.minItems ?? 0) || v.length > (spec.maxItems ?? Infinity)) throw new Error('Invalid ' + key + '.');
      for (const x of v) check(spec.items, x, key, depth + 1);
    } else if (spec.type === 'boolean') {
      if (typeof v !== 'boolean') throw new Error('Invalid ' + key + '.');
    } else if (spec.type === 'string') {
      if (typeof v !== 'string' || v.includes('\0') || v.length < (spec.minLength ?? 0) || v.length > (spec.maxLength ?? Infinity)
        || (spec.pattern && !new RegExp(spec.pattern).test(v))) throw new Error('Invalid ' + key + '.');
    } else if (typeof v !== 'number' || !Number.isFinite(v) || (spec.type === 'integer' && !Number.isSafeInteger(v))
      || v < (spec.minimum ?? -Infinity) || v > (spec.maximum ?? Infinity)) throw new Error('Invalid ' + key + '.');
  }
  function jsonValue(v, key, depth) {
    if (depth > 32) throw new Error('Invalid ' + key + ': nested too deeply.');
    if (v === null || typeof v === 'boolean' || typeof v === 'string') return;
    if (typeof v === 'number') { if (!Number.isFinite(v)) throw new Error('Invalid ' + key + '.'); return; }
    if (Array.isArray(v)) { for (const x of v) jsonValue(x, key, depth + 1); return; }
    if (isObject(v)) { for (const x of Object.values(v)) jsonValue(x, key, depth + 1); return; }
    throw new Error('Invalid ' + key + '.');
  }
  check(tool.inputSchema, value, 'arguments');
  if (Buffer.byteLength(JSON.stringify(value), 'utf8') > 28000) throw new Error('Command exceeds 28000 UTF-8 bytes; split the edit.');
  return value;
}

/** A PNG the app saved, as MCP image content (when it is small enough). */
function imageContent(path) {
  try {
    if (statSync(path).size > 4 * 1024 * 1024) return null;
    return { type: 'image', data: readFileSync(path).toString('base64'), mimeType: 'image/png' };
  } catch { return null; }
}

/** Minimal tools-only MCP server. */
export class McpServer {
  constructor(link, write) { this.link = link; this.write = write; this.state = 'new'; this.active = new Set(); }
  result(id, result) { this.write({ jsonrpc: '2.0', id, result }); }
  error(id, code, message) { this.write({ jsonrpc: '2.0', id, error: { code, message } }); }
  async handle(message) {
    if (!isObject(message) || message.jsonrpc !== '2.0' || typeof message.method !== 'string'
        || (has(message, 'id') && !validId(message.id))) {
      this.error(null, -32600, 'Invalid JSON-RPC request'); return;
    }
    const { method, id } = message;
    if (!has(message, 'id')) {
      if (method === 'notifications/initialized' && this.state === 'initialized') this.state = 'ready';
      if (method === 'notifications/cancelled') this.link.cancel(message.params?.requestId);
      return;
    }
    if (this.active.has(id)) { this.error(id, -32600, 'Duplicate in-flight request ID'); return; }
    if (this.active.size >= 8) { this.error(id, -32600, 'Too many requests'); return; }
    this.active.add(id);
    try {
      if (method === 'initialize') {
        const p = message.params;
        if (this.state !== 'new' || !isObject(p) || typeof p.protocolVersion !== 'string') {
          this.error(id, -32602, 'Invalid initialize request'); return;
        }
        this.state = 'initialized';
        this.result(id, { protocolVersion: PROTOCOLS.includes(p.protocolVersion) ? p.protocolVersion : PROTOCOLS[0],
          capabilities: { tools: { listChanged: false } },
          serverInfo: { name: 'hair-strand-designer-mcp', version: VERSION },
          instructions: 'Hair Strand Designer control: it makes 4096x4096 hair textures (colour, normal, mask, AO, depth, flow, ID, frizz and RGB mask maps) from 11 strand sets. Call hsd_describe once for parameter names and ranges, hsd_get_state to see the current hair, and hsd_start_session if the start screen is up. Change the hair with hsd_set_params / hsd_set_colours / hsd_set_options, check it with hsd_screenshot (wait_for_preview=true), then hsd_set_maps, hsd_generate and hsd_export_maps. Only save, load, overwrite or export where the user asked. hsd_load_project replaces the current hair: ask first. If the app says it is busy because of something the user is doing, tell them rather than retrying. Never retry a change after a timeout; check hsd_get_state first. Keep pairing keys private.' });
      } else if (method === 'ping') this.result(id, {});
      else if (this.state !== 'ready') this.error(id, -32002, 'Initialize MCP first');
      else if (method === 'tools/list') this.result(id, { tools: TOOLS });
      else if (method === 'tools/call') {
        const p = message.params;
        if (!isObject(p) || typeof p.name !== 'string' || !TOOLS.some(t => t.name === p.name)) {
          this.error(id, -32602, 'Unknown or missing tool name'); return;
        }
        try {
          const args = validateArgs(p.name, p.arguments ?? {});
          const result = p.name === 'hsd_status' ? await this.link.status()
            : await this.link.request(p.name.slice(4), args, id);
          const content = [{ type: 'text', text: JSON.stringify(result) }];
          if (p.name === 'hsd_screenshot' && typeof result.path === 'string') {
            const image = imageContent(result.path);
            if (image) content.push(image);
          }
          this.result(id, { content, isError: false });
        } catch (error) {
          this.result(id, { content: [{ type: 'text', text: error.message }], isError: true });
        }
      } else this.error(id, -32601, 'Method not found');
    } finally { this.active.delete(id); }
  }
}

export async function main(argv = process.argv.slice(2)) {
  const config = loadConfig();
  const self = fileURLToPath(import.meta.url);
  if (argv.length === 1 && argv[0] === '--claude-config') {
    process.stdout.write(JSON.stringify({ mcpServers: { 'hair-strand-designer': {
      command: process.execPath, args: [self], env: { HSD_MCP_PORT: String(config.port) },
    } } }, null, 2) + '\n'); return;
  }
  if (argv.length === 1 && argv[0] === '--broker') {
    const broker = new EditorLink(config);
    await broker.start();
    // The broker stays while clients use it, and a while after, so the app keeps its link.
    let idleSince = Date.now();
    const idle = setInterval(() => {
      if (broker.clients.size) idleSince = Date.now();
      if (Date.now() - idleSince > 600000) { clearInterval(idle); void broker.close(); }
    }, 1000);
    process.once('SIGTERM', () => { clearInterval(idle); void broker.close(); });
    return;
  }
  if (argv.length) throw new Error('Usage: node bridge.mjs [--claude-config | --broker]');
  const link = new SharedClient(config, Lines);
  await link.start(self);
  let closing = false;
  const close = async () => {
    if (closing) return; closing = true; process.stdin.pause();
    await link.close();
  };
  const server = new McpServer(link, message => {
    if (closing) return;
    if (process.stdout.writableLength > MAX_FRAME * 512) { void close(); return; }
    process.stdout.write(JSON.stringify(message) + '\n');
  });
  const lines = new Lines(line => {
    let parsed;
    try { parsed = JSON.parse(line); }
    catch { server.error(null, -32700, 'Parse error'); return; }
    void server.handle(parsed).catch(() => { void close(); });
  }, MAX_FRAME * 8);
  process.stdin.on('data', chunk => {
    try { lines.push(chunk); }
    catch { server.error(null, -32600, 'Invalid or oversized UTF-8 frame'); void close(); }
  });
  process.stdin.on('end', () => { void close(); });
  process.stdin.on('error', () => { void close(); });
  process.stdout.on('error', () => { void close(); });
  process.once('SIGINT', () => { void close(); });
  process.once('SIGTERM', () => { void close(); });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => {
    process.stderr.write(`[HSD MCP] ${error.code === 'EADDRINUSE'
      ? 'Port is already in use; run only one broker (or set HSD_MCP_PORT).'
      : error.message}\n`);
    process.exitCode = 1;
  });
}
