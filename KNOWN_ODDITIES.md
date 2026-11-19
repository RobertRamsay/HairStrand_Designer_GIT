# Known oddities

Things noticed while the source was being commented for 1.96 (November 2026).
**They are suspicions from reading the code, not confirmed by running it, and
none has been changed.** Most have a `NOTE` comment beside them in the source.
Line numbers drift, so each entry gives something to search for.

## Likely real, user-visible

- **Mask Map tick box** (`Draw_0.gml`, map toggle click handlers): clicking a
  generated Mask map's tick clears `doNorm`, not `doMask`. An old comment calls
  it intentional; it reads like a copy-paste slip.
- **Frizz export row** (`exportIndividual.gml`, `mouse_y>130+(vSpace*6)`): the
  top edge uses `*6`, so it covers the AO row too. Clicking the AO export icon
  can also open a Frizz save dialog.
- **Blur (B)** (`Draw_0.gml`, BLUR PASS): the horizontal pass draws the original
  canvas again instead of the vertically blurred result, so the two passes are
  layered, not chained. In `Create_0.gml` the two `blur_amount` uniform handles
  are also looked up on the opposite shaders.
- **Flow map Flip X** (`doMainStep.gml`, `dirFlipX * 180`): the 180 is added
  outside `degtorad()`, so it is 180 radians, not a half turn.
- **Dice with a set selected** (`Draw_0.gml`, DICE BUTTON): tests
  `randomOverride[s]` where `s` is a stale loop counter, not `setSelectedID`.
- **Thick Rng notches** (`Draw_0.gml`, rows 9): with a set selected the notch is
  drawn at the wrong position (the number is right); every other per-set row has
  an `if setSelectedID != -1 slx = ...` line these two lack.
- **Colour history flooding** (`Draw_0.gml`, COLOUR SWATCH HANDLERS): the swatch
  block fires on hover with no mouse-button test, pushing a colour into the
  24-entry history every frame.
- **Root Position slider** (`Draw_0.gml`): its drag code is inside the hover
  test, so it stops following when the mouse leaves the track. Tip Position
  latches properly.
- **Per-set strand count of 0** (`Draw_0.gml`, STRAND COUNT DISPLAY): treated as
  "no override", so such a set is shown and totalled with the global count.
- **Override dots** (`Draw_0.gml`, OVERRIDE INDICATOR DOTS): Wave Freq and the
  three Mixer rows have no dots.
- **Demo mode Save icon** (`Draw_0.gml`): only drawn faded; the click still
  fakes the S key. The real block is in `KeyPress_83`.
- **Switching Single / Multi strand** (`updatePreRands.gml`): Multi takes three
  extra random draws per strand, so switching changes every strand's values, not
  only the sprite.
- **Autosaved per-set seeds** (`doAutoSave.gml`): written with `string()`, which
  keeps 2 decimals. The manual-save block keeps 6. A fractional seed can come
  back slightly different from an autosave.
- **L then cancel** (`Create_0.gml`, `pathLoadAx` defaults; `KeyPress_76.gml`):
  the mixer path defaults are copied from `StragglePath_A/B/C` while the live
  mixers are `StragglePath_A1/B1/C1`. Pressing L and cancelling before any load
  may apply those defaults and discard unsaved mixer edits.
- **Mixer path point count** (`KeyPress_83.gml` / `KeyPress_76.gml`): the saver
  writes however many points a path has, the loader always reads 11. A path with
  a different point count would shift every later line of the file.
- **Cancelled export dialog** (`KeyPress_83.gml`, PNG export): the dialog result
  is not checked, so cancelling still calls `surface_save` with an empty name.
- **F4 / F5** (`Step_1.gml`): per-set seeds and X/Y offsets are not reset with
  the other overrides.
- **UV image loader** (`obj_UV_Image_Loader/Draw_0.gml`): on cancel the object
  stays alive with the placeholder, and loaded sprites are never deleted.

## Inconsistent or dead, probably harmless

- `doMainStep`: `doLogOnce = 9` disables every log line in the file.
- `doMainStep`: the "Flow Map base color" overwash at render start is wiped by
  the black fill that follows it.
- `doMainStep`: fallback branches fill the colour canvas black and pick the
  normal fill from `oldNormDraw`, where the main branches use `colrBack` and
  `moreHairs`.
- `doMainStep`, AO pass: the `tog` counter is never reset, so which ring is
  drawn drifts from point to point.
- `doMainStep`: `gpu_set_texfilter(1)` is left on after the normal pass.
- `doMainStep`: `generating` is cleared on the first step after Generate, so the
  render progress overlay in `Draw_0` shows for at most one frame.
- `mainCalc`: `setSelected!=-1` tests an array, so it does not mean "a set is
  selected".
- `doHighlighting`: `b=clickedID` assigns to the loop counter; the label Y is
  divided by 4 twice.
- `mixerCacheBuild` (`clumpTools`): divides by the set's Variation; 0 would be a
  divide by zero (the slider's minimum is 1).
- `setupCanvases` (`if count>1`): frees 11 surfaces and recreates 3. Dormant: it
  is only called once.
- `killSurfaces` from Clean Up recreates the 4096 surfaces as the object dies.
- Begin Step kills every map if any one surface is missing, before
  `canvasCheck`'s gentler single-surface recreate can run.
- `doAutoSave` runs twice per mouse release (from `doMainStep` and `Step_2`).
- `doAutoLoad` (`if theFile != ""`): `file_text_open_read` returns -1 on
  failure, so this never catches a missing file (the caller checks first).
- The nine map tick boxes and "Current map" are saved but not restored.
- `dec_to_hex_save`: variable names `hexBlue` / `hexRed` are backwards; output
  is correct but can be shorter than six characters.
- `reset_textBoxes`: `textBox_minScale` / `textBox_maxScale` reset to 2, not 0.
- `clearOverrides`: `setVariOverrode[a]=0` appears twice.
- `shd_normal.fsh`: the `bumpAmount` uniform is re-declared as a local, so the
  uniform has no effect. `shd_gaussian_vertical.fsh` is a 502-sample box blur.
- Numpad digits in the number boxes are read from the held key with no
  pressed-edge test.
- Opening the HEX field does not close an open slider number box.
- `Draw_0`: two `keyboard_key_press(ord("S"))` calls have no matching release.
- `localUpdateSet` and `firstCalc` are written but nothing reads them.
  `set_active[]` is never set to 1.
- Map list rows: icons are drawn at a 26 px pitch, click tests use 27 px.
- `obj_pathEdit`: point 0 can be selected but not dragged; the curve is drawn
  from y 10 while the point markers have no offset.
- `KeyPress_76`: the project file is opened for reading and never closed.
- `KeyPress_83`: the legacy colour lines hold the selected set's colours if a
  set is selected when saving; only the V1.85 block has the true globals.
- `Step_2`: older save / load blocks near the top duplicate Alarm 1's work
  without the clump and extras blocks; two `draw_sprite(spr_colHL...)` calls in
  a Step event draw nothing; set 0's colours are swapped in and out around
  `doMainStep` on every idle frame.
- `Create_0`: `strandLife[...]= life=random_range(...)` stores true / false (the
  second `=` is a comparison); nothing reads that table. 2000 flyaway paths are
  created at every start and nothing reads them.
- `Create_0`, unused variables: `liveLocalEvery`, `liveLocalTick`,
  `normalMapGenerated`, `or_editColor`, `previewingUV`, `prevFinalX`,
  `clumpPath`, `yjit`, `surfSetAO`. `alogrithmInfluence[]` and
  `taperInfluence[]` are saved, loaded and copied but no calculation reads them.
- `Step_1`: `if optimalStep>2 optimalStep-=8` can reach 0; the 1.96 preview no
  longer reads it.
- `rooms/Room_HSD/Room_HSD1.yy` is a stray file not referenced by the project.

## Worth a runtime check

- Returning from the mixer editor room: `Room_HSD` is not persistent and places
  `obj_surfaceDweller`, `g` and `o_motionDetector`, which are persistent. That
  normally creates a second copy on re-entry; no guard was found by reading.
