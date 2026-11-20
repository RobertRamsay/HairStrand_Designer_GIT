# Hair Strand Designer - developer guide

A map of the source for finding your way around and diagnosing problems.
Every source file also has a header comment saying what it does, when it runs
and what it reads and writes; this guide is the overview that ties them together.

Written for version 1.96 (November 2026).

## 1. The shape of the program

- It is a GameMaker project. Almost everything happens in one object,
  **`obj_surfaceDweller`**, and the scripts it calls run in its scope (they read
  and write its instance variables directly).
- Rooms: `PreRoom` (`obj_windowSetup` sizes the window, then goes on) ->
  `Room_HSD` (the application) <-> `Room_PathEditing` (the mixer curve editor,
  `obj_pathEdit`).
- The UI is a 1920 x 1080 room. The control panel is **one baked sprite,
  `spr_UI`**, so every click rectangle in the code is a hard-coded position that
  matches the artwork. Slider rows sit at `y = 436 + 28 * row`.
- The hair is 11 **sets** (index 0-10; the arrays are sized `maxSets`). A value
  is either global or overridden per set: per-set values live in arrays named
  `set...Adj[]` / `strandSet...Adj[]` with a matching `set...Overrode[]` flag.
  `setSelectedID` is the selected set, or -1 for none.
- Two renderers draw the same hair:
  - the **preview** (1024 x 1024 surfaces, `previewSurf[0..10]`, one per set),
  - the **final render** (4096 x 4096 canvases, one per map).
  They share per-set **pre-random tables** (`preRand*[set, strand]`) so a strand
  is the same strand in both. A formula changed in one must be changed in the other.

### One frame, in order

| Event | File | What happens |
|---|---|---|
| Begin Step | `obj_surfaceDweller/Step_1.gml`, `g/Step_1.gml` | Keys (F2-F5), surface-loss check, colour-change snapshot for saving |
| Step | `obj_surfaceDweller/Step_0.gml` | Colour slot handling, F4 / F5 colour resets |
| End Step | `obj_surfaceDweller/Step_2.gml` -> `doMainStep()` | Surface check, autoload at start-up, pre-random refresh, autosave on mouse release, and **the final render, one set per step** |
| Draw | `obj_surfaceDweller/Draw_0.gml` | The whole UI and its input; calls `mainCalc()` which updates and composites the preview |
| Draw GUI | `obj_surfaceDweller/Draw_64.gml`, `obj_copy/Draw_64.gml` | Version text, function-key buttons, AO width button, COPY / PASTE |
| Alarm 1 | `obj_surfaceDweller/Alarm_1.gml` | Save / load post-processing (see section 5) |

## 2. Where to look

| I want to change or debug... | Look in |
|---|---|
| A variable: what it is, its range, its default | `objects/obj_surfaceDweller/Create_0.gml` (grouped and commented) |
| A slider, button, text box, the splash, the help panel | `objects/obj_surfaceDweller/Draw_0.gml` (table of contents in its header) |
| The helper tips on the bottom bar | `scripts/uiTips/uiTips.gml` |
| The function-key buttons, AO width button | `objects/obj_surfaceDweller/Draw_64.gml` |
| What a key does | `objects/obj_surfaceDweller/KeyPress_<keycode>.gml` (76 = L, 83 = S, 117-120 = F6-F9) |
| The preview: live / busy update, grow-in, speed | `scripts/previewJob/previewJob.gml`, `scripts/mainCalc/mainCalc.gml` |
| The preview smoothing shader | `shaders/shd_previewSmooth` |
| The generated maps | `scripts/doMainStep/doMainStep.gml` (pipeline outline in its header) |
| Clumping | `scripts/clumpTools/clumpTools.gml` |
| The random values each strand gets | `scripts/updatePreRands/updatePreRands.gml` |
| Selecting, moving, soloing sets | `scripts/checkAndOffset/checkAndOffset.gml`, `scripts/doHighlighting/doHighlighting.gml` |
| COPY / PASTE of a set | `objects/obj_copy/Draw_64.gml` |
| Autosave / autoload | `scripts/doAutoSave`, `scripts/doAutoLoad` |
| Manual save (S) / load (L) | `KeyPress_83.gml`, `KeyPress_76.gml`, `Alarm_1.gml`, `scripts/projectExtras`, clump block in `scripts/clumpTools` |
| Exporting one map | `scripts/exportIndividual/exportIndividual.gml` |
| The 4096 surfaces: creation, loss, recovery | `scripts/setupCanvases`, `canvasCheck`, `killSurfaces` |
| The mixer curve editor | `objects/obj_pathEdit` |
| The panel artwork, logo, buttons, help panel image | `tools/ui_art/*.py` (run from the project root) |
| Claude / MCP control (V1.97) | `objects/obj_mcp` (the link), `scripts/mcpCommands` (the commands), `tools/hsd-mcp` (the Node bridge and its README) |

## 3. The final render (`doMainStep`)

`img` is the map on view: 0 RGB, 1 normal, 2 ID, 3 depth, 4 colour, 5 mask,
6 flow, 7 AO, 8 frizz, 9 previewer. Each map has a tick box (`doRGB` ...
`doFrizz`) and a state `*_GenState`: 0 off, 1 due, 2 generated.

```
every step    canvasCheck -> autoload -> preRandsRefresh -> autosave on mouse release
              -> colour-write alpha switched OFF (and left off)
render start  (renderF == 0) fill each due map with its background
per set       seed the random stream, mixerCacheBuild, clumpPrepareSet     <- ONE SET PER STEP
per strand    all per-strand values come from preRand*[set, strand]
per point     pass 1: thickness, colours, fade, then the path:
              wave -> mixers -> waviness / variation -> taper -> noise -> set offset -> clump pull
              (stored in pt_* arrays)
per map       pass 2: one sprite per point into each due map's canvas
end of set    renderF++, and return until the next step
finish        flow blue overwash -> GenStates 1 -> 2 -> canSave, pleaseGen = false
```

`pleaseGen` means "settings changed, the maps are stale". Draw_0 uses it to drop
every generated map from state 2 back to its tick value.

## 4. The preview (`previewJob`)

- `previewUpdate()` runs every frame from `mainCalc()`. Each set has a
  **signature** (`previewSetSig`) built from everything that affects how it
  looks; a set is only redrawn when its signature changes.
- Per-set state `pvState[]`: 0 clean, 1 queued for a full redraw, 2 live coarse
  pass (while dragging), 3 growing in.
- Time budgets in microseconds: `pvBudget` (grow-in), `pvLiveBudget` (dragging).
  `pvMode` is LIVE / BUSY, `pvSmooth` is the smoothing shader; both are saved in
  `HSD_Settings.ini`.
- `previewDrawStrands()` is the preview's copy of the render maths.

## 5. Save files

- `Autosave.txt` lives in `%LOCALAPPDATA%\HairStrand_Designer`. Manual projects
  are wherever you save them. Both are text, one `Description:value;` per line;
  the description is ignored when loading.
- **The older part of the file is read back by line position.** The order of the
  writes in the saver must equal the order of the reads in the loader, exactly.
  A line added in the middle shifts everything after it.
- **Newer blocks are found by a marker line** instead, so they can be missing
  (old files still load) and their position does not matter:
  - `V1.85 - Per Set Colour Overrides`
  - `V1.96 - Clumping` (`clumpWriteBlock` / `clumpReadFile`)
  - `V1.96 - Set Extras` (`extrasWriteBlock` / `extrasReadFile`: noise, per-set
    thickness, fading, noise and seeds)
- A manual save (`KeyPress_83`) writes the old positional part only; **Alarm 1**
  then appends the three marker blocks. On any load, Alarm 1 runs one frame
  later and reads the marker blocks.
- Only 11 sets are stored.
- `demoMode == 1` disables the S save, the Alarm 1 append and all autosaving.

**Adding a new saved value:** put it in a marker block (the simplest is
`projectExtras`), then add it to the autosave writer and reader, and, if it is
per set, to `obj_copy` in both the copy struct and the paste, and to
`clearOverrides` / the F4 and F5 resets.

## 6. Traps that have already cost time

- **Copy-on-write arrays are ON** in this project. Writing through a shared
  array reference needs the accessor form `array[@ i] = value`, or the write
  goes to a private copy and is lost.
- **`doMainStep` leaves colour-write alpha switched off every step.** Anything
  that draws to a surface afterwards and needs alpha must call
  `gpu_set_colorwriteenable(true, true, true, true)` first. Symptom when
  forgotten: strands missing or faint on some frames only.
- **Preview and render must match.** A change to the strand maths in
  `doMainStep` needs the same change in `previewDrawStrands`.
- **The random stream order matters.** `updatePreRands` draws values in a fixed
  order per set; adding a draw in the middle changes every strand of every
  existing project. Clumping deliberately uses a seed hash and draws nothing.
- **Strings cannot contain a real line break** in GML; use `"\n"`.
- **Click rectangles follow the artwork.** If a control is moved in `spr_UI`,
  move its hit test in `Draw_0`, and its tip in `uiTips`, too.
- **The surface checks reset nothing else.** After a surface is lost and
  recreated a map can still read "generated" over a blank canvas; regenerate.

## 7. MCP control (V1.97)

Claude Code can drive the running app through `tools/hsd-mcp/bridge.mjs`; see
the README there. In the app:

- `obj_mcp` (created by `obj_surfaceDweller`'s Create, persistent) owns the
  loopback connection. It is off until Ctrl+Shift+F10 or the `-mcp` launch
  option, and draws a small MCP tab at the top of the preview while on.
- `scripts/mcpCommands` holds every command. They write the same variables the
  sliders and buttons write, then set `pleaseGen` and autosave, so nothing else
  in the program needs to know MCP exists.
- The only hooks elsewhere: `mcpFileOverride` (Create_0), read by the S and L
  key events instead of their file dialogs.
- A new slider needs one line in `mcp_param_table()` to be reachable over MCP.

## 8. Building and testing without the IDE

Runtime: `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23`.

- Compile check: `bin\igor\windows\x64\Igor.exe ... -- windows Compile`
- Release zip / installer: `... -- windows PackageZip` / `PackageNsis` with
  `--tf=<target file>`. Keep logs and the cache outside the `--temp` folder.
- Demo build: the same code with `demoMode=1` on line 3 of
  `obj_surfaceDweller/Create_0.gml` (change it in a temporary copy).
- A release is five files: PRO zip, PRO installer, DEMO zip, DEMO installer and
  the documentation PDF.
- `python tools/check_comments_only.py` proves an edit changed comments only
  (it compares against the last commit with the comments stripped out).

## 9. Leftovers you can ignore

These are in the project but nothing creates or reaches them:
`obj_save`, `obj_test`, `sentry_handler`, `obj_FS_Windowed`, `obj_background`,
`obj_global_controller`, `obj_controller_gaussian_blur`,
`obj_player_gaussian_blur`, `obj_plotCurver`, `obj_curver`, `obj_loadMessage`,
`o_pathMaker` (its room is never entered), and the scripts `doCalcSoft`,
`analise_HexToDec`, `charToUnicode`, `trace`, `window_command_toggle`.
`resetSurfaces` and `quickClearSurfaces` have empty bodies.

## 10. Things noticed while commenting (not fixed)

Each has a `NOTE` comment beside it in the source. None is new; they are listed
so they are not a surprise later. See `KNOWN_ODDITIES.md` for the full list.
