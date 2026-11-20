# Hair Strand Designer MCP bridge

Lets Claude Code (or any MCP client) drive a running Hair Strand Designer: shape
the hair, set colours, look at the preview, generate the 4096 x 4096 maps and
export them. Made so HairBrush sessions can get the hair textures they need
without anyone working the sliders by hand. Node built-ins only (Node 18+), no
`npm install`. Adapted from the Amiga Dev Machine's `adm-mcp`.

## How it fits together

```
Claude Code --stdio--> bridge.mjs --TCP--> broker (bridge.mjs --broker, 127.0.0.1:5180) <--TCP-- Hair Strand Designer (obj_mcp)
```

- The first `bridge.mjs` starts a shared broker in the background; every MCP
  client talks to it, and the broker keeps one link to the app. It stops 10
  minutes after the last client leaves.
- **Pairing:** the broker creates a random 64-hex key in
  `%LOCALAPPDATA%\HairStrand_Designer\mcp\token` (the app's save area). The app
  reads the same file, so there is nothing to copy. Never paste the key anywhere.
- **The app side is off by default.** Switch it on with **Ctrl+Shift+F10** in
  Hair Strand Designer (remembered in `HSD_Settings.ini`, `[mcp] enabled`), or
  for one session by launching with `-mcp`. While it is on, a small tab at the
  top of the preview says MCP LINKED (green) or MCP WAITING (amber).
- One command runs per frame on the app's main thread
  (`scripts/mcpCommands/mcpCommands.gml`). Changes are refused while the start
  screen, the mixer editor or the quit dialog is up, while a render, export,
  save or load is running, or while a mouse button is held in the app.
- Every change goes through the same variables and events the UI uses, so
  overrides, the preview, autosave and project files behave exactly as if the
  sliders had been moved by hand. A change deselects any set in the UI.

## Set up

```
claude mcp add --scope user hair-strand-designer -- "C:\Program Files\nodejs\node.exe" "D:\POLYTRICITY\HairStrand_Designer\tools\hsd-mcp\bridge.mjs"
```

(`node bridge.mjs --claude-config` prints the same as JSON.) `HSD_MCP_PORT` and
`HSD_MCP_TOKEN_FILE` override the port and key file.

## Tools

| Tool | What it does |
|---|---|
| `hsd_status`, `hsd_ping` | link state; the app answers, says whether it is busy and why |
| `hsd_describe` | every parameter with its range and meaning, colours, maps, options, workflow |
| `hsd_get_state` | the current hair: globals, colours, each set's overrides, options, map states |
| `hsd_start_session` | LOAD AUTOSAVE or GET STARTED on the start screen |
| `hsd_set_params` | sliders, globally or for one set (0-10); `clear` drops a set's overrides; also seeds and set positions |
| `hsd_set_colours` | background, variation 1 / 2, root and tip, globally or per set |
| `hsd_reset_overrides` | one set or all back to the globals (F4 / F5) |
| `hsd_set_options` | strand type and curl, AO width, ID / flow modes, preview quality, live / busy, smoothing, solo set |
| `hsd_set_maps` | which maps Generate makes |
| `hsd_generate`, `hsd_generate_status` | render the due maps at 4096 (waits until done by default) |
| `hsd_export_maps` | write generated maps as `<name>_Color.png` etc. into a folder |
| `hsd_save_project`, `hsd_load_project` | project files without the dialogs (loading needs `replace_current=true`) |
| `hsd_screenshot` | the preview, the whole window, or a map, returned as an image |

Parameter names match the slider rows: `strands`, `length`, `spacing`,
`distance`, `waviness`, `wave_freq_min` / `_max`, `tapering`, `variation`,
`root_jitter`, `thickness_min` / `_max`, `thick_adj_left` / `_right`,
`thickness_variance`, `fade_root` / `_tip`, `noise_amount` / `_frequency`,
`mixer1_amount` ... `mixer3_offset`, `clump_amount` / `_count` / `_start` /
`_scatter`, `root_coverage`, `tip_coverage`, plus `seed`, `x_offset`, `y_offset`.

## Test

With Hair Strand Designer running and its link on:

- `node tools/hsd-mcp/call.mjs hsd_ping` calls one tool
  (`... hsd_screenshot "{\"view\":\"preview\"}" --out shot.png` saves the image).
- `node tools/hsd-mcp/smoke.mjs` runs read-only checks.
- `node tools/hsd-mcp/smoke.mjs --edit <folder>` also changes the hair,
  renders two maps, exports them and saves / reloads a project in `<folder>`.
  **It changes the hair in the app and so the autosave**: back up
  `Autosave.txt` first if it matters.

## Adding to it

- A new slider: add a line to `mcp_param_table()` in `mcpCommands.gml`. It is
  then settable, resettable and listed by `hsd_describe` with no other change.
- A new map: add it to `mcp_map_table()` (and to `MAPS` in `bridge.mjs`).
- A new command: a `case` in `mcp_dispatch()`, plus a tool entry in `TOOLS` in
  `bridge.mjs` (named `hsd_` + the command name).
