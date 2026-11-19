// -----------------------------------------------------------------------------
// EVENT : Step (Step_0). Runs every frame after Begin Step, the alarms and the
//         key events, and before End Step (Step_2) and Draw_0.
// DOES  : the per-set COLOUR model, and three fixes layered over the old Draw_0
//         colour UI without rewriting it:
//         1. first-run creation of the colour arrays (they are NOT in Create_0)
//         2. downgrade path for projects older than format 1.85
//         3. route a colour edit to the global colour or to the selected set
//         4. F4 / F5 colour-override resets (the slider half is in Step_1)
//         5. expose the right colours back to the UI (custom*)
//         6. click-only colour slot selection
//         7. colour history hover suppression
//         8. dragging the 512x512 viewer window over a 4K map
//
// THE THREE LAYERS OF COLOUR VARIABLE (the key to this file)
//   custom*  customColVarA / customColVarB / customRootCol / customTipCol
//            What the colour UI shows and edits. NOT the truth: it holds the
//            selected set's colours while a set is selected, otherwise the
//            globals. Step_2 also swaps it temporarily while rendering.
//   global*  globalColVarA / B / RootCol / TipCol
//            The project-wide colours. Used by every set that has no override.
//   set*     setColVarA[] / setColVarB[] / setRootCol[] / setTipCol[]  (per set)
//            What is actually drawn for each set. Always filled in.
//            set*Overrode[] = 1 means that set keeps its own colour when the
//            global one changes.
//   colourUiLast* : custom* as they were at the end of last frame's Step_0.
//            "custom != last" is how an edit made by the picker (Step_2 / Draw_0
//            of the previous frame) is detected here.
//   colrBack (background) is global only - it has no per-set version.
//
// CALLED BY / DEPENDS ON: Draw_0 and Step_2 write custom* and the *_active
//   flags; mainCalc() re-applies colourSelectedSlot inside Draw_0; Alarm 1 and
//   Step_2 reload these arrays after a project load; object g (Begin Step)
//   snapshots them to trigger the colour autosave.
// -----------------------------------------------------------------------------
//fix 17th May 2021 / edite 22nd may 2023 (about 2 years later haha)
//if maxScale<minScale maxScale=minScale

// -----------------------------------------------------------------------------
// PER-SET COLOUR OVERRIDES
// Mirrors the existing strand length/count override behaviour:
// - no selected set: edit the global colour and propagate to non-overridden sets
// - selected set: edit only that set and mark that colour channel overridden
// -----------------------------------------------------------------------------
// One-off initialisation, done lazily on the first Step instead of in Create_0.
// setColourOverridesReady only exists once this block has run; other code
// (object g, Alarm 1) checks for it before touching the arrays.
if !variable_instance_exists(id,"setColourOverridesReady")
	{
	globalColVarA=customColVarA
	globalColVarB=customColVarB
	globalRootCol=customRootCol
	globalTipCol=customTipCol
	
	for (var _colourSet=0;_colourSet<maxSets;_colourSet++)
		{
		setColVarA[_colourSet]=globalColVarA
		setColVarB[_colourSet]=globalColVarB
		setRootCol[_colourSet]=globalRootCol
		setTipCol[_colourSet]=globalTipCol
		
		setColVarAOverrode[_colourSet]=0
		setColVarBOverrode[_colourSet]=0
		setRootColOverrode[_colourSet]=0
		setTipColOverrode[_colourSet]=0
		}
	
	colourUiLastA=customColVarA
	colourUiLastB=customColVarB
	colourUiLastRoot=customRootCol
	colourUiLastTip=customTipCol
	colourUiLastSet=setSelectedID
	setColourOverridesReady=1
	}

// Per-set colour data did not exist before project format 1.85.
// If an older project/autosave is loaded, deliberately ignore any accidental
// trailing colour block and treat its four legacy colours as global-only.
// Once converted in memory, future saves use the current 1.95 project header.
// (That comment predates 1.96 - the header written below is the 1.96 one.)
// HOW THE VERSION IS READ: mainS is the first line of the project file, e.g.
//   "Hair Strand Designer - Project File - Version1.96.0 - ..."
// "Version" ends at character 45, so string_copy(mainS,46,4) is "1.96". This
// depends on the header text never changing length before the number. real()
// throws if those four characters are not a number.
// This block runs every frame but only does anything while mainS still holds an
// old header, i.e. on the frames between a legacy load finishing (loading goes
// false) and Alarm 1 / Step_2 writing the current header back into mainS. In
// practice Alarm 1 does the same job; this is the safety net.
// The header string must stay identical in every place that assigns mainS
// (Create_0, here, Step_2, Alarm 1, object g's Begin Step and S key). When the
// version number is bumped, change all of them, and check doAutoSave too.
var _colourProjectVersion=real(string_copy(mainS,46,4))
if _colourProjectVersion<1.85 and !loading
	{
	globalColVarA=customColVarA
	globalColVarB=customColVarB
	globalRootCol=customRootCol
	globalTipCol=customTipCol
	
	for (var _legacyColourSet=0;_legacyColourSet<maxSets;_legacyColourSet++)
		{
		setColVarA[_legacyColourSet]=globalColVarA
		setColVarB[_legacyColourSet]=globalColVarB
		setRootCol[_legacyColourSet]=globalRootCol
		setTipCol[_legacyColourSet]=globalTipCol
		setColVarAOverrode[_legacyColourSet]=0
		setColVarBOverrode[_legacyColourSet]=0
		setRootColOverrode[_legacyColourSet]=0
		setTipColOverrode[_legacyColourSet]=0
		}
	
	mainS="Hair Strand Designer - Project File - Version1.96.0 - 9thNov2026 (C) Robert Ramsay"
	colourUiLastA=customColVarA
	colourUiLastB=customColVarB
	colourUiLastRoot=customRootCol
	colourUiLastTip=customTipCol
	colourUiLastSet=setSelectedID
	}

// EDIT ROUTING. The same pattern four times (A, B, root, tip):
//   custom != colourUiLast  -> the UI changed this colour since last frame
//   a set is selected       -> store it in that set and flag the set overridden
//   no set selected         -> store it as the global and copy it to every set
//                              that is not overridden
// A set, once overridden, stays overridden until F4 / F5.
var _colourChanged=0

// Variation A
if customColVarA!=colourUiLastA
	{
	if setSelectedID!=-1
		{
		setColVarA[setSelectedID]=customColVarA
		setColVarAOverrode[setSelectedID]=1
		}
	else
		{
		globalColVarA=customColVarA
		for (var _setA=0;_setA<maxSets;_setA++)
			{
			if setColVarAOverrode[_setA]!=1 setColVarA[_setA]=globalColVarA
			}
		}
	_colourChanged=1
	}

// Variation B
if customColVarB!=colourUiLastB
	{
	if setSelectedID!=-1
		{
		setColVarB[setSelectedID]=customColVarB
		setColVarBOverrode[setSelectedID]=1
		}
	else
		{
		globalColVarB=customColVarB
		for (var _setB=0;_setB<maxSets;_setB++)
			{
			if setColVarBOverrode[_setB]!=1 setColVarB[_setB]=globalColVarB
			}
		}
	_colourChanged=1
	}

// Root colour
if customRootCol!=colourUiLastRoot
	{
	if setSelectedID!=-1
		{
		setRootCol[setSelectedID]=customRootCol
		setRootColOverrode[setSelectedID]=1
		}
	else
		{
		globalRootCol=customRootCol
		for (var _setRoot=0;_setRoot<maxSets;_setRoot++)
			{
			if setRootColOverrode[_setRoot]!=1 setRootCol[_setRoot]=globalRootCol
			}
		}
	_colourChanged=1
	}

// Tip colour
if customTipCol!=colourUiLastTip
	{
	if setSelectedID!=-1
		{
		setTipCol[setSelectedID]=customTipCol
		setTipColOverrode[setSelectedID]=1
		}
	else
		{
		globalTipCol=customTipCol
		for (var _setTip=0;_setTip<maxSets;_setTip++)
			{
			if setTipColOverrode[_setTip]!=1 setTipCol[_setTip]=globalTipCol
			}
		}
	_colourChanged=1
	}

// F4: reset the selected set's colour overrides to the globals.
if keyboard_check_pressed(vk_f4) and setSelectedID!=-1
	{
	var _resetColourSet=setSelectedID
	setColVarAOverrode[_resetColourSet]=0
	setColVarBOverrode[_resetColourSet]=0
	setRootColOverrode[_resetColourSet]=0
	setTipColOverrode[_resetColourSet]=0
	setColVarA[_resetColourSet]=globalColVarA
	setColVarB[_resetColourSet]=globalColVarB
	setRootCol[_resetColourSet]=globalRootCol
	setTipCol[_resetColourSet]=globalTipCol
	_colourChanged=1
	}

// F5: reset all colour overrides, matching the existing all-override reset.
if keyboard_check_pressed(vk_f5)
	{
	for (var _resetAllColours=0;_resetAllColours<maxSets;_resetAllColours++)
		{
		setColVarAOverrode[_resetAllColours]=0
		setColVarBOverrode[_resetAllColours]=0
		setRootColOverrode[_resetAllColours]=0
		setTipColOverrode[_resetAllColours]=0
		setColVarA[_resetAllColours]=globalColVarA
		setColVarB[_resetAllColours]=globalColVarB
		setRootCol[_resetAllColours]=globalRootCol
		setTipCol[_resetAllColours]=globalTipCol
		}
	_colourChanged=1
	}

// A colour changed: ask for redraws.
//   color_GenState 2 -> 1 : the finished 4K colour map is now stale, so mark it
//                           "wanted, not rendered" (it re-renders on the next G)
//   colorOnlyUpdate=1     : tells previewUpdate() this forceUpdate is only a
//                           colour edit, so it need not redraw every set - the
//                           per-set signatures pick up which sets changed
//   previewCanvasComplete : legacy flag, still written, no longer read by the
//                           1.96 preview
if _colourChanged==1
	{
	if color_GenState==2 color_GenState=1
	colorOnlyUpdate=1
	previewCanvasComplete=0
	forceUpdate=1
	}

// Expose the correct colours to the existing colour UI.  This means the old
// picker/swatch code does not need to know anything about the override arrays.
if setSelectedID!=-1
	{
	customColVarA=setColVarA[setSelectedID]
	customColVarB=setColVarB[setSelectedID]
	customRootCol=setRootCol[setSelectedID]
	customTipCol=setTipCol[setSelectedID]
	}
else
	{
	customColVarA=globalColVarA
	customColVarB=globalColVarB
	customRootCol=globalRootCol
	customTipCol=globalTipCol
	}

// -----------------------------------------------------------------------------
// COLOUR SLOT SELECTION: CLICK ONLY
// Draw_0 contains an old hover-driven selector. Keep an authoritative selection
// here which only changes on a real left click. mainCalc() restores this state
// after the old Draw hover block has run, before the colour UI is drawn/used.
// Slot: 0=background, 1=A, 2=B, 3=root, 4=tip.
// -----------------------------------------------------------------------------
if !variable_instance_exists(id,"colourSelectedSlot")
	{
	if bkCol_active==1 colourSelectedSlot=0
	else if ColA_active==1 colourSelectedSlot=1
	else if ColB_active==1 colourSelectedSlot=2
	else if RootCol_active==1 colourSelectedSlot=3
	else if TipCol_active==1 colourSelectedSlot=4
	else colourSelectedSlot=1
	colourSelectedStoreColor=storeColor
	}

// The five source swatches are a column at x 1568..1632; the y bands below are
// background, A, B, root, tip from top to bottom. The same rectangles are
// repeated in the colour-history block further down - change both together.
// colourSelectedStoreColor is the "old colour" half of the old/new comparison
// swatch: the colour the slot had when it was picked.
var _clickedColourSlot=-1
if mouse_check_button_pressed(mb_left) and mouse_x>1568 and mouse_x<1632
	{
	if mouse_y>541 and mouse_y<564 _clickedColourSlot=0
	if mouse_y>568 and mouse_y<590 _clickedColourSlot=1
	if mouse_y>594 and mouse_y<618 _clickedColourSlot=2
	if mouse_y>621 and mouse_y<645 _clickedColourSlot=3
	if mouse_y>649 and mouse_y<671 _clickedColourSlot=4
	}

if _clickedColourSlot!=-1
	{
	colourSelectedSlot=_clickedColourSlot
	if colourSelectedSlot==0 colourSelectedStoreColor=colrBack
	if colourSelectedSlot==1 colourSelectedStoreColor=customColVarA
	if colourSelectedSlot==2 colourSelectedStoreColor=customColVarB
	if colourSelectedSlot==3 colourSelectedStoreColor=customRootCol
	if colourSelectedSlot==4 colourSelectedStoreColor=customTipCol
	}

// If the user changes strand set while keeping the same colour channel active,
// reset the old/new comparison source to that set's colour.
if colourUiLastSet!=setSelectedID
	{
	if colourSelectedSlot==0 colourSelectedStoreColor=colrBack
	if colourSelectedSlot==1 colourSelectedStoreColor=customColVarA
	if colourSelectedSlot==2 colourSelectedStoreColor=customColVarB
	if colourSelectedSlot==3 colourSelectedStoreColor=customRootCol
	if colourSelectedSlot==4 colourSelectedStoreColor=customTipCol
	}

// Restore the authoritative active flags before End Step / picker interaction.
bkCol_active=0
ColA_active=0
ColB_active=0
RootCol_active=0
TipCol_active=0
if colourSelectedSlot==0 bkCol_active=1
if colourSelectedSlot==1 ColA_active=1
if colourSelectedSlot==2 ColB_active=1
if colourSelectedSlot==3 RootCol_active=1
if colourSelectedSlot==4 TipCol_active=1

storeColor=colourSelectedStoreColor
if colourSelectedSlot==0 newColor=colrBack
if colourSelectedSlot==1 newColor=customColVarA
if colourSelectedSlot==2 newColor=customColVarB
if colourSelectedSlot==3 newColor=customRootCol
if colourSelectedSlot==4 newColor=customTipCol

// When switching between global/set editing, make the active colour picker
// follow the newly exposed colour instead of retaining the previous set's value.
if colourUiLastSet!=setSelectedID
	{
	if bkCol_active==1   newColor=colrBack
	if ColA_active==1    newColor=customColVarA
	if ColB_active==1    newColor=customColVarB
	if RootCol_active==1 newColor=customRootCol
	if TipCol_active==1  newColor=customTipCol
	}

// Remember what the UI now shows. Must be the LAST thing done to custom* in this
// event: anything that changes custom* after this line (the pickers in Step_2,
// Draw_0) is what next frame's "custom != colourUiLast" test will pick up.
colourUiLastA=customColVarA
colourUiLastB=customColVarB
colourUiLastRoot=customRootCol
colourUiLastTip=customTipCol
colourUiLastSet=setSelectedID

// -----------------------------------------------------------------------------
// COLOUR HISTORY: ONLY COMMIT ON A REAL LEFT CLICK
// The legacy Draw event's five colour swatch handlers run from mouse position
// alone, so merely hovering currently writes hCol[] and advances the history.
// Keep its normal click behaviour, but redirect hover-only writes to hCol[24],
// which is outside the 24 visible history slots (0..23).
// -----------------------------------------------------------------------------
if !variable_instance_exists(id,"colourHistoryHoverSuppressed")
	{
	colourHistoryHoverSuppressed=0
	colourHistorySavedPointer=colorHistoryPointer
	}

var _overColourSourceSwatch =
	mouse_x>1568 and mouse_x<1632 and
	(
		(mouse_y>541 and mouse_y<564) or
		(mouse_y>568 and mouse_y<590) or
		(mouse_y>594 and mouse_y<618) or
		(mouse_y>621 and mouse_y<645) or
		(mouse_y>649 and mouse_y<671)
	)

if _overColourSourceSwatch and !mouse_check_button_pressed(mb_left)
	{
	if colourHistoryHoverSuppressed==0
		{
		colourHistorySavedPointer=colorHistoryPointer
		colourHistoryHoverSuppressed=1
		}
	
	// Draw_0 may write/increment/wrap this during hover. Reset it to the dummy
	// slot every Step so no visible history entry is changed.
	colorHistoryPointer=24
	}
else
	{
	if colourHistoryHoverSuppressed==1
		{
		// Restore the real insertion point before Draw_0 sees an actual click,
		// or when the cursor leaves the colour-source swatches.
		colorHistoryPointer=colourHistorySavedPointer
		colourHistoryHoverSuppressed=0
		}
	}

// -----------------------------------------------------------------------------
// TEXTURE VIEWER BOX DRAG
// Draw_0 still draws the map viewer from xxx/yyy, but its original assignments
// are commented out. Restore the intended behaviour here without rewriting the
// large Draw event: drag anywhere inside the 1024x1024 map preview to move the
// 512x512 source window over the 4096x4096 generated texture.
// The preview area shows the whole 4096 map at 1/4 size, so mouse*4 is the
// texture pixel under the cursor; -256 centres the 512 window on it and the
// clamp keeps the window inside the texture (0..3584).
// Only in map views (img!=9) and never while rendering.
// NOTE: the renderer (doMainStep) also writes xxx/yyy per strand while it runs.
// -----------------------------------------------------------------------------
if img!=9 and mouse_check_button(mb_left) and mouse_x>=0 and mouse_x<1024 and mouse_y>=0 and mouse_y<1024 and !generating
	{
	xxx=clamp((mouse_x*4)-256,0,4096-512)
	yyy=clamp((mouse_y*4)-256,0,4096-512)
	}
