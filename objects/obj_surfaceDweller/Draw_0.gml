/// @description PREVIEW STRANDS - Draw Event
// Main draw event for the Hair Strand Designer preview/control panel.
// Handles: UI drawing, map toggle buttons, slider controls, colour pickers,
//          blur pass, surface display, and all mouse/keyboard interactions.
//
// WHAT THIS EVENT DOES
// Runs once per frame. It draws the whole screen AND handles nearly all of the
// mouse/keyboard input for the panel in the same pass: each control is
// hit-tested, updated and drawn at the point where it appears in this file.
// Later code draws over earlier code, so file order = draw order, and a click
// is seen by EVERY block whose rectangle contains it (nothing "consumes" a click).
//
// ORDER OF SECTIONS (search for the banner text)
//   UI BASE + PALETTE IMAGE            spr_UI backdrop, custom palette image, import button
//   GENERATE SHORTCUT (G KEY)          starts a full 4K generate
//   MAP ENABLE / DISABLE STATES        tick/export icons per map, render progress overlay
//   PREVIEW CANVAS BACKGROUND + UV     background colour fill, UV reference image
//   MAP TOGGLE BUTTON TOOLTIPS         helper tips for the 9 map tick boxes
//   MAP ENABLE / DISABLE CLICK         tick boxes, per-map export, Generate button
//   COLOUR SWATCH CLICK HANDLERS       legacy hover-driven swatch select (see note there)
//   COLOUR HISTORY SWATCH ROW          24 recent colours
//   PREVIEW MAP SELECTOR               click a map name to view it (sets img)
//   GHOST SPRITE + MAIN CALCULATION    mainCalc(): the live strand preview
//   RANDOMISATION DICE BUTTON          seeds
//   VIEWER BOX POSITION                disabled (code commented out)
//   SAVE / EXPORT, QUIT / ROOM SWITCH  top-bar buttons
//   SLIDER: ... / DUAL SLIDERS: ...    the slider rows, one #region per slider
//                                      (rows 0,2,3..13, then Clumping 17-18, Length row 1, Mixers 14-16)
//   COLOUR SLIDERS: ROOT/TIP POSITION  gradient position sliders in the colour panel
//   STRAND COUNT DISPLAY               per-set counts and the total
//   COLOUR SWATCHES / MODE / SLIDERS   swatch fills, RGB-HSV-Grey buttons, 3 channel sliders
//   HEX COLOUR EDITOR                  typed hex colour
//   FLOW / ID DIRECTION MODE BUTTONS   toggles above the slider rows
//   GEN STATE SYNC                     pleaseGen -> map states back to "needs generating"
//   BLUR PASS                          B key / BLUR button, blurs the viewed 4K map
//   SURFACE DISPLAY                    draws the viewed map + zoom view, tip text (uiTips)
//   AO + COLOUR MAP MULTIPLIED PREVIEW hold J
//   VIEWER BOX OUTLINE                 green zoom rectangle
//   UV OVERLAY + LOAD / SAVE ICONS
//   DIVIDING LINE + SIDE MAP MARKER    also calls checkAndOffset() = the set number buttons
//   UI EXTRAS: OVERRIDE INDICATOR DOTS
//   MISC UI                            filename, strand type, preview mode, curl, seed readout
//   HELP PANEL TOGGLE
//   STARTUP SPLASH SCREEN
//   HEART ICON, DRAG WINDOW BAR, EXIT CONFIRMATION DIALOG, FRAME CLEANUP
//
// CONVENTIONS YOU NEED TO KNOW
// - Coordinates are room pixels in a 1920x1080 room. The left 1024x1024 square
//   is the preview canvas (the 4096 maps are shown at 0.25 scale, so canvas
//   pixel = map pixel / 4). Everything right of x=1024 is the control panel.
// - The panel art is ONE baked sprite (spr_UI). Labels, boxes and slider tracks
//   are painted into it, so every hit rectangle and draw position here is a
//   hard-coded number chosen to match that art. If the art moves, the numbers
//   in this file (and in uiTips / checkAndOffset / exportIndividual) must follow.
// - Slider rows: row centre y = 436 + 28*row. Track starts at x=1198 (ex).
//   1 pixel of track = 1 unit of value, so a 0-100 slider is 100px wide.
//   "Dual" rows hold two 0-40 sliders: left at ex=1198, right at ex=1198+60,
//   with number boxes at x 1312-1340 (left) and 1347-1376 (right).
//   Single rows use one number box, x 1312-1376. Readout text is at x=1318
//   (right box: 1318+34).
// - setSelectedID = index of the selected set, or -1 for "no set selected".
//   With no set selected a slider edits the GLOBAL value (strands, wavyness...)
//   and copies it into every set that has not been overridden.
//   With a set selected it edits only that set's entry in the per-set array
//   (strandSet*Adj[] / set*Adj[] / strand*Override[]) and sets the matching
//   flag array (set*Overrode[] = 1) so later global edits skip that set.
//   Overridden values are drawn in tbColOver instead of tbCol.
// - pleaseGen = true means "settings changed, the 4K maps are stale". It shows
//   the "please generate" message and (GEN STATE SYNC) drops finished maps
//   back from state 2 to their enabled/disabled state.
// - *_GenState per map: 0 = disabled, 1 = enabled / waiting to generate,
//   2 = generated (can be viewed and exported). do* (doRGB, doNorm...) is the
//   tick box itself.
// - img = which map the canvas is showing: 0 RGB mask, 1 normal, 2 ID,
//   3 depth, 4 colour, 5 mask, 6 flow, 7 AO, 8 frizz, 9 = live strand previewer.
//   Note the on-screen row order (RGB, Normal, Mask, Colour, ID, Depth, Flow,
//   AO, Frizz, Previewer) is NOT the img order.
// - forceUpdate = 1 asks the preview (previewJob) for a rebuild; the text boxes
//   set it on Enter. colorOnlyUpdate = 1 + previewCanvasComplete = 0 ask for a
//   recolour only. The preview code clears forceUpdate/colorOnlyUpdate.
// - smallTip = helper-tip text for the thing under the mouse. It is cleared
//   every frame in Step_1 and drawn in SURFACE DISPLAY, after uiTips() has
//   filled it in for anything this file did not already claim. First writer
//   wins inside uiTips, so a tip set here takes priority.
// - Text boxes: only one is open at a time (reset_textBoxes() closes all).
//   The text being typed lives in the shared buffer `str` (hex editor: `str2`).
// - Sliders: slider_interract_* is the "this slider is being dragged" latch,
//   set on press inside the track and cleared for all sliders on mouse release
//   (nullify_sliderInterracts). The latch is why a drag keeps working when the
//   mouse leaves the track.
// - `over`, `ex`, `ey`, `sly`, `slx` are re-declared with var in every slider
//   block; each block is self-contained and they carry no meaning between blocks.

debugMsg = "Preview Strands"

// ============================================================
// UI BASE + PALETTE IMAGE
// ============================================================
#region

draw_sprite(spr_UI, 0, 0, 0) // draw base UI

// Draw custom palette image if one is loaded
// It is stretched to fill the 254x180 palette area at (1645,542) in the colour
// panel, whatever the size of the loaded image.
if newPalImg != -1
{
	var piw = 254 / sprite_get_width(newPalImg)
	var pih = 180 / sprite_get_height(newPalImg)
	draw_sprite_ext(newPalImg, 0, 1645, 542, piw, pih, 0, c_white, 1)
}

// Import palette button - dim when not hovered
// 32x18 button at (1863,824), under the palette. Left click fakes an F9 key
// press, so the real work is in the F9 key event. Right click removes the
// custom palette image (newPalImg back to -1 = use the built-in palette).
if !point_in_rectangle(mouse_x, mouse_y, 1863, 824, 1863+32, 824+18)
{
	draw_sprite_ext(s_importImagePal, 0, 1863, 824, 1, 1, 0, c_white, 0.6)
}
else
{
	draw_sprite_ext(s_importImagePal, 0, 1863, 824, 1, 1, 0, c_white, 1)
	draw_set_font(smallFont)
	draw_text(mouse_x-50, mouse_y+50, "Load Custom image \nAs a Palette")
	draw_set_font(regFont)
	if mouse_check_button_pressed(mb_left)  { keyboard_key_press(vk_f9); keyboard_key_release(vk_f9) }
	if mouse_check_button_pressed(mb_right)
	{
		if sprite_exists(newPalImg)
		{
			sprite_flush(newPalImg)
			sprite_delete(newPalImg)
		}
		newPalImg = -1
	}
}

// generating is cleared every frame and only set again below by the G key or
// the Generate button, so in this event it is true only on the frame the
// generate was requested. (The render progress overlay further down tests it.)
generating = false

#endregion


// ============================================================
// GENERATE SHORTCUT (G KEY)
// ============================================================
#region

// Same flag set as the on-screen Generate button (in MAP ENABLE / DISABLE
// CLICK HANDLERS below) - keep the two in step.
//   doOnce + retrigger : tell doMainStep to start the 4K render of every map
//                        whose GenState is 1
//   canSave = false    : block saving until the render has finished
//   pleaseGen = false  : hides the "please generate" message
//   obj_wait           : the "please wait" overlay object
if keyboard_check_pressed(ord("G"))
{
	firstTime   = false
	generating  = true
	changesMade = false
	doOnce      = true
	canSave     = false
	pleaseGen   = false
	instance_create_depth(0, 0, -1000, obj_wait)
	retrigger   = true
}

#endregion


// ============================================================
// MAP ENABLE / DISABLE STATES + RENDER PROGRESS OVERLAY
// ============================================================
#region

// The map list is the block at the top of the panel (x 1024-1376, y ~103-370):
// one row per map, in this screen order: RGB mask, Normal, Mask, Colour, ID,
// Depth, Flow, AO, Frizz. Rows are drawn 26px apart here; the click tests
// further down use 27px, which is why later rows use slightly different numbers.
var vSpace  = 26
var placeY  = 107

// Draw gen-state indicators for each map channel
// Tick-box column at x=1240. The GenState value is used directly as the
// sprite frame: 0 = disabled, 1 = enabled (waiting), 2 = generated.
draw_sprite(spr_GeneratedStates, rgbMask_GenState, 1240, placeY)
draw_sprite(spr_GeneratedStates, norm_GenState,    1240, placeY + vSpace*1)
draw_sprite(spr_GeneratedStates, mask_GenState,    1240, placeY + vSpace*2)
draw_sprite(spr_GeneratedStates, color_GenState,   1240, placeY + vSpace*3)
draw_sprite(spr_GeneratedStates, id_GenState,      1240, placeY + vSpace*4)
draw_sprite(spr_GeneratedStates, depth_GenState,   1240, placeY + vSpace*5)
draw_sprite(spr_GeneratedStates, flow_GenState,    1240, placeY + vSpace*6)
draw_sprite(spr_GeneratedStates, ao_GenState,      1240, placeY + vSpace*7)
draw_sprite(spr_GeneratedStates, frizz_GenState,   1240, placeY + vSpace*8)

// Draw export-state overlay icons
// Shown at x=1268 only for maps in state 2 (generated). The matching click
// test is in exportIndividual().
placeY = 106
if rgbMask_GenState == 2 draw_sprite(spr_genExp, 0, 1268, placeY)
if norm_GenState    == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*1)
if mask_GenState    == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*2)
if color_GenState   == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*3)
if id_GenState      == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*4)
if depth_GenState   == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*5)
if flow_GenState    == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*6)
if ao_GenState      == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*7)
if frizz_GenState   == 2 draw_sprite(spr_genExp, 0, 1268, placeY + vSpace*8)

// ---- RENDER PROGRESS OVERLAY ----
// Drawn under the map list. renderF is the set currently being rendered
// (0..sets), so renderF/(sets+1) is the fraction of sets done.
// NOTE: generating was cleared at the top of this event and is only true here
// on the frame G was pressed (the Generate BUTTON sets it further down, after
// this block), so as written this overlay shows for one frame at most.
if generating
{
	
	//img=4
	
	var _px   = 1034  // left edge of progress area
	var _pw   = 200   // bar width
	var _py   = placeY + vSpace*9 + 8
	var _prog = clamp(renderF / (sets+1), 0, 1)

	// Overall progress bar
	draw_set_color(make_color_rgb(40, 40, 40))
	draw_rectangle(_px, _py, _px+_pw, _py+10, 0)
	draw_set_color(make_color_rgb(80, 220, 120))
	draw_rectangle(_px, _py, _px+(_pw*_prog), _py+10, 0)
	draw_set_color(c_white)
	draw_text(_px, _py-14, "Set "+string(renderF+1)+" / "+string(sets+1)+" | "+string(strandCount)+" strands")

	// Per-map mini status bars
	var _mapNames  = ["RGB","NRM","MSK","COL","ID ","DPT","FLW","AO ","FRZ"]
	var _mapStates = [rgbMask_GenState, norm_GenState, mask_GenState, color_GenState,
	                  id_GenState, depth_GenState, flow_GenState, ao_GenState, frizz_GenState]
	var _bw  = 20
	var _bpy = _py + 18

	for (var _mi = 0; _mi < 9; _mi++)
	{
		var _bx  = _px + (_mi * (_bw+3))
		var _col
		if _mapStates[_mi] == 0 _col = make_color_rgb(40, 40, 40)    // disabled
		if _mapStates[_mi] == 1 _col = make_color_rgb(220, 160, 40)  // generating (amber)
		if _mapStates[_mi] == 2 _col = make_color_rgb(80, 220, 120)  // done (green)
		draw_set_color(_col)
		draw_rectangle(_bx, _bpy, _bx+_bw, _bpy+8, 0)
		draw_set_color(c_white)
		draw_set_font(-1)
		draw_text(_bx+2, _bpy+10, _mapNames[_mi])
	}

	// Strand counter
	draw_set_color(make_color_rgb(180, 180, 180))
	draw_text(_px, _bpy+22, string(strandCount)+" strands drawn")
	draw_set_color(c_white)
}
// ---- END RENDER PROGRESS OVERLAY ----

#endregion


// ============================================================
// PREVIEW CANVAS BACKGROUND + UV OVERLAY
// ============================================================
#region

// Fill preview area with the background hair colour
// Only in previewer mode (img 9); the other modes draw a map surface over the
// whole canvas later, in SURFACE DISPLAY.
draw_set_color(colrBack)
if img == 9 draw_rectangle(0, 0, 1023, 1023, 0)

// Draw UV reference image if loaded
// sc = 1024 / image width (set in obj_UV_Image_Loader Create), so 1024/sc
// source pixels drawn at scale sc exactly fill the 1024 canvas. a is the
// loader's alpha.
// This copy sits UNDER the strands; the UV OVERLAY section near the end draws
// it again on top while U is held.
if instance_exists(obj_UV_Image_Loader)
{
	if sprite_exists(obj_UV_Image_Loader.loadedSprite)
	{
		draw_sprite_part_ext(obj_UV_Image_Loader.loadedSprite, 0,
		                     0, 0,
		                     1024 / obj_UV_Image_Loader.sc, 1024 / obj_UV_Image_Loader.sc,
		                     0, 0,
		                     obj_UV_Image_Loader.sc, obj_UV_Image_Loader.sc,
		                     c_white, obj_UV_Image_Loader.a)
	}
}

#endregion


// ============================================================
// MAP TOGGLE BUTTON TOOLTIPS
// ============================================================
#region

// Tick boxes are x 1241-1270. The rectangle 130..157 is the NORMAL row (the
// second row); RGB is one row up (-vSpace) and the rest step down from it.
// vSpace is re-declared as 27 here and stays 27 for the click tests below.
var vSpace = 27

if point_in_rectangle(mouse_x, mouse_y, 1241, 130-(vSpace*1), 1270, 157-(vSpace*1)) smallTip = "Generate RGB Mask Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130,            1270, 157)            smallTip = "Generate Normal Texture Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*1), 1270, 157+(vSpace*1)) smallTip = "Generate Mask Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*2), 1270, 157+(vSpace*2)) smallTip = "Generate Color Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*3), 1270, 157+(vSpace*3)) smallTip = "Generate ID Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*4), 1270, 157+(vSpace*4)) smallTip = "Generate Depth Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*5), 1270, 157+(vSpace*5)) smallTip = "Generate Flow Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*6), 1270, 157+(vSpace*6)) smallTip = "Generate AO Map Toggle"
if point_in_rectangle(mouse_x, mouse_y, 1241, 130+(vSpace*7), 1270, 157+(vSpace*7)) smallTip = "Generate Frizz Map Toggle"

#endregion


// ============================================================
// MAP ENABLE / DISABLE CLICK HANDLERS
// ============================================================
#region

// firstCalc is raised while the left button is held and cleared in FRAME
// CLEANUP at the end of this event.
if mouse_check_button(mb_left) firstCalc = 1

if mouse_check_button_pressed(mb_left)
{
	// --- Enable / disable column (x: 1241–1270) ---
	// Each row: if the map is not yet generated, flip its do* tick and copy it
	// into the GenState (0 or 1). If it IS generated (state 2), a click throws
	// the result away: state and tick both go to 0.
	if mouse_x > 1241 and mouse_x < 1270
	{
		// RGB Mask
		if mouse_y > 130-(vSpace*1) and mouse_y < 157-(vSpace*1)
		{
			if rgbMask_GenState != 2 { doRGB=1-doRGB; rgbMask_GenState=doRGB }
			else                     { rgbMask_GenState=0; doRGB=0 }
		}
		// Normal Map
		if mouse_y > 130 and mouse_y < 157
		{
			if norm_GenState != 2 { doNorm=1-doNorm; norm_GenState=doNorm }
			else                  { norm_GenState=0; doNorm=0 }
		}
		// Mask Map
		if mouse_y > 130+(vSpace*1) and mouse_y < 157+(vSpace*1)
		{
			if mask_GenState != 2 { doMask=1-doMask; mask_GenState=doMask }
			else                  { mask_GenState=0; doNorm=0 } // note: doNorm intentional (legacy)
		}
		// Color Map
		if mouse_y > 130+(vSpace*2) and mouse_y < 157+(vSpace*2)
		{
			if color_GenState != 2 { doColor=1-doColor; color_GenState=doColor }
			else                   { color_GenState=0; doColor=0 }
		}
		// ID Map
		if mouse_y > 130+(vSpace*3) and mouse_y < 157+(vSpace*3)
		{
			if id_GenState != 2 { doID=1-doID; id_GenState=doID }
			else                { id_GenState=0; doID=0 }
		}
		// Depth Map
		if mouse_y > 130+(vSpace*4) and mouse_y < 157+(vSpace*4)
		{
			if depth_GenState != 2 { doDepth=1-doDepth; depth_GenState=doDepth }
			else                   { depth_GenState=0; doDepth=0 }
		}
		// Flow Map
		if mouse_y > 130+(vSpace*5) and mouse_y < 157+(vSpace*5)
		{
			if flow_GenState != 2 { doFlow=1-doFlow; flow_GenState=doFlow }
			else                  { flow_GenState=0; doFlow=0 }
		}
		// AO Map
		if mouse_y > 130+(vSpace*6) and mouse_y < 157+(vSpace*6)
		{
			if ao_GenState != 2 { doAO=1-doAO; ao_GenState=doAO }
			else                { ao_GenState=0; doAO=0 }
		}
		// Frizz Map
		if mouse_y > 130+(vSpace*7) and mouse_y < 157+(vSpace*7)
		{
			if frizz_GenState != 2 { doFrizz=1-doFrizz; frizz_GenState=doFrizz }
			else                   { frizz_GenState=0; doFrizz=0 }
		}
	}

	// --- Export individual maps ---
	// Script: tests the export-icon column (x 1347-1370) on the same rows and
	// opens a save dialog for a map that is in state 2.
	exportIndividual()

	// --- Generate button (main) ---
	// Wide button above the map list, x 1175-1375, y 67-97. Same flags as the
	// G key section above (explained there). doMainStep tests this same
	// rectangle for its own logging, so move both together.
	if mouse_x > 1175 and mouse_x < 1375 and mouse_y > 67 and mouse_y < 97
	{
		firstTime   = false
		generating  = true
		doOnce      = true
		changesMade = false
		canSave     = false
		pleaseGen   = false
		instance_create_depth(0, 0, -1000, obj_wait)
		retrigger   = true
	}
}

// Release obj_wait on mouse up
if mouse_check_button_released(mb_left)
{
	if instance_exists(obj_wait) instance_destroy(obj_wait)
}

#endregion


// ============================================================
// COLOUR SWATCH CLICK HANDLERS (select active colour slot)
// ============================================================
#region

// The five swatches are a column at x 1568-1632, y 541-671 in the colour panel
// (Background, A, B, Root, Tip).
// NOTE: there is NO mouse-button test here - this block fires on HOVER alone,
// every frame the mouse is over a swatch. It is legacy code. The real,
// click-only selection is kept in colourSelectedSlot (set in Step_0, which
// tests these same rectangles with a real click), and
// mainCalc(), which runs just below, overwrites the *_active flags, storeColor
// and newColor from it. So what this block still does in practice is push the
// hovered colour into the history ring (hCol, 24 entries, pointer wraps at 23)
// once per frame while hovering.
// For each swatch: mark it active, remember its colour as storeColor (the
// "old" half of the comparison bar) and start newColor from it.
if mouse_x > 1568 and mouse_x < 1632
{
	// Background colour
	if mouse_y > 541 and mouse_y < 564
	{
		bkCol_active    = 1; ColA_active = 0; ColB_active = 0
		RootCol_active  = 0; TipCol_active = 0
		storeColor      = colrBack
		newColor        = storeColor
		hCol[colorHistoryPointer] = storeColor
		colorHistoryPointer++
		if colorHistoryPointer > 23 colorHistoryPointer = 0
	}
	// Colour A
	if mouse_y > 568 and mouse_y < 590
	{
		bkCol_active    = 0; ColA_active = 1; ColB_active = 0
		RootCol_active  = 0; TipCol_active = 0
		storeColor      = customColVarA
		newColor        = storeColor
		hCol[colorHistoryPointer] = storeColor
		colorHistoryPointer++
		if colorHistoryPointer > 23 colorHistoryPointer = 0
	}
	// Colour B
	if mouse_y > 594 and mouse_y < 618
	{
		bkCol_active    = 0; ColA_active = 0; ColB_active = 1
		RootCol_active  = 0; TipCol_active = 0
		storeColor      = customColVarB
		newColor        = storeColor
		hCol[colorHistoryPointer] = storeColor
		colorHistoryPointer++
		if colorHistoryPointer > 23 colorHistoryPointer = 0
	}
	// Root colour
	if mouse_y > 621 and mouse_y < 645
	{
		bkCol_active    = 0; ColA_active = 0; ColB_active = 0
		RootCol_active  = 1; TipCol_active = 0
		storeColor      = customRootCol
		newColor        = storeColor
		hCol[colorHistoryPointer] = storeColor
		colorHistoryPointer++
		if colorHistoryPointer > 23 colorHistoryPointer = 0
	}
	// Tip colour
	if mouse_y > 649 and mouse_y < 671
	{
		bkCol_active    = 0; ColA_active = 0; ColB_active = 0
		RootCol_active  = 0; TipCol_active = 1
		storeColor      = customTipCol
		newColor        = storeColor
		hCol[colorHistoryPointer] = storeColor
		colorHistoryPointer++
		if colorHistoryPointer > 23 colorHistoryPointer = 0
	}
}

#endregion


// ============================================================
// COLOUR HISTORY SWATCH ROW
// ============================================================
#region

// 24 squares, 10px apart, starting at (1652,744) under the palette. Display
// only in this file: there is no click handling for them here.
for (swatchX = 0; swatchX < 24; swatchX++)
{
	draw_set_color(hCol[swatchX])
	draw_rectangle(1652+(swatchX*10), 744, 1652+9+(swatchX*10), 753, 0)
}

#endregion


// ============================================================
// PREVIEW MAP SELECTOR (click left panel to switch viewed map)
// ============================================================
#region

// Clicking a map NAME (x 1024-1240, left of the tick boxes) switches the
// canvas to that map by setting img. Rows are in screen order, so the img
// numbers on the right are out of sequence on purpose. A tenth row below
// Frizz is the live Previewer (img 9).
// resetSets() deselects any selected set (setSelectedID = -1), so changing
// view always returns the sliders to the global values.
var vSpace = 27

if mouse_check_button_pressed(mb_left)
{
	if mouse_x > 1024 and mouse_x < 1240
	{
		if mouse_y > 130-vSpace       and mouse_y < 158-vSpace       { img=0; resetSets() } // RGB Mask
		if mouse_y > 130              and mouse_y < 158              { img=1; resetSets() } // Normal Map
		if mouse_y > 130+(vSpace*1)   and mouse_y < 158+(vSpace*1)   { img=5; resetSets() } // Mask Map
		if mouse_y > 130+(vSpace*2)   and mouse_y < 158+(vSpace*2)   { img=4; resetSets() } // Color Map
		if mouse_y > 130+(vSpace*3)   and mouse_y < 158+(vSpace*3)   { img=2; resetSets() } // ID Map
		if mouse_y > 130+(vSpace*4)   and mouse_y < 158+(vSpace*4)   { img=3; resetSets() } // Depth Map
		if mouse_y > 130+(vSpace*5)   and mouse_y < 158+(vSpace*5)   { img=6; resetSets() } // Flow Map
		if mouse_y > 130+(vSpace*6)   and mouse_y < 158+(vSpace*6)   { img=7; resetSets() } // AO Map
		if mouse_y > 130+(vSpace*7)   and mouse_y < 158+(vSpace*7)   { img=8; resetSets() } // Frizz Map
		if mouse_y > 130+(vSpace*8)   and mouse_y < 158+(vSpace*8)   { img=9; resetSets() } // Previewer
	}
}

#endregion


// ============================================================
// GHOST SPRITE + MAIN CALCULATION
// ============================================================
#region

// ghostSprite is a screen grab taken by checkAndOffset() when a set is
// isolated (right-click while dragging it). It is drawn at 40% alpha over the
// canvas; holding right mouse hides it. checkAndOffset() deletes it on the
// next right click.
if sprite_exists(ghostSprite) and !mouse_check_button(mb_right)
	draw_sprite_part_ext(ghostSprite, 0, 0, 0, 1024, 1024, 0, 0, 1, 1, c_white, 0.4)

// mainCalc() (scripts/mainCalc) does three things, in this order:
//  1. restores the click-only colour slot (undoes the hover block above),
//  2. previewUpdate() - rebuilds whichever sets' preview surfaces changed,
//  3. draws the 11 preview surfaces onto the canvas (plus set highlighting).
// It must run BEFORE the slider blocks: edits made by the sliders this frame
// are picked up by previewUpdate() on the next frame.
mainCalc() // === MAIN STRAND CALCULATION ===
// V1.97 - remembered for BACK TO THE PREVIEWER (before GEN STATE SYNC): a
// change made in this event sets pleaseGen, and that is how it is noticed.
var _pleaseGenBefore = pleaseGen

// V1.91 - localUpdateSet describes the per-set edit made on the PREVIOUS frame.
// mainCalc() has just consumed it, and the slider blocks further down this event
// will set it again if the user is still editing one set. Clearing it here is
// what keeps a global edit from being mistaken for a local one.
localUpdateSet = -1

// "Please generate" banner, top centre of the canvas, while the maps are stale.
draw_set_color(c_white)
if pleaseGen draw_sprite(spr_genMessage, 0, 512, 32)

#endregion


// ============================================================
// RANDOMISATION DICE BUTTON
// ============================================================
#region

// Dice button: 30x30 at (1056,980), bottom-left of the panel beside the Seed
// readout. Seeds:
//   seedVal            the global seed shown when no set is selected
//   randomSeedVal[s]   the seed each set actually uses
//   randomOverride[s]  1 = this set has its own seed; global re-rolls skip it
// makeRandom is only the dice sprite frame: it flips here and alarm[0]
// (2 frames later) sets it back to 0, giving a short "pressed" flash.
if point_in_rectangle(mouse_x, mouse_y, 1056, 980, 1086, 1010)
{
	smallTip = "Dice - click for a new random seed. Right-click gives every set that is not overridden its own new seed"

	

	// Left click: toggle random mode, update seed
	if mouse_check_button_pressed(mb_left)
	{
		makeRandom = 1 - makeRandom
		if makeRandom == 1 randomize()
		seedVal = random_get_seed()
		random_set_seed(seedVal)

		if setSelectedID != -1
		{
			// Affect only the selected set
			// The set is marked as overridden and given seedVal+1.
			// NOTE: the test below indexes randomOverride with `s`, not
			// setSelectedID. `s` is an instance variable left over from the
			// last for-loop that used it, so which set is tested is not obvious.
			if randomOverride[s] == 1 seedVal = randomSeedVal[setSelectedID]
			randomOverride[setSelectedID]    = 1
			randomSeedVal[setSelectedID]     = seedVal + 1
		}
		else
		{
			// Affect all non-overridden sets
			// Each gets a fresh random(55555), which is a NON-integer seed
			// (the right-click path below uses irandom instead).
			seedValstring = seedVal
			for (s = 0; s < sets+1; s++)
			{
				if randomOverride[s] != 1 randomSeedVal[s] = random(55555);
				
			}
		}

		pleaseGen = true
		alarm[0]  = 2
	}

	// Right click: fully re-randomise all non-overridden sets
	// Loops all 12 slots (the left-click path loops sets+1). seedVal ends up
	// holding the last seed handed out, and that is what the readout shows.
	if mouse_check_button_pressed(mb_right)
	{
		randomize()
		random_set_seed(seedVal)

		for (s = 0; s < 12; s++)
		{
			if randomOverride[s] != 1
			{
				seedVal        = irandom(9999999)
				randomSeedVal[s] = seedVal
			}
		}

		pleaseGen = true
		alarm[0]  = 2
	}
}

draw_sprite(spr_dice, makeRandom, 1071, 996) // draw dice button

#endregion


// ============================================================
// VIEWER BOX POSITION (drag with left mouse in canvas area)
// ============================================================
#region

// DISABLED: the body is commented out, so this block does nothing. xxx/yyy
// (top-left of the 512x512 zoom window, in 4096-map pixels) are not set
// anywhere in this event; here they are only clamped and drawn.
if mouse_check_button(mb_left) and mouse_x < 1024 and mouse_y < 1024 and !generating
{
//	xxx = (mouse_x * 4) - 256
//	yyy = (mouse_y * 4) - 256
}

#endregion


// ============================================================
// SAVE / EXPORT BUTTON
// ============================================================
#region

// Top-right button of the panel's top bar (x 1333-1376, y 9-51): export the
// maps. It fakes pressing S, so the work is in the S key event (KeyPress_83).
// projectOnly = false means "export textures", as opposed to the project-only
// Save icon further down, which sets it true before faking the same key.
// NOTE: only keyboard_key_press is called here, with no matching release.
if mouse_x > 1333 and mouse_x < 1376 and mouse_y > 9 and mouse_y < 51
{
	if mouse_check_button_pressed(mb_left)
	{
		draw_sprite(spr_ExportMaps, saving, 512, 512)
		projectOnly = false
		keyboard_key_press(ord("S"))
	}
}

#endregion


// ============================================================
// QUIT / ROOM SWITCH BUTTON
// ============================================================
#region

// Top-left button of the panel's top bar (x 1032-1077, y 9-51).
// In the main room it runs User Event 0 (deselects sets and sets exiting =
// true, which opens the EXIT CONFIRMATION DIALOG at the end of this event).
// In the path-editing room the same button just returns to the main room.
if mouse_x > 1032 and mouse_x < 1077 and mouse_y > 9 and mouse_y < 51
{
	if mouse_check_button_pressed(mb_left) and room == Room_HSD         event_user(0)
	if mouse_check_button_pressed(mb_left) and room == Room_PathEditing  room = Room_HSD
}

#endregion


// ============================================================
// HELPER MACRO - numpad input block (reused per slider textbox)
// ============================================================
// NOTE: Each slider textbox section below uses an identical numpad switch block.
// To add a new key, add it to this pattern in each relevant section.
// A helper script would reduce duplication — left as-is to preserve legibility.
// (There is no actual macro: the block is copy-pasted. The newest rows,
// Clumping / Clump Var, DO use a shared function: uiClumpSlider in clumpTools.
// It is the same logic in one place and is the easiest version to read.)
//
// EVERY SLIDER BLOCK BELOW HAS THE SAME FIVE PARTS, IN THIS ORDER.
// The Strand Count block is commented in full; the rest are labelled briefly.
//   1. Setup      ex/ey = left end and centre line of the track, slx = notch x.
//   2. Grab       press inside the track -> set this slider's drag latch.
//   3. Drag       while latched: value = mouse x - ex, clamped. Writes the
//                 per-set value or the global (see header). Sets pleaseGen.
//   4. Draw       notch sprite on the track + the number in the box.
//   5. Text box   click the number to type a value; applied on every frame
//                 while the box is open, Enter sets forceUpdate.
// If a slider misbehaves, compare its block against Strand Count line by line:
// the usual cause is one name left unchanged from the block it was copied from.


// ============================================================
// SLIDER: STRAND COUNT
// ============================================================
#region

// Row 0 "Strands". Range 0-100. Global: strands.
// Per set: strandCountOverride[], flag setCountOverrode[].
// over = notch sprite frame (1 = highlighted while dragging)
// ex   = x of the left end of the track = value 0
// ey   = y of the row centre (row 0 = 436; other rows add 28 per row)
// sly  = y the notch is drawn at (same as ey)
// slx  = x the notch is drawn at = ex + value, because 1px = 1 unit
var over = 0
var ex   = 1198
var ey   = 436
var sly  = ey
var slx  = ex + strands
if setSelectedID != -1 slx = ex + strandCountOverride[setSelectedID]   // a selected set shows its own value

// Activate slider on press within range
// Track hit area: 100px wide, 10px above and below the centre line.
// nullify_sliderInterracts() first drops every other slider's latch, so only
// one slider can ever be dragging.
if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_strands = true }
	}
}

// Drag slider
// Runs for as long as the button is held after a grab, wherever the mouse is
// (the clamp keeps the notch on the track).
// reset_textBoxes(): an open number box would otherwise re-apply its old text
// on top of the dragged value every frame.
// localUpdateSet records which set was edited (see the note after mainCalc()).
if mouse_check_button(mb_left) && slider_interract_strands
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes()
	pleaseGen = true

	if setSelectedID != -1
	{
		// A set is selected: change only that set and flag it as overridden.
		strandCountOverride[setSelectedID] = clamp(slx-ex, 0, 100)
		setCountOverrode[setSelectedID]    = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		// No set selected: change the global, then copy it into every set
		// slot (all 12) that has not been overridden.
		strands = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setCountOverrode[setChange] != 1 strandCountOverride[setChange] = strands
		}
	}
}

// Draw notch and value
// Text colour: tbCol normally, tbColOver when the selected set overrides this
// row. The number is drawn at x=1318, inside the box painted in spr_UI.
// The notch x is clamp(slx, ex, ex+value), so the notch never sits to the
// right of the stored value even if the mouse does. That matters on rows where
// the value is limited further than the track (e.g. a Min that cannot pass
// its Max).
draw_set_color(tbCol)
if (setSelectedID != -1 && setCountOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom)
draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strands), sly);                                draw_text(1318, ey+11, string(strands)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandCountOverride[setSelectedID]), sly);    draw_text(1318, ey+11, string(strandCountOverride[setSelectedID])) }
draw_set_color(c_white)

// Textbox click
// The number box is x 1312-1376 on this row. A click inside opens it: every
// other box is closed, and the typing buffer `str` is loaded with the current
// value (the set's value if a set is selected). A click anywhere else closes
// it. textBox_strands_value is a copy of the text kept alongside.
if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_strands = 1
		if setSelectedID == -1 { str = string(strands);                                  textBox_strands_value = string(strands) }
		if setSelectedID != -1 { str = string(strandCountOverride[setSelectedID]);       textBox_strands_value = string(strandCountOverride[setSelectedID]) }
	}
}
else
{
	if mouse_check_button_pressed(mb_left) textBox_strands = 0
}

// Textbox active: draw, handle input
if textBox_strands == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setCountOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	// Caret: a 2px vertical line just after the text. tickytime counts 0..1
	// and wraps (Step_1); the caret shows for 0.5-0.9 of each cycle = blink.
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	// Numpad keys are read from keyboard_key (the key currently held), so they
	// are handled separately from the main-row digits below, which come from
	// keyboard_lastkey. The length test (< 3 here) is the maximum number of
	// digits the box accepts: 3 for 0-100 boxes, 2 for 0-40, 4 for Length.
	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	// (8 = vk_backspace. An emptied box becomes "0" so real(str) never fails.)
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		// keyboard_lastkey is set back to -1 so each key press is used once.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	// Cap the typed text at the slider maximum, then apply it straight away:
	// the value is written every frame the box is open, not only on Enter.
	if real(str) > 100 str = "100"
	textBox_strands_value = str

	if setSelectedID != -1
	{
		strandCountOverride[setSelectedID] = clamp(real(str), 0, 100)
		setCountOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		strands = clamp(real(str), 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setCountOverrode[setChange] != 1 strandCountOverride[setChange] = strands
		}
	}

	// Enter asks the preview for a rebuild. The box itself is closed by FRAME
	// CLEANUP at the very end of this event (reset_textBoxes on Enter).
	// Unlike the drag path, typing does not set localUpdateSet.
	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: STRAND COUNT


// ============================================================
// SLIDER: STRAND DISTANCINGS (spacing between strands)
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*2)   // row 2 "Spacing". 0-100. Global: distancings. Per set: strandSetSpaceAdj[], flag setSpacingOverrode[]
var sly  = ey
var slx  = ex + distancings
if setSelectedID != -1 slx = ex + strandSetSpaceAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_distancings = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_distancings
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandSetSpaceAdj[setSelectedID]   = clamp(slx-ex, 0, 100)
		setSpacingOverrode[setSelectedID]  = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		distancings = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setSpacingOverrode[setChange] != 1 strandSetSpaceAdj[setChange] = distancings
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setSpacingOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom)
draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+distancings), sly);                         draw_text(1318, ey+11, string(distancings)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetSpaceAdj[setSelectedID]), sly);    draw_text(1318, ey+11, string(strandSetSpaceAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_distancings = 1
		if setSelectedID == -1 { str = string(distancings);                              textBox_distancings_value = string(distancings) }
		if setSelectedID != -1 { str = string(strandSetSpaceAdj[setSelectedID]);         textBox_distancings_value = string(strandSetSpaceAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_distancings = 0 }

if textBox_distancings == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setSpacingOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_distancings_value = str

	if setSelectedID != -1
	{
		strandSetSpaceAdj[setSelectedID] = clamp(real(str), 0, 100)
		setSpacingOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		distancings = clamp(real(str), 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setSpacingOverrode[setChange] != 1 strandSetSpaceAdj[setChange] = distancings
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: DISTANCINGS


// ============================================================
// SLIDER: SET DISTANCE (spacing between sets)
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*3)   // row 3 "Distance". 0-100. Global only: setDistance
var sly  = ey
var slx  = ex + setDistance
// This row has NO per-set version (it is the gap between sets), so there is
// no setSelectedID branch, no override colour and no localUpdateSet here.

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_setDistancings = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_setDistancings
{
	over       = 1
	slx        = clamp(mouse_x, ex, ex+100); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag
	setDistance = clamp(slx-ex, 0, 100)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+100), sly)
draw_set_color(tbCol)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318, ey+11, string(setDistance))
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                      = string(setDistance)
		textBox_setDistance      = 1
		textBox_setDistance_value = string(setDistance)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_setDistance = 0 }

if textBox_setDistance == 1
{
	draw_set_color(tbCol)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_setDistance_value = str

	setDistance = clamp(real(str), 0, 100)

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: SET DISTANCE


// ============================================================
// SLIDER: WAVYNESS
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*4)   // row 4 "Waviness". 0-100. Global: wavyness. Per set: strandSetWavynessAdj[], flag setWaveynessOverrode[]
var sly  = ey
var slx  = ex + wavyness
if setSelectedID != -1 slx = ex + strandSetWavynessAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_wavyness = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_wavyness
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandSetWavynessAdj[setSelectedID]  = clamp(slx-ex, 0, 100)
		setWaveynessOverrode[setSelectedID]  = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		wavyness = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveynessOverrode[setChange] != 1 strandSetWavynessAdj[setChange] = wavyness
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setWaveynessOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+wavyness), sly);                              draw_text(1318, ey+11, string(wavyness)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetWavynessAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(strandSetWavynessAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_wavyness = 1
		if setSelectedID == -1 { str = string(wavyness);                              textBox_wavyness_value = string(wavyness) }
		if setSelectedID != -1 { str = string(strandSetWavynessAdj[setSelectedID]);   textBox_wavyness_value = string(strandSetWavynessAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_wavyness = 0 }

if textBox_wavyness == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setWaveynessOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_wavyness_value = str

	if setSelectedID != -1
	{
		strandSetWavynessAdj[setSelectedID] = clamp(real(str), 0, 100)
		setWaveynessOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		wavyness = clamp(real(str), 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveynessOverrode[setChange] != 1 strandSetWavynessAdj[setChange] = wavyness
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: WAVYNESS


// ============================================================
// DUAL SLIDERS: WAVE FREQUENCY MIN + MAX
// ============================================================
// Row 5 "Wave Freq". First of the DUAL rows: two 0-40 sliders share one row.
//   left  slider: track x 1198-1238, number box x 1312-1340, text at 1318
//   right slider: track x 1258-1298 (ex = 1198+60), box x 1347-1376, text at 1318+34
// Number boxes take 2 digits (string_length(str) < 2) and cap at 40.
// Min and Max are kept in order: Min is written as min(new, Max) and Max as
// max(new, Min), both for the global pair and for each set's own pair, so
// neither notch can cross the other.
// Global: minFreq / maxFreq. Per set: strandSetWaveFreqMinAdj[] /
// strandSetWaveFreqMaxAdj[], flags setWaveFreqMinOverrode[] / setWaveFreqMaxOverrode[].

// ---- Min Freq (left half) ----
#region
// Left slider of row 5. Writes minFreq, or strandSetWaveFreqMinAdj[set].
// In the global branch each non-overridden set gets min(minFreq, that set's
// Max), so a set whose Max is overridden lower is not pushed past it.

var over = 0
var ex   = 1198
var ey   = 436 + (28*5)
var sly  = ey
var slx  = ex + minFreq
if setSelectedID != -1 slx = ex + strandSetWaveFreqMinAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_minFreq = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_minFreq
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()

	if setSelectedID != -1
	{
		strandSetWaveFreqMinAdj[setSelectedID]  = min(clamp(slx-ex, 0, 40), strandSetWaveFreqMaxAdj[setSelectedID])
		setWaveFreqMinOverrode[setSelectedID]   = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		minFreq = min(clamp(slx-ex, 0, 40), maxFreq)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMinOverrode[setChange] != 1 strandSetWaveFreqMinAdj[setChange] = min(minFreq, strandSetWaveFreqMaxAdj[setChange])
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setWaveFreqMinOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+minFreq), sly);                                  draw_text(1318, ey+11, string(minFreq)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetWaveFreqMinAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(strandSetWaveFreqMinAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_minFreq = 1
		if setSelectedID == -1 { str = string(minFreq);                                  textBox_minFreq_value = string(minFreq) }
		if setSelectedID != -1 { str = string(strandSetWaveFreqMinAdj[setSelectedID]);   textBox_minFreq_value = string(strandSetWaveFreqMinAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_minFreq = 0 }

if textBox_minFreq == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setWaveFreqMinOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_minFreq_value = str

	if setSelectedID != -1
	{
		strandSetWaveFreqMinAdj[setSelectedID] = min(clamp(real(str), 0, 40), strandSetWaveFreqMaxAdj[setSelectedID])
		setWaveFreqMinOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		minFreq = min(clamp(real(str), 0, 40), maxFreq)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMinOverrode[setChange] != 1 strandSetWaveFreqMinAdj[setChange] = min(minFreq, strandSetWaveFreqMaxAdj[setChange])
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FREQ MIN

// ---- Max Freq (right half) ----
#region
// Right slider of row 5 (ex = 1198+60). Writes maxFreq, or
// strandSetWaveFreqMaxAdj[set]. Mirror image of Min Freq, using max().

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*5)
var sly  = ey
var slx  = ex + maxFreq
if setSelectedID != -1 slx = ex + strandSetWaveFreqMaxAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_maxFreq = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_maxFreq
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()

	if setSelectedID != -1
	{
		strandSetWaveFreqMaxAdj[setSelectedID]  = max(clamp(slx-ex, 0, 40), strandSetWaveFreqMinAdj[setSelectedID])
		setWaveFreqMaxOverrode[setSelectedID]   = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		maxFreq = max(clamp(slx-ex, 0, 40), minFreq)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMaxOverrode[setChange] != 1 strandSetWaveFreqMaxAdj[setChange] = max(maxFreq, strandSetWaveFreqMinAdj[setChange])
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setWaveFreqMaxOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+maxFreq), sly);                                  draw_text(1318+34, ey+11, string(maxFreq)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetWaveFreqMaxAdj[setSelectedID]), sly);   draw_text(1318+34, ey+11, string(strandSetWaveFreqMaxAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_maxFreq = 1
		if setSelectedID == -1 { str = string(maxFreq);                                  textBox_maxFreq_value = string(maxFreq) }
		if setSelectedID != -1 { str = string(strandSetWaveFreqMaxAdj[setSelectedID]);   textBox_maxFreq_value = string(strandSetWaveFreqMaxAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_maxFreq = 0 }

if textBox_maxFreq == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setWaveFreqMaxOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_maxFreq_value = str

	if setSelectedID != -1
	{
		strandSetWaveFreqMaxAdj[setSelectedID] = max(clamp(real(str), 0, 40), strandSetWaveFreqMinAdj[setSelectedID])
		setWaveFreqMaxOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		maxFreq = max(clamp(real(str), 0, 40), minFreq)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMaxOverrode[setChange] != 1 strandSetWaveFreqMaxAdj[setChange] = max(maxFreq, strandSetWaveFreqMinAdj[setChange])
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FREQ MAX


// ============================================================
// SLIDER: TAPERING
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*6)   // row 6 "Tapering". 0-100. Global: tapering. Per set: strandSetTaperAdj[], flag setTaperOverrode[]
var sly  = ey
var slx  = ex + tapering
if setSelectedID != -1 slx = ex + strandSetTaperAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_tapering = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_tapering
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandSetTaperAdj[setSelectedID]  = clamp(slx-ex, 0, 100)
		setTaperOverrode[setSelectedID]   = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		tapering = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setTaperOverrode[setChange] != 1 strandSetTaperAdj[setChange] = tapering
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setTaperOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+tapering), sly);                            draw_text(1318, ey+11, string(tapering)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetTaperAdj[setSelectedID]), sly);    draw_text(1318, ey+11, string(strandSetTaperAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_tapering = 1
		if setSelectedID == -1 { str = string(tapering);                              textBox_tapering_value = string(tapering) }
		if setSelectedID != -1 { str = string(strandSetTaperAdj[setSelectedID]);      textBox_tapering_value = string(strandSetTaperAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_tapering = 0 }

if textBox_tapering == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setTaperOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_tapering_value = str

	if setSelectedID != -1
	{
		strandSetTaperAdj[setSelectedID] = clamp(real(str), 0, 100)
		setTaperOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		tapering = clamp(real(str), 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setTaperOverrode[setChange] != 1 strandSetTaperAdj[setChange] = tapering
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: TAPERING


// ============================================================
// SLIDER: LIFE VARIANT (strand length variation)
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*7)   // row 7 "Variation". Global: lifeVariant. Per set: strandSetVariAdj[], flag setVariOverrode[]
// Range is 1-100: both the drag and the typed value are clamped to a minimum of 1, never 0.
var sly  = ey
var slx  = ex + lifeVariant
if setSelectedID != -1 slx = ex + strandSetVariAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_lifeVariant = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_lifeVariant
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandSetVariAdj[setSelectedID]  = clamp(slx-ex, 1, 100)
		setVariOverrode[setSelectedID]   = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		lifeVariant = clamp(slx-ex, 1, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setVariOverrode[setChange] != 1 strandSetVariAdj[setChange] = lifeVariant
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setVariOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+lifeVariant), sly);                            draw_text(1318, ey+11, string(lifeVariant)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetVariAdj[setSelectedID]), sly);        draw_text(1318, ey+11, string(strandSetVariAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_lifeVariant = 1
		if setSelectedID == -1 { str = string(lifeVariant);                              textBox_lifeVariant_value = string(lifeVariant) }
		if setSelectedID != -1 { str = string(strandSetVariAdj[setSelectedID]);           textBox_lifeVariant_value = string(strandSetVariAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_lifeVariant = 0 }

if textBox_lifeVariant == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setVariOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_lifeVariant_value = str

	if setSelectedID != -1
	{
		strandSetVariAdj[setSelectedID] = clamp(real(str), 1, 100)
		setVariOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		lifeVariant = clamp(real(str), 1, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setVariOverrode[setChange] != 1 strandSetVariAdj[setChange] = lifeVariant
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: LIFE VARIANT


// ============================================================
// SLIDER: Y RANDOM RANGE (root Y variation)
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*8)   // row 8 "Root Jitter". Global: yRanRange. Per set: strandYRanRange[], flag strandYRanRangeOverrode[]
// Range is 1-100: both the drag and the typed value are clamped to a minimum of 1, never 0.
var sly  = ey
var slx  = ex + yRanRange
if setSelectedID != -1 slx = ex + strandYRanRange[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_yRanRange = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_yRanRange
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandYRanRange[setSelectedID]         = clamp(slx-ex, 1, 100)
		strandYRanRangeOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		yRanRange = clamp(slx-ex, 1, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if strandYRanRangeOverrode[setChange] != 1 strandYRanRange[setChange] = yRanRange
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && strandYRanRangeOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+yRanRange), sly);                         draw_text(1318, ey+11, string(yRanRange)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandYRanRange[setSelectedID]), sly);    draw_text(1318, ey+11, string(strandYRanRange[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_YRanRange = 1
		if setSelectedID == -1 { str = string(yRanRange);                              textBox_YRanRange_value = string(yRanRange) }
		if setSelectedID != -1 { str = string(strandYRanRange[setSelectedID]);          textBox_YRanRange_value = string(strandYRanRange[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_YRanRange = 0 }

if textBox_YRanRange == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and strandYRanRangeOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_YRanRange_value = str

	if setSelectedID != -1
	{
		strandYRanRange[setSelectedID] = clamp(real(str), 1, 100)
		strandYRanRangeOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		yRanRange = clamp(real(str), 1, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if strandYRanRangeOverrode[setChange] != 1 strandYRanRange[setChange] = yRanRange
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: Y RANDOM RANGE


// ============================================================
// DUAL SLIDERS: THICKNESS MIN + MAX (strand width range)
// ============================================================

// Row 9 "Thick Rng". Dual row, each 1-40 (minimum 1, never 0). Min/Max are
// kept in order with min()/max() exactly as on the Wave Freq row.
// Global: minScale / maxScale. Per set: setThickMinAdj[] / setThickMaxAdj[],
// flags setThickMinOverrode[] / setThickMaxOverrode[].
// NOTE: unlike the other per-set rows, these two blocks have no
// "if setSelectedID != -1 slx = ..." line, so slx always starts from the
// GLOBAL value. With a set selected the notch is then drawn at
// clamp(global, ex, ex+set value), i.e. at whichever of the two is smaller.
// The number in the box is still the set's own value.

// ---- Thickness Min (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*9)
var sly  = ey
var slx  = ex + minScale

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_minScale = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_minScale
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setThickMinAdj[setSelectedID]      = min(clamp(slx-ex, 1, 40), setThickMaxAdj[setSelectedID])
		setThickMinOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		minScale = min(clamp(slx-ex, 1, 40), maxScale)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMinOverrode[setChange] != 1 setThickMinAdj[setChange] = min(minScale, setThickMaxAdj[setChange])
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setThickMinOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+minScale), sly);                         draw_text(1318, ey+11, string(minScale)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setThickMinAdj[setSelectedID]), sly);    draw_text(1318, ey+11, string(setThickMinAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_minScale = 1
		if setSelectedID == -1 { str = string(minScale);                              textBox_minScale_value = string(minScale) }
		if setSelectedID != -1 { str = string(setThickMinAdj[setSelectedID]);         textBox_minScale_value = string(setThickMinAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_minScale = 0 }

if textBox_minScale == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setThickMinOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_minScale_value = str

	if setSelectedID != -1
	{
		setThickMinAdj[setSelectedID] = min(clamp(real(str), 1, 40), setThickMaxAdj[setSelectedID])
		setThickMinOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		minScale = min(clamp(real(str), 1, 40), maxScale)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMinOverrode[setChange] != 1 setThickMinAdj[setChange] = min(minScale, setThickMaxAdj[setChange])
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: THICKNESS MIN

// ---- Thickness Max (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*9)
var sly  = ey
var slx  = ex + maxScale

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_maxScale = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_maxScale
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setThickMaxAdj[setSelectedID]      = max(clamp(slx-ex, 1, 40), setThickMinAdj[setSelectedID])
		setThickMaxOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		maxScale = max(clamp(slx-ex, 1, 40), minScale)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMaxOverrode[setChange] != 1 setThickMaxAdj[setChange] = max(maxScale, setThickMinAdj[setChange])
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setThickMaxOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+maxScale), sly);                         draw_text(1318+34, ey+11, string(maxScale)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setThickMaxAdj[setSelectedID]), sly);    draw_text(1318+34, ey+11, string(setThickMaxAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		if maxScale < 1 maxScale = 1
		textBox_maxScale = 1
		if setSelectedID == -1 { str = string(maxScale);                              textBox_maxScale_value = string(maxScale) }
		if setSelectedID != -1 { str = string(setThickMaxAdj[setSelectedID]);         textBox_maxScale_value = string(setThickMaxAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_maxScale = 0 }

if textBox_maxScale == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setThickMaxOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_maxScale_value = str

	if setSelectedID != -1
	{
		setThickMaxAdj[setSelectedID] = max(clamp(real(str), 1, 40), setThickMinAdj[setSelectedID])
		setThickMaxOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		maxScale = max(clamp(real(str), 1, 40), minScale)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMaxOverrode[setChange] != 1 setThickMaxAdj[setChange] = max(maxScale, setThickMinAdj[setChange])
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: THICKNESS MAX


// ============================================================
// DUAL SLIDERS: TIP THICK + ROOT THICK (root/tip thickness range)
// V1.91 - now per-set overridable (the row carries a notch in the panel art)
// ============================================================
// Row 10 "Thick Adj". Dual row, each 0-40, independent of each other (no
// min/max ordering). Left = Tip, right = Root.
// Global: tipThick / rootThick. Per set: setTipThickAdj[] / setRootThickAdj[],
// flags setTipThickOverrode[] / setRootThickOverrode[].

// ---- Tip Thick (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*10)
var sly  = ey
var slx  = ex + tipThick
if setSelectedID != -1 slx = ex + setTipThickAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_tipThick = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_tipThick
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setTipThickAdj[setSelectedID] = clamp(slx-ex, 0, 40)
		setTipThickOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		tipThick = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setTipThickOverrode[setChange] != 1 setTipThickAdj[setChange] = tipThick
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setTipThickOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+tipThick), sly);                        draw_text(1318, ey+11, string(tipThick)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setTipThickAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(setTipThickAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_tipThick = 1
		if setSelectedID == -1 { str = string(tipThick);                        textBox_tipThick_value = string(tipThick) }
		if setSelectedID != -1 { str = string(setTipThickAdj[setSelectedID]);   textBox_tipThick_value = string(setTipThickAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_tipThick = 0 }

if textBox_tipThick == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setTipThickOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_tipThick_value = str

	if setSelectedID != -1
	{
		setTipThickAdj[setSelectedID] = clamp(real(str), 0, 40)
		setTipThickOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		tipThick = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setTipThickOverrode[setChange] != 1 setTipThickAdj[setChange] = tipThick
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: TIP THICK

// ---- Root Thick (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*10)
var sly  = ey
var slx  = ex + rootThick
if setSelectedID != -1 slx = ex + setRootThickAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_rootThick = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_rootThick
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setRootThickAdj[setSelectedID] = clamp(slx-ex, 0, 40)
		setRootThickOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		rootThick = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setRootThickOverrode[setChange] != 1 setRootThickAdj[setChange] = rootThick
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setRootThickOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+rootThick), sly);                        draw_text(1318+34, ey+11, string(rootThick)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setRootThickAdj[setSelectedID]), sly);   draw_text(1318+34, ey+11, string(setRootThickAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_rootThick = 1
		if setSelectedID == -1 { str = string(rootThick);                        textBox_rootThick_value = string(rootThick) }
		if setSelectedID != -1 { str = string(setRootThickAdj[setSelectedID]);   textBox_rootThick_value = string(setRootThickAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_rootThick = 0 }

if textBox_rootThick == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setRootThickOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_rootThick_value = str

	if setSelectedID != -1
	{
		setRootThickAdj[setSelectedID] = clamp(real(str), 0, 40)
		setRootThickOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		rootThick = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setRootThickOverrode[setChange] != 1 setRootThickAdj[setChange] = rootThick
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: ROOT THICK


// ============================================================
// SLIDER: THICK VARY (thickness variance)
// V1.91 - now per-set overridable
// ============================================================

// ---- Thick Vary ----
#region
// Row 11 "Thick Var". Single 0-100 slider with the wide number box.
// Global: thickVary. Per set: setThickVaryAdj[], flag setThickVaryOverrode[].

var over = 0
var ex   = 1198
var ey   = 436 + (28*11)
var sly  = ey
var slx  = ex + thickVary
if setSelectedID != -1 slx = ex + setThickVaryAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_thickVary = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_thickVary
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setThickVaryAdj[setSelectedID] = clamp(slx-ex, 0, 100)
		setThickVaryOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		thickVary = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickVaryOverrode[setChange] != 1 setThickVaryAdj[setChange] = thickVary
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setThickVaryOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+thickVary), sly);                        draw_text(1318, ey+11, string(thickVary)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setThickVaryAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(setThickVaryAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_thickVary = 1
		if setSelectedID == -1 { str = string(thickVary);                        textBox_thickVary_value = string(thickVary) }
		if setSelectedID != -1 { str = string(setThickVaryAdj[setSelectedID]);   textBox_thickVary_value = string(setThickVaryAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_thickVary = 0 }

if textBox_thickVary == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setThickVaryOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 3
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 3
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 100 str = "100"
	textBox_thickVary_value = str

	if setSelectedID != -1
	{
		setThickVaryAdj[setSelectedID] = clamp(real(str), 0, 100)
		setThickVaryOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		thickVary = clamp(real(str), 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickVaryOverrode[setChange] != 1 setThickVaryAdj[setChange] = thickVary
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: THICK VARY


// ============================================================
// DUAL SLIDERS: FADE IN + FADE OUT
// V1.91 - now per-set overridable
// ============================================================

// Row 12 "Fading". Dual row, each 1-40 (minimum 1, never 0), independent.
// Global: fadeIn / fadeOut. Per set: setFadeInAdj[] / setFadeOutAdj[],
// flags setFadeInOverrode[] / setFadeOutOverrode[].

// ---- Fade In (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*12)
var sly  = ey
var slx  = ex + fadeIn
if setSelectedID != -1 slx = ex + setFadeInAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_fadeIn = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_fadeIn
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setFadeInAdj[setSelectedID] = clamp(slx-ex, 1, 40)
		setFadeInOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		fadeIn = clamp(slx-ex, 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setFadeInOverrode[setChange] != 1 setFadeInAdj[setChange] = fadeIn
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setFadeInOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+fadeIn), sly);                        draw_text(1318, ey+11, string(fadeIn)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setFadeInAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(setFadeInAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_fadeIn = 1
		if setSelectedID == -1 { str = string(fadeIn);                        textBox_fadeIn_value = string(fadeIn) }
		if setSelectedID != -1 { str = string(setFadeInAdj[setSelectedID]);   textBox_fadeIn_value = string(setFadeInAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_fadeIn = 0 }

if textBox_fadeIn == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setFadeInOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_fadeIn_value = str

	if setSelectedID != -1
	{
		setFadeInAdj[setSelectedID] = clamp(real(str), 1, 40)
		setFadeInOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		fadeIn = clamp(real(str), 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setFadeInOverrode[setChange] != 1 setFadeInAdj[setChange] = fadeIn
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FADE IN

// ---- Fade Out (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*12)
var sly  = ey
var slx  = ex + fadeOut
if setSelectedID != -1 slx = ex + setFadeOutAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_fadeOut = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_fadeOut
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setFadeOutAdj[setSelectedID] = clamp(slx-ex, 1, 40)
		setFadeOutOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		fadeOut = clamp(slx-ex, 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setFadeOutOverrode[setChange] != 1 setFadeOutAdj[setChange] = fadeOut
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setFadeOutOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+fadeOut), sly);                        draw_text(1318+34, ey+11, string(fadeOut)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setFadeOutAdj[setSelectedID]), sly);   draw_text(1318+34, ey+11, string(setFadeOutAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_fadeOut = 1
		if setSelectedID == -1 { str = string(fadeOut);                        textBox_fadeOut_value = string(fadeOut) }
		if setSelectedID != -1 { str = string(setFadeOutAdj[setSelectedID]);   textBox_fadeOut_value = string(setFadeOutAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_fadeOut = 0 }

if textBox_fadeOut == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setFadeOutOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "1"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_fadeOut_value = str

	if setSelectedID != -1
	{
		setFadeOutAdj[setSelectedID] = clamp(real(str), 1, 40)
		setFadeOutOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		fadeOut = clamp(real(str), 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setFadeOutOverrode[setChange] != 1 setFadeOutAdj[setChange] = fadeOut
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FADE OUT


// ============================================================
// DUAL SLIDERS: NOISE AMOUNT + NOISE FREQUENCY  (V1.90)
// Row 13, directly under Fading. Amount 0 = off.
// V1.91 - now per-set overridable
// ============================================================

// Dual row, each 0-40, independent.
// Global: noiseAmt / noiseFreq. Per set: setNoiseAmtAdj[] / setNoiseFreqAdj[],
// flags setNoiseAmtOverrode[] / setNoiseFreqOverrode[].

// ---- Noise Amount (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*13)
var sly  = ey
var slx  = ex + noiseAmt
if setSelectedID != -1 slx = ex + setNoiseAmtAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_noiseAmt = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_noiseAmt
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setNoiseAmtAdj[setSelectedID] = clamp(slx-ex, 0, 40)
		setNoiseAmtOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		noiseAmt = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setNoiseAmtOverrode[setChange] != 1 setNoiseAmtAdj[setChange] = noiseAmt
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setNoiseAmtOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+noiseAmt), sly);                        draw_text(1318, ey+11, string(noiseAmt)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setNoiseAmtAdj[setSelectedID]), sly);   draw_text(1318, ey+11, string(setNoiseAmtAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_noiseAmt = 1
		if setSelectedID == -1 { str = string(noiseAmt);                        textBox_noiseAmt_value = string(noiseAmt) }
		if setSelectedID != -1 { str = string(setNoiseAmtAdj[setSelectedID]);   textBox_noiseAmt_value = string(setNoiseAmtAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_noiseAmt = 0 }

if textBox_noiseAmt == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setNoiseAmtOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_noiseAmt_value = str

	if setSelectedID != -1
	{
		setNoiseAmtAdj[setSelectedID] = clamp(real(str), 0, 40)
		setNoiseAmtOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		noiseAmt = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setNoiseAmtOverrode[setChange] != 1 setNoiseAmtAdj[setChange] = noiseAmt
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: NOISE AMOUNT

// ---- Noise Frequency (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*13)
var sly  = ey
var slx  = ex + noiseFreq
if setSelectedID != -1 slx = ex + setNoiseFreqAdj[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_noiseFreq = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_noiseFreq
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		setNoiseFreqAdj[setSelectedID] = clamp(slx-ex, 0, 40)
		setNoiseFreqOverrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		noiseFreq = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setNoiseFreqOverrode[setChange] != 1 setNoiseFreqAdj[setChange] = noiseFreq
		}
	}
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setNoiseFreqOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+noiseFreq), sly);                        draw_text(1318+34, ey+11, string(noiseFreq)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+setNoiseFreqAdj[setSelectedID]), sly);   draw_text(1318+34, ey+11, string(setNoiseFreqAdj[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_noiseFreq = 1
		if setSelectedID == -1 { str = string(noiseFreq);                        textBox_noiseFreq_value = string(noiseFreq) }
		if setSelectedID != -1 { str = string(setNoiseFreqAdj[setSelectedID]);   textBox_noiseFreq_value = string(setNoiseFreqAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_noiseFreq = 0 }

if textBox_noiseFreq == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setNoiseFreqOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_noiseFreq_value = str

	if setSelectedID != -1
	{
		setNoiseFreqAdj[setSelectedID] = clamp(real(str), 0, 40)
		setNoiseFreqOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		noiseFreq = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setNoiseFreqOverrode[setChange] != 1 setNoiseFreqAdj[setChange] = noiseFreq
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: NOISE FREQUENCY


// ============================================================
// DUAL SLIDERS: CLUMPING (V1.96)
// Row 17 "Clumping"  - Amount | Count
// Row 18 "Clump Var" - Start  | Scatter
// Both rows are baked into spr_UI below Mixer 3, at the same 28px pitch.
// Same behaviour as the Noise row; see uiClumpSlider in clumpTools.
// ============================================================
#region
// uiClumpSlider(k, track left x, row centre y, readout x). k picks the clump
// parameter: 0 Amount, 1 Count, 2 Start, 3 Scatter. Each is 0-40, per-set
// overridable (setClump*Adj[] / setClump*Overrode[]), and sets its own
// smallTip. The function is the whole slider + number box in one place.
uiClumpSlider(0, 1198,      436 + (28*17), 1318)      // Amount
uiClumpSlider(1, 1198 + 60, 436 + (28*17), 1318 + 34) // Count
uiClumpSlider(2, 1198,      436 + (28*18), 1318)      // Start
uiClumpSlider(3, 1198 + 60, 436 + (28*18), 1318 + 34) // Scatter
#endregion
// END SLIDERS: CLUMPING


// ============================================================
// SLIDER: STRAND LENGTH
// ============================================================
#region
// Row 1 "Length" (it sits out of order in this file, after the Clumping rows;
// on screen it is the second row). Global: length. Per set:
// strandLengthOverride[], flag setLengthOverrode[].
// This is the only row where 1px is not 1 unit: length runs 38 to 3800 and
// the 100px track maps to it as value = track pixels * 38.
// So dragging moves in steps of 38, while the number box accepts any whole
// value from 38 to 3800 (4 digits). An emptied box becomes "38", the minimum.
// The grab area is a little wider than the track (ex+110) and the drag clamp
// is ex+101; the value itself is still clamped to 1..100 steps.

var over = 0
var ex   = 1198
var ey   = 436 + (28*1)
var sly  = ey
var slx  = ex + (length / 38) // scale: length range 0–3800 → slider 0–100px
if setSelectedID != -1 slx = ex + (strandLengthOverride[setSelectedID] / 38)

if mouse_x >= ex and mouse_x <= ex+110
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_length = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_length
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+101)
	reset_textBoxes(); pleaseGen = true

	if setSelectedID != -1
	{
		strandLengthOverride[setSelectedID] = clamp(slx-ex, 1, 100) * 38
		setLengthOverrode[setSelectedID]    = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		length = clamp(slx-ex, 1, 100) * 38
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setLengthOverrode[setChange] != 1 strandLengthOverride[setChange] = length
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setLengthOverrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+(length/38)), sly);                                  draw_text(1318, ey+11, string(length)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+(strandLengthOverride[setSelectedID]/38)), sly);    draw_text(1318, ey+11, string(strandLengthOverride[setSelectedID])) }

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_length = 1
		if setSelectedID == -1 { str = string(length);                                  textBox_length_value = string(length) }
		if setSelectedID != -1 { str = string(strandLengthOverride[setSelectedID]);     textBox_length_value = string(strandLengthOverride[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_length = 0 }

if textBox_length == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setLengthOverrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 4
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "38"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 4
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 3800 str = "3800"
	textBox_length_value = str

	if setSelectedID != -1
	{
		strandLengthOverride[setSelectedID] = clamp(real(str), 38, 3800)
		setLengthOverrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		length = clamp(real(str), 38, 3800)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setLengthOverrode[setChange] != 1 strandLengthOverride[setChange] = length
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: STRAND LENGTH


// ============================================================
// MIXER SLIDERS (3x dual-slider pairs: amount + offset)
// Each mixer has: left = amount (0–40), right = offset (0–40)
// ============================================================
// Rows 14, 15, 16 = Mixer 1, 2, 3. Six blocks, all the plain dual-row pattern
// (independent, 2-digit boxes). Clicking the mixer NAME to edit its curve is
// not handled in this file.
//   Mixer n amount: global mixer<n>,        per set strandSetMixerAdj<n>[],       flag setMixerAmt<n>Overrode[]
//   Mixer n offset: global mixer<n>_offset, per set strandSetMixerOffsetAdj<n>[], flag setMixerOfs<n>Overrode[]
// These rows have no override dots in UI EXTRAS further down.

// ---- Mixer 1 Amount (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*14)
var sly  = ey
var slx  = ex + mixer1
if setSelectedID != -1 slx = ex + strandSetMixerAdj1[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer1 = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer1
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()

	if setSelectedID != -1
	{
		strandSetMixerAdj1[setSelectedID]    = clamp(slx-ex, 0, 40)
		setMixerAmt1Overrode[setSelectedID]  = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer1 = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt1Overrode[setChange] != 1 strandSetMixerAdj1[setChange] = mixer1
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerAmt1Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer1), sly);                             draw_text(1318, ey+11, string(mixer1)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerAdj1[setSelectedID]), sly);  draw_text(1318, ey+11, string(strandSetMixerAdj1[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer1 = 1
		if setSelectedID == -1 { str = string(mixer1);                              textBox_mixer1_value = string(mixer1) }
		if setSelectedID != -1 { str = string(strandSetMixerAdj1[setSelectedID]);   textBox_mixer1_value = string(strandSetMixerAdj1[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer1 = 0 }

if textBox_mixer1 == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerAmt1Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer1_value = str

	if setSelectedID != -1
	{
		strandSetMixerAdj1[setSelectedID] = clamp(real(str), 0, 40)
		setMixerAmt1Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer1 = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt1Overrode[setChange] != 1 strandSetMixerAdj1[setChange] = mixer1
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 1 AMOUNT

// ---- Mixer 1 Offset (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*14)
var sly  = ey
var slx  = ex + mixer1_offset
if setSelectedID != -1 slx = ex + strandSetMixerOffsetAdj1[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer1_offset = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer1_offset
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj1[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs1Overrode[setSelectedID]     = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer1_offset = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs1Overrode[setChange] != 1 strandSetMixerOffsetAdj1[setChange] = mixer1_offset
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerOfs1Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer1_offset), sly);                                  draw_text(1318+34, ey+11, string(mixer1_offset)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerOffsetAdj1[setSelectedID]), sly);        draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj1[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer1_offset = 1
		if setSelectedID == -1 { str = string(mixer1_offset);                              textBox_mixer1_offset_value = string(mixer1_offset) }
		if setSelectedID != -1 { str = string(strandSetMixerOffsetAdj1[setSelectedID]);    textBox_mixer1_offset_value = string(strandSetMixerOffsetAdj1[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer1_offset = 0 }

if textBox_mixer1_offset == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerOfs1Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer1_offset_value = str

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj1[setSelectedID] = clamp(real(str), 0, 40)
		setMixerOfs1Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer1_offset = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs1Overrode[setChange] != 1 strandSetMixerOffsetAdj1[setChange] = mixer1_offset
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 1 OFFSET


// ---- Mixer 2 Amount (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*15)
var sly  = ey
var slx  = ex + mixer2
if setSelectedID != -1 slx = ex + strandSetMixerAdj2[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer2 = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer2
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()

	if setSelectedID != -1
	{
		strandSetMixerAdj2[setSelectedID]   = clamp(slx-ex, 0, 40)
		setMixerAmt2Overrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer2 = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt2Overrode[setChange] != 1 strandSetMixerAdj2[setChange] = mixer2
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerAmt2Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer2), sly);                             draw_text(1318, ey+11, string(mixer2)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerAdj2[setSelectedID]), sly);  draw_text(1318, ey+11, string(strandSetMixerAdj2[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer2 = 1
		if setSelectedID == -1 { str = string(mixer2);                              textBox_mixer2_value = string(mixer2) }
		if setSelectedID != -1 { str = string(strandSetMixerAdj2[setSelectedID]);   textBox_mixer2_value = string(strandSetMixerAdj2[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer2 = 0 }

if textBox_mixer2 == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerAmt2Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer2_value = str

	if setSelectedID != -1
	{
		strandSetMixerAdj2[setSelectedID] = clamp(real(str), 0, 40)
		setMixerAmt2Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer2 = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt2Overrode[setChange] != 1 strandSetMixerAdj2[setChange] = mixer2
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 2 AMOUNT

// ---- Mixer 2 Offset (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*15)
var sly  = ey
var slx  = ex + mixer2_offset
if setSelectedID != -1 slx = ex + strandSetMixerOffsetAdj2[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer2_offset = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer2_offset
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj2[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs2Overrode[setSelectedID]     = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer2_offset = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs2Overrode[setChange] != 1 strandSetMixerOffsetAdj2[setChange] = mixer2_offset
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerOfs2Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer2_offset), sly);                              draw_text(1318+34, ey+11, string(mixer2_offset)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerOffsetAdj2[setSelectedID]), sly);    draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj2[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer2_offset = 1
		if setSelectedID == -1 { str = string(mixer2_offset);                              textBox_mixer2_offset_value = string(mixer2_offset) }
		if setSelectedID != -1 { str = string(strandSetMixerOffsetAdj2[setSelectedID]);    textBox_mixer2_offset_value = string(strandSetMixerOffsetAdj2[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer2_offset = 0 }

if textBox_mixer2_offset == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerOfs2Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer2_offset_value = str

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj2[setSelectedID] = clamp(real(str), 0, 40)
		setMixerOfs2Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer2_offset = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs2Overrode[setChange] != 1 strandSetMixerOffsetAdj2[setChange] = mixer2_offset
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 2 OFFSET


// ---- Mixer 3 Amount (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*16)
var sly  = ey
var slx  = ex + mixer3
if setSelectedID != -1 slx = ex + strandSetMixerAdj3[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer3 = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer3
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()

	if setSelectedID != -1
	{
		strandSetMixerAdj3[setSelectedID]   = clamp(slx-ex, 0, 40)
		setMixerAmt3Overrode[setSelectedID] = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer3 = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt3Overrode[setChange] != 1 strandSetMixerAdj3[setChange] = mixer3
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerAmt3Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer3), sly);                             draw_text(1318, ey+11, string(mixer3)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerAdj3[setSelectedID]), sly);  draw_text(1318, ey+11, string(strandSetMixerAdj3[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer3 = 1
		if setSelectedID == -1 { str = string(mixer3);                              textBox_mixer3_value = string(mixer3) }
		if setSelectedID != -1 { str = string(strandSetMixerAdj3[setSelectedID]);   textBox_mixer3_value = string(strandSetMixerAdj3[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer3 = 0 }

if textBox_mixer3 == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerAmt3Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+2+string_width(str), ey-9, 1318+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer3_value = str

	if setSelectedID != -1
	{
		strandSetMixerAdj3[setSelectedID] = clamp(real(str), 0, 40)
		setMixerAmt3Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer3 = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerAmt3Overrode[setChange] != 1 strandSetMixerAdj3[setChange] = mixer3
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 3 AMOUNT

// ---- Mixer 3 Offset (right) ----
#region

var over = 0
var ex   = 1198 + 60
var ey   = 436 + (28*16)
var sly  = ey
var slx  = ex + mixer3_offset
if setSelectedID != -1 slx = ex + strandSetMixerOffsetAdj3[setSelectedID]

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_mixer3_offset = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_mixer3_offset
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+40); pleaseGen = true
	reset_textBoxes()   // an open box would re-apply its stale text over this drag

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj3[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs3Overrode[setSelectedID]     = 1
		localUpdateSet = setSelectedID
	}
	else
	{
		mixer3_offset = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs3Overrode[setChange] != 1 strandSetMixerOffsetAdj3[setChange] = mixer3_offset
		}
	}
	draw_set_color(c_white)
}

draw_set_color(tbCol)
if (setSelectedID != -1 && setMixerOfs3Overrode[setSelectedID] != 0) draw_set_color(tbColOver)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+mixer3_offset), sly);                              draw_text(1318+34, ey+11, string(mixer3_offset)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandSetMixerOffsetAdj3[setSelectedID]), sly);    draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj3[setSelectedID])) }
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		textBox_mixer3_offset = 1
		if setSelectedID == -1 { str = string(mixer3_offset);                              textBox_mixer3_offset_value = string(mixer3_offset) }
		if setSelectedID != -1 { str = string(strandSetMixerOffsetAdj3[setSelectedID]);    textBox_mixer3_offset_value = string(strandSetMixerOffsetAdj3[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_mixer3_offset = 0 }

if textBox_mixer3_offset == 1
{
	draw_set_color(tbCol)
	if setSelectedID != -1 and setMixerOfs3Overrode[setSelectedID] != 0 draw_set_color(tbColOver)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)

	// Draw the buffer being typed, not the stored variable - the readout and
	// the caret then always agree with each other and with what was keyed in.
	draw_text(1318+34, ey+11, str)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1318+34+2+string_width(str), ey-9, 1318+34+2+string_width(str), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input
	if string_length(str) < 2
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Backspace runs first and OUTSIDE the digit-count gate. It used to sit
	// inside it, so a box padded to the limit ("0000") accepted neither a
	// digit nor a backspace and could only be escaped by clicking away.
	if keyboard_lastkey == 8
	{
		str = string_copy(str, 1, string_length(str)-1)
		if str == "" str = "0"
		keyboard_lastkey = -1
	}
	else if keyboard_lastkey != -1 and string_length(str) < 2
	{
		// 48-57 only. 46 is vk_delete, not '.', and accepting it appended
		// whatever keyboard_lastchar still held - repeating the last digit.
		if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
		keyboard_lastkey = -1
	}

	if real(str) > 40 str = "40"
	textBox_mixer3_offset_value = str

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj3[setSelectedID] = clamp(real(str), 0, 40)
		setMixerOfs3Overrode[setSelectedID] = 1
	}
	else
	{
		// The global is only written when NO set is selected. It used to be
		// assigned first either way, so editing one set quietly moved the
		// global setting and every set that follows it.
		mixer3_offset = clamp(real(str), 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setMixerOfs3Overrode[setChange] != 1 strandSetMixerOffsetAdj3[setChange] = mixer3_offset
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 3 OFFSET


// ============================================================
// COLOUR SLIDERS: ROOT POSITION + TIP POSITION
// ============================================================

// Two short 0-100 sliders in the colour panel (track x 1522-1622), at y 686
// and 705, under the Root / Tip swatches. They set rootPosition / tipPosition.
// Global only (no per-set version), no number box, and they only set
// pleaseGen - they do not reset text boxes or set forceUpdate.

// ---- Root Position ----
#region
// NOTE: written differently from Tip Position below: here the drag code is
// INSIDE the hover test, so the value only follows the mouse while the mouse
// is still within the track rectangle (y within 11px). Tip keeps following
// once grabbed, like the panel sliders.

var over = 0
var ex   = 1522
var ey   = 686
var sly  = ey
var slx  = ex + rootPosition

if mouse_x >= ex and mouse_x <= ex+100 and mouse_y > sly-11 and mouse_y < sly+11
{
	if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_rootPosition = true }
	if slider_interract_rootPosition over = 1
	if mouse_check_button(mb_left) && slider_interract_rootPosition
	{
		slx          = clamp(mouse_x, ex, ex+100); pleaseGen = true
		rootPosition = clamp(slx-ex, 0, 100)
	}
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+100), sly)

#endregion
// END SLIDER: ROOT POSITION

// ---- Tip Position ----
#region

var over = 0
var ex   = 1522
var ey   = 705
var sly  = ey
var slx  = ex + tipPosition

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_tipPosition = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_tipPosition
{
	over        = 1
	slx         = clamp(mouse_x, ex, ex+100); pleaseGen = true
	tipPosition = clamp(slx-ex, 0, 100)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+100), sly)

#endregion
// END SLIDER: TIP POSITION

// Reset all slider interactions on mouse release
// This is the one place the drag latches are dropped. The three colour channel
// sliders further down are latched the same way and rely on this line too
// (it runs before them, so their last frame of drag is the frame before release).
if mouse_check_button_released(mb_left) nullify_sliderInterracts()


// ============================================================
// STRAND COUNT DISPLAY (per-set totals row)
// ============================================================
#region

// Small "N strands" label under each set number button (80px apart, starting
// x=1040, y=1068) and the grand total at (1338,1010).
// A set is counted only when set_active[mm] == 0. Create_0 sets every entry
// to 0, so 0 is the normal "counted" state here.
// A per-set count of 0 is treated as "no value, use the global strands", so a
// set deliberately overridden to 0 is shown and counted with the global count.
var total = 0
draw_set_halign(fa_left)
draw_set_font(smallFont)
var countXpos = 1040
var countYpos = 1068

for (mm = 0; mm < sets+1; mm++)
{
	// Accumulate total (inactive sets excluded)
	if strandCountOverride[mm] == 0
		{ if set_active[mm] == 0 total += strands }
	else
		{ if set_active[mm] == 0 total += strandCountOverride[mm] }

	// Draw per-set count
	if strandCountOverride[mm] == 0
		{ if set_active[mm] == 0 draw_text(countXpos+(mm*80), countYpos, string(strands)+" strands") }
	else
		{ if set_active[mm] == 0 draw_text(countXpos+(mm*80), countYpos, string(strandCountOverride[mm])+" strands") }
}

draw_set_font(font_tipFont)
draw_text(1338, 1010, "Total number of strands to generate: "+string(total)
                      +"  Previewing "+string(maxPreviewStrandsPerSet)+" max per set")

#endregion


// ============================================================
// COLOUR SWATCHES (background / A / B / root / tip)
// ============================================================
#region

// Fill the five swatch boxes with their current colours (same column the
// click/hover tests use: x 1569-1631, 27px apart from y 541).
draw_set_color(colrBack)    draw_rectangle(1569, 541, 1631, 565, 0)
draw_set_color(customColVarA)  draw_rectangle(1569, 568, 1631, 592, 0)
draw_set_color(customColVarB)  draw_rectangle(1569, 595, 1631, 619, 0)
draw_set_color(customRootCol)  draw_rectangle(1569, 622, 1631, 646, 0)
draw_set_color(customTipCol)   draw_rectangle(1569, 649, 1631, 673, 0)

// Old / new colour comparison bar
// Left half = storeColor (the colour the slot had when it was selected),
// right half = newColor (what the sliders / hex box / picker are editing).
draw_set_color(storeColor) draw_rectangle(1658, 760, 1771, 790, 0)
draw_set_color(newColor)   draw_rectangle(1772, 760, 1885, 790, 0)

#endregion


// ============================================================
// COLOUR MODE BUTTONS (RGB / HSV / Grey)
// ============================================================
#region

// Three small buttons at y 822-837 under the channel sliders. colorMode only
// changes how the three sliders read and write newColor (0 RGB, 1 HSV,
// 2 Grey); it does not change any colour by itself. It is also the frame of
// the two sprites drawn below (the mode tag and the button strip).
if mouse_check_button_pressed(mb_left)
{
	if mouse_x >= 1475 and mouse_x <= 1506 and mouse_y >= 822 and mouse_y <= 837 colorMode = 0 // RGB
	if mouse_x >= 1519 and mouse_x <= 1563 and mouse_y >= 822 and mouse_y <= 837 colorMode = 1 // HSV
	if mouse_x >= 1563 and mouse_x <= 1594 and mouse_y >= 822 and mouse_y <= 837 colorMode = 2 // Grey
}

draw_sprite(spr_colorModeTag, colorMode, 1443, 761)
draw_sprite(spr_ColorModes,   colorMode, 1473, 822)

#endregion


// ============================================================
// COLOUR SLIDERS (RGB / HSV / Grey depending on colorMode)
// ============================================================
#region

// Three channel sliders at y 771, 790, 809, track x 1471-1600.
// Scale: 2 colour units per pixel (0-255 over ~128px), so
//   notch x = 1471 + channel/2      and      channel = (mouse_x - 1471) * 2.
// They edit newColor, then APPLY_NEW_COLOR copies newColor into whichever
// swatch slot is active and asks the preview for a recolour.
// The notch sprite frame is the slider's drag latch (highlight while dragged).

// Calculate notch positions based on current colour mode
if colorMode == 0 // RGB
{
	var redPos = 1471 + (color_get_red(newColor)   / 2)
	var grnPos = 1471 + (color_get_green(newColor) / 2)
	var bluPos = 1471 + (color_get_blue(newColor)  / 2)
	draw_sprite(spr_smallNotch, slider_interract_redHue, redPos, 771)
draw_sprite(spr_smallNotch, slider_interract_grnSat, grnPos, 790)
draw_sprite(spr_smallNotch, slider_interract_bluVal, bluPos, 809)

}
if colorMode == 1 // HSV
{
	var redPos = 1471 + (color_get_hue(newColor)        / 2)
	var grnPos = 1471 + (color_get_saturation(newColor) / 2)
	var bluPos = 1471 + (color_get_value(newColor)      / 2)
	draw_sprite(spr_smallNotch, slider_interract_redHue, redPos, 771)
draw_sprite(spr_smallNotch, slider_interract_grnSat, grnPos, 790)
draw_sprite(spr_smallNotch, slider_interract_bluVal, bluPos, 809)

}
if colorMode == 2 // Greyscale (all three sliders track value)
{
	var redPos = 1471 + (color_get_value(newColor) / 2)
	var grnPos = redPos
	var bluPos = redPos
	draw_sprite(spr_smallNotch, slider_interract_redHue, redPos, 771)
draw_sprite(spr_smallNotch, slider_interract_grnSat, grnPos, 790)
draw_sprite(spr_smallNotch, slider_interract_bluVal, bluPos, 809)

}

draw_set_color(c_white)

// Draw channel value labels
// Numbers at x=1608, one per slider (21px apart). Grey mode shows the R, G, B
// values, which are all equal there.
if colorMode == 0 or colorMode == 2
{
	draw_text(1608, 777,    string(color_get_red(newColor)))
	draw_text(1608, 777+21, string(color_get_green(newColor)))
	draw_text(1608, 777+42, string(color_get_blue(newColor)))
}
if colorMode == 1
{
	draw_text(1608, 777,    string(round(color_get_hue(newColor))))
	draw_text(1608, 777+21, string(round(color_get_saturation(newColor))))
	draw_text(1608, 777+42, string(round(color_get_value(newColor))))
}

// Helper macro: apply newColor to whichever swatch is active
// It is used four times below (three sliders + hex editor). After copying the
// colour it sets colorOnlyUpdate + forceUpdate and clears
// previewCanvasComplete, which makes the preview recolour itself. It does NOT
// set pleaseGen. Because it is a macro the text is pasted in place, so it
// reads and writes this instance's variables directly.
// (A #macro is global to the project even though it is defined mid-event;
// do not add comments on the macro's own lines.)
#macro APPLY_NEW_COLOR \
	if bkCol_active   == 1 colrBack      = newColor \
	if ColA_active    == 1 customColVarA  = newColor \
	if ColB_active    == 1 customColVarB  = newColor \
	if RootCol_active == 1 customRootCol  = newColor \
	if TipCol_active  == 1 customTipCol   = newColor \
	colorOnlyUpdate      = 1 \
	previewCanvasComplete = 0 \
	forceUpdate          = 1

// Red / Hue slider
// Grab within 6px of the line, then drag (latched). The slider changes ONE
// channel and rebuilds newColor from it plus the other two channels read back
// from newColor. In HSV mode hue is clamped to 254, not 255. In Grey mode all
// three sliders do the same thing: set R = G = B.
if mouse_x >= 1471 and mouse_x <= 1600 and mouse_y > 771-6 and mouse_y < 771+6
{
	if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_redHue = true }
}
if mouse_check_button(mb_left) && slider_interract_redHue
{
	if colorMode == 0 newColor = make_color_rgb(clamp((mouse_x-1471)*2, 0, 255), color_get_green(newColor), color_get_blue(newColor))
	if colorMode == 1 newColor = make_color_hsv(clamp((mouse_x-1471)*2, 0, 254), color_get_saturation(newColor), color_get_value(newColor))
	if colorMode == 2 newColor = make_color_rgb(clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255))
	APPLY_NEW_COLOR
}

// Green / Sat slider
if mouse_x >= 1471 and mouse_x <= 1600 and mouse_y > 790-6 and mouse_y < 790+6
{
	if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_grnSat = true }
}
if mouse_check_button(mb_left) && slider_interract_grnSat
{
	if colorMode == 0 newColor = make_color_rgb(color_get_red(newColor), clamp((mouse_x-1471)*2, 0, 255), color_get_blue(newColor))
	if colorMode == 1 newColor = make_color_hsv(color_get_hue(newColor), clamp((mouse_x-1471)*2, 0, 255), color_get_value(newColor))
	if colorMode == 2 newColor = make_color_rgb(clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255))
	APPLY_NEW_COLOR
}

// Blue / Val slider
if mouse_x >= 1471 and mouse_x <= 1600 and mouse_y > 809-6 and mouse_y < 809+6
{
	if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_bluVal = true }
}
if mouse_check_button(mb_left) && slider_interract_bluVal
{
	if colorMode == 0 newColor = make_color_rgb(color_get_red(newColor), color_get_green(newColor), clamp((mouse_x-1471)*2, 0, 255))
	if colorMode == 1 newColor = make_color_hsv(color_get_hue(newColor), color_get_saturation(newColor), clamp((mouse_x-1471)*2, 0, 255))
	if colorMode == 2 newColor = make_color_rgb(clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255), clamp((mouse_x-1471)*2, 0, 255))
	APPLY_NEW_COLOR
}

#endregion


// ============================================================
// HEX COLOUR EDITOR
// ============================================================
#region

// Hex readout / input for newColor, in the colour panel. The text is drawn at
// (1535,738); the click rectangle for the field is x 1519-1632, y 715-735.
// hexColEdit = true while typing. The typing buffer is str2 (6 characters max,
// RRGGBB), separate from the sliders' str.
draw_set_color(tbCol)

// Build hex string from current colour components
// Each channel becomes two hex digits. The "" -> "00" test is a safety net;
// dec_to_hex already returns "00" for 0.
hexColR = dec_to_hex(color_get_red(newColor));   if hexColR == "" hexColR = "00"
hexColG = dec_to_hex(color_get_green(newColor));  if hexColG == "" hexColG = "00"
hexColB = dec_to_hex(color_get_blue(newColor));   if hexColB == "" hexColB = "00"

if !hexColEdit
{
	hexColString = hexColR + hexColG + hexColB
	draw_set_font(regFont)
	draw_text(1535, 738, hexColString)
	draw_set_color(c_white)
}

// Exit hex edit mode on Enter
if keyboard_check_pressed(vk_enter) hexColEdit = false

// Click into / out of hex field
// Clicking the field starts editing from the current hex text; any other
// click ends it. Note this does not call reset_textBoxes(), so a slider
// number box can stay open at the same time and both will read the keyboard.
if mouse_check_button_pressed(mb_left)
{
	if mouse_x > 1519 and mouse_x < 1632 and mouse_y > 715 and mouse_y < 735
	{
		hexColEdit  = true
		editHexColor = hexColString
		str2         = editHexColor
	}
	else hexColEdit = false
}

if hexColEdit
{
	draw_set_color(tbCol)
	draw_set_font(regFont)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1536+string_width(string(str2)), 733, 1536+string_width(string(str2)), 719, 2)

	// Backspace first, so it can never be swallowed by the length gate below.
	if keyboard_lastkey == 8
	{
		str2 = string_copy(str2, 1, string_length(str2)-1)
		keyboard_lastkey = -1
	}
	// Character input (hex digits 0-9, a-f, A-F). 46 is vk_delete, not '.', and
	// accepting it appended whatever keyboard_lastchar still held.
	else if keyboard_lastkey != -1 and string_length(str2) <= 5
	{
		if (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
		   or (keyboard_lastkey >= 65 and keyboard_lastkey <= 70)
		   or (keyboard_lastkey >= 97 and keyboard_lastkey <= 102)
			str2 += keyboard_lastchar
		keyboard_lastkey = -1
	}

	// Numpad input
	#region
	if string_length(str2) <= 5
	{
		switch (keyboard_key)
		{
			case vk_numpad0: str2+="0"; keyboard_lastkey=-1; break
			case vk_numpad1: str2+="1"; keyboard_lastkey=-1; break
			case vk_numpad2: str2+="2"; keyboard_lastkey=-1; break
			case vk_numpad3: str2+="3"; keyboard_lastkey=-1; break
			case vk_numpad4: str2+="4"; keyboard_lastkey=-1; break
			case vk_numpad5: str2+="5"; keyboard_lastkey=-1; break
			case vk_numpad6: str2+="6"; keyboard_lastkey=-1; break
			case vk_numpad7: str2+="7"; keyboard_lastkey=-1; break
			case vk_numpad8: str2+="8"; keyboard_lastkey=-1; break
			case vk_numpad9: str2+="9"; keyboard_lastkey=-1; break
		}
	}
	#endregion

	// Applied on every frame while editing, not only on Enter: characters
	// 1-2 = red, 3-4 = green, 5-6 = blue. While the text is still short the
	// missing pairs are empty strings, so the colour changes as you type.
	// APPLY_NEW_COLOR then pushes it into the active swatch and the preview.
	editHexColor = str2
	newColor = make_color_rgb(
	    hex_to_dec(string_copy(editHexColor, 1, 2)),
	    hex_to_dec(string_copy(editHexColor, 3, 2)),
	    hex_to_dec(string_copy(editHexColor, 5, 2)))

APPLY_NEW_COLOR

	draw_text(1535, 738, editHexColor)
	draw_set_color(c_white)
}

#endregion


// ============================================================
// FLOW / ID DIRECTION MODE BUTTONS
// ============================================================
#region

// A strip of five toggle buttons at y 389-408, between the map list and the
// slider rows. Each one only affects ONE map, so instead of pleaseGen it puts
// just that map's GenState back to its tick-box value (do*): a generated map
// (2) drops to 1 = "needs generating again", a disabled one stays 0.

// ID strand-vs-set toggle
// idMode 0 = ID colour per strand, 1 = per set (see the labels in SURFACE DISPLAY).
draw_sprite(spr_strandOrSet, idMode, 1272, 390)
if mouse_x >= 1272 and mouse_x <= 1376 and mouse_y >= 389 and mouse_y <= 408
{
	if mouse_check_button_pressed(mb_left)
	{
		idMode       = 1 - idMode
		id_GenState  = doID
	}
}

// Flow direction toggles
// Four 50px buttons from x=1050: Flip X, Flip Y, Blue mode, Hue. They change
// how the flow map is encoded (dirFlipX / dirFlipY / dirBlue / dirHue) and
// mark only the flow map as stale.
draw_sprite(spr_FlipX,    dirFlipX, 1050, 390)
draw_sprite(spr_FlipY,    dirFlipY, 1104, 390)
draw_sprite(spr_BlueMode, dirBlue,  1158, 390)
draw_sprite(spr_Hue,      dirHue,   1214, 390)

if mouse_check_button_pressed(mb_left) and mouse_y >= 389 and mouse_y <= 408
{
	if mouse_x >= 1050 and mouse_x <= 1100 { dirFlipX = 1-dirFlipX; flow_GenState = doFlow }
	if mouse_x >= 1104 and mouse_x <= 1154 { dirFlipY = 1-dirFlipY; flow_GenState = doFlow }
	if mouse_x >= 1158 and mouse_x <= 1208 { dirBlue  = 1-dirBlue;  flow_GenState = doFlow }
	if mouse_x >= 1214 and mouse_x <= 1264 { dirHue   = 1-dirHue;   flow_GenState = doFlow }
}

#endregion


// ============================================================
// GEN STATE SYNC (reset map states when pleaseGen is flagged)
// ============================================================
#region

// V1.97 - BACK TO THE PREVIEWER. Moving a slider (or typing a value, picking
// a colour, rolling the dice: anything that marks the maps stale) while a
// rendered map is on view (img 0-8) switches back to the Previewer, as the P
// key does, so the change can be seen. Not during a render.
// The slider test also catches a drag that continues after the maps were
// already stale (pleaseGen already true, so it does not change this frame).
if img != 9 and !doOnce and ((pleaseGen and !_pleaseGenBefore) or (mouse_check_button(mb_left) and uiSliderHeld()))
{
	currentMapPreview = img
	img = 9
}

// While pleaseGen is set, every map's state is forced back to its tick-box
// value: generated maps (2) become 1 (enabled, not generated), disabled stay
// 0. This is what makes the export icons disappear and the "Not generated or
// settings changed" warning appear after any setting is touched.
// ORDER: this sits after all the sliders/buttons that set pleaseGen and
// before SURFACE DISPLAY, so the warning shows on the same frame as the edit.
if pleaseGen
{
	rgbMask_GenState = doRGB
	norm_GenState    = doNorm
	mask_GenState    = doMask
	color_GenState   = doColor
	id_GenState      = doID
	depth_GenState   = doDepth
	flow_GenState    = doFlow
	ao_GenState      = doAO
	frizz_GenState   = doFrizz
}

#endregion


// ============================================================
// BLUR PASS (B key or blur button — applies shader pass)
// ============================================================
#region

// Blurs the 4096x4096 map currently being viewed, IN PLACE: the result is
// written back into the real canvas, so the blur is part of what gets
// exported, and it cannot be undone except by generating again.
// The test uses keyboard_check / mouse_check_button (held, not pressed), so
// the blur is applied again on EVERY frame the key or button is held: holding
// longer = more blur.
// BLUR button: bottom bar, x 906-963, y 1027-1051.
// The img -> canvas mapping is repeated in each step below because the
// surfaces are separate variables; all five lists must stay identical.
if (keyboard_check(ord("B")) or point_in_rectangle(mouse_x, mouse_y, 906, 1027, 963, 1051) and mouse_check_button(mb_left))
   and img != 9 // not in previewer mode
{
	// Helper to select the right canvas by img index
	// Copy source into blur surface
	if img == 0 surface_copy(blurSurface, 0, 0, canvas)
	if img == 1 surface_copy(blurSurface, 0, 0, nm_canvas)
	if img == 5 surface_copy(blurSurface, 0, 0, mask_canvas)
	if img == 4 surface_copy(blurSurface, 0, 0, color_canvas)
	if img == 2 surface_copy(blurSurface, 0, 0, id_canvas)
	if img == 3 surface_copy(blurSurface, 0, 0, depth_canvas)
	if img == 6 surface_copy(blurSurface, 0, 0, flow_canvas)
	if img == 7 surface_copy(blurSurface, 0, 0, ao_canvas)
	if img == 8 surface_copy(blurSurface, 0, 0, frizz_canvas)

	// Vertical blur pass
	// Draws the ORIGINAL canvas through the vertical shader into blurSurface.
	// 4096 = the surface size the shader needs to work out one texel.
	shader_set(shd_gaussian_vertical)
	shader_set_uniform_f(uni_resolution_vert, 4096, 4096)
	shader_set_uniform_f(uni_blur_amount_vert, var_blur_amount * 1.0)
	surface_set_target(blurSurface)
	if img == 0 draw_surface_ext(canvas,       0, 0, 1, 1, 0, c_white, 1)
	if img == 1 draw_surface_ext(nm_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 5 draw_surface_ext(mask_canvas,  0, 0, 1, 1, 0, c_white, 1)
	if img == 4 draw_surface_ext(color_canvas, 0, 0, 1, 1, 0, c_white, 1)
	if img == 2 draw_surface_ext(id_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 3 draw_surface_ext(depth_canvas, 0, 0, 1, 1, 0, c_white, 1)
	if img == 6 draw_surface_ext(flow_canvas,  0, 0, 1, 1, 0, c_white, 1)
	if img == 7 draw_surface_ext(ao_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 8 draw_surface_ext(frizz_canvas, 0, 0, 1, 1, 0, c_white, 1)
	surface_reset_target()
	shader_reset()

	// Horizontal blur pass (lighter amount)
	// NOTE: this pass also draws the ORIGINAL canvas (not the vertically
	// blurred blurSurface) into blurSurface, on top of the vertical result.
	// So the two passes are layered, not chained. Horizontal strength is a
	// quarter of the vertical.
	shader_set(shd_gaussian_horizontal)
	shader_set_uniform_f(uni_resolution_hoz, 4096, 4096)
	shader_set_uniform_f(uni_blur_amount_hoz, var_blur_amount * 0.25)
	surface_set_target(blurSurface)
	if img == 0 draw_surface_ext(canvas,       0, 0, 1, 1, 0, c_white, 1)
	if img == 1 draw_surface_ext(nm_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 5 draw_surface_ext(mask_canvas,  0, 0, 1, 1, 0, c_white, 1)
	if img == 4 draw_surface_ext(color_canvas, 0, 0, 1, 1, 0, c_white, 1)
	if img == 2 draw_surface_ext(id_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 3 draw_surface_ext(depth_canvas, 0, 0, 1, 1, 0, c_white, 1)
	if img == 6 draw_surface_ext(flow_canvas,  0, 0, 1, 1, 0, c_white, 1)
	if img == 7 draw_surface_ext(ao_canvas,    0, 0, 1, 1, 0, c_white, 1)
	if img == 8 draw_surface_ext(frizz_canvas, 0, 0, 1, 1, 0, c_white, 1)
	surface_reset_target()
	shader_reset()

	// Additive brightness compensation pass
	// Adds 2.1% of the original back on top to offset the slight darkening.
	gpu_set_blendmode(bm_add)
	surface_set_target(blurSurface)
	var amount = 0.021
	if img == 0 draw_surface_ext(canvas,       0, 0, 1, 1, 0, c_white, amount)
	if img == 1 draw_surface_ext(nm_canvas,    0, 0, 1, 1, 0, c_white, amount)
	if img == 5 draw_surface_ext(mask_canvas,  0, 0, 1, 1, 0, c_white, amount)
	if img == 4 draw_surface_ext(color_canvas, 0, 0, 1, 1, 0, c_white, amount)
	if img == 2 draw_surface_ext(id_canvas,    0, 0, 1, 1, 0, c_white, amount)
	if img == 3 draw_surface_ext(depth_canvas, 0, 0, 1, 1, 0, c_white, amount)
	if img == 6 draw_surface_ext(flow_canvas,  0, 0, 1, 1, 0, c_white, amount)
	if img == 7 draw_surface_ext(ao_canvas,    0, 0, 1, 1, 0, c_white, amount)
	if img == 8 draw_surface_ext(frizz_canvas, 0, 0, 1, 1, 0, c_white, amount)
	surface_reset_target()
	gpu_set_blendmode(bm_normal)

	// Write blurred result back to the active canvas
	if img == 0 surface_copy(canvas,       0, 0, blurSurface)
	if img == 1 surface_copy(nm_canvas,    0, 0, blurSurface)
	if img == 5 surface_copy(mask_canvas,  0, 0, blurSurface)
	if img == 4 surface_copy(color_canvas, 0, 0, blurSurface)
	if img == 2 surface_copy(id_canvas,    0, 0, blurSurface)
	if img == 3 surface_copy(depth_canvas, 0, 0, blurSurface)
	if img == 6 surface_copy(flow_canvas,  0, 0, blurSurface)
	if img == 7 surface_copy(ao_canvas,    0, 0, blurSurface)
	if img == 8 surface_copy(frizz_canvas, 0, 0, blurSurface)
}

#endregion


// ============================================================
// SURFACE DISPLAY (draw active canvas to screen)
// ============================================================
#region

// For the map selected by img, every branch below does the same three things:
//   1. draw the whole 4096 map at 0.25 scale onto the 1024 canvas (0,0);
//   2. draw a 512x512 piece of it at 1:1 in the zoom view at (Vxpos,Vypos) =
//      (1390,21), top right of the screen. xxx,yyy = top-left of that piece
//      in map pixels (the green box drawn later shows where it is);
//   3. if the map's GenState is 2, label it at the bottom of the canvas;
//      otherwise tint the canvas red (15% alpha) and put a warning in Tooltip.
// Tooltip is the large status text, drawn at the end of this region. It is a
// different thing from smallTip (the one-line helper tip).
// The branches are in img order (0-9), not screen order.
draw_set_halign(fa_left)
var Vxpos = 1390
var Vypos = 21

// tick drives the warning colour: 0-360 degrees in steps of 4 per frame.
tick += 4
if tick > 359.99 tick = 0

// During generation: show imgOverride canvas centered on current set
// (That line describes code that is no longer here: nothing below reads
// imgOverride. The braces that follow are just a plain block.)


{
	// Helper: flash colour for "not generated" warning
	// tt pulses 0..1; pcolor is black-to-orange. It is left as the draw colour
	// in each "not generated" branch, so the Tooltip text pulses - except
	// where a branch sets the colour back to white first (most of them do,
	// so in practice only the RGB Mask warning is drawn in pcolor).
	var tt     = abs(sin(degtorad(tick)))
	var pcolor = make_color_rgb(tt*255, tt*128, tt*32)

	// ---- RGB Mask ----
	if img == 0
	{
		
		// Surfaces can be lost (e.g. the window being minimised). Only this
		// branch recreates them; the other branches just skip drawing when
		// their surface is missing.
		if !surface_exists(canvas) resetSurfaces()
		draw_surface_ext(canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if rgbMask_GenState == 2
			{ draw_text(8, 1000, "Previewing RGB Mask  R=Variation  G=Root  B=Tip"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "RGB Mask - Not generated or settings changed. Enable and click Generate, or press P."
		}
	}

	// ---- Normal Map ----
	if img == 1 and surface_exists(nm_canvas)
	{
		// In multi-strand mode (moreHairs) the normal map is DISPLAYED through
		// shd_normal; the stored surface is not changed by this.
		if moreHairs == 1 shader_set(shd_normal)
		draw_surface_ext(nm_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(nm_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if moreHairs == 1 shader_reset()
		if norm_GenState == 2
			{ draw_text(8, 1000, "Previewing Normal Map"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Normal Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- ID Map ----
	if img == 2 and surface_exists(id_canvas)
	{
		draw_surface_ext(id_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(id_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if id_GenState == 2
		{
			if idMode == 0 draw_text(8, 1000, "Previewing ID Map - Strand Based")
			if idMode == 1 draw_text(8, 1000, "Previewing ID Map - Set Based")
			Tooltip = ""
		}
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "ID Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Depth Map ----
	if img == 3 and surface_exists(depth_canvas)
	{
		draw_surface_ext(depth_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(depth_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if depth_GenState == 2
			{ draw_text(8, 1000, "Previewing Depth Map"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Depth Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Color Map ----
	if img == 4 and surface_exists(color_canvas)
	{
		draw_surface_ext(color_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(color_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if color_GenState == 2
		{
			if ao_GenState != 2 draw_text(8, 1000, "Previewing Custom Color Map")
			if ao_GenState == 2 draw_text(8, 1000, "Previewing Custom Color Map  [J] to preview AO over this map")
			Tooltip = ""
		}
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Color Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Mask Map ----
	if img == 5 and surface_exists(mask_canvas)
	{
		draw_surface_ext(mask_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(mask_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if mask_GenState == 2
			{ draw_text(8, 1000, "Previewing Mask Map"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Mask Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Flow Map ----
	if img == 6 and surface_exists(flow_canvas)
	{
		draw_surface_ext(flow_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(flow_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if flow_GenState == 2
			{ draw_text(8, 1000, "Previewing Flow Map"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Flow Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- AO Map ----
	if img == 7 and surface_exists(ao_canvas)
	{
		draw_surface_ext(ao_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(ao_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if ao_GenState == 2
		{
			draw_set_color(c_white)
			if color_GenState != 2 draw_text(8, 1000, "Previewing AO Map")
			if color_GenState == 2 draw_text(8, 1000, "Previewing AO Map  [J] to preview over Colour Map")
			Tooltip = ""
		}
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "AO Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Frizz Map ----
	if img == 8 and surface_exists(frizz_canvas)
	{
		draw_surface_ext(frizz_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(frizz_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)
		if frizz_GenState == 2
			{ draw_set_color(c_white); draw_text(8, 1000, "Previewing Frizz Map"); Tooltip="" }
		else
		{
			draw_set_color(c_red); draw_set_alpha(0.15); draw_rectangle(0,0,1024,1023,0); draw_set_alpha(1); draw_set_color(pcolor)
			Tooltip = "Frizz Map - Not generated or settings changed. Enable and click Generate, or press P."
			draw_set_color(c_white)
		}
	}

	// ---- Previewer (strand preview) ----
	// Nothing is drawn on the canvas here: the strands were already drawn by
	// mainCalc(). The zoom view area shows a help picture instead.
	if img == 9
	{
		draw_set_color(c_orange)
		Tooltip = "Isolate strands by double-clicking their number below. Right-click to show all sets."
		draw_set_halign(fa_left)
		draw_sprite(spr_previewHelp, 0, 1390, 21)
		draw_set_color(c_white)
	}
}

// Tooltip and status text
draw_set_font(font_tipFont)
draw_set_valign(fa_top)
// V1.96 - every button and slider row now has a helper tip (uiTips).
// The tip has its own line along the bottom of the bar, under the buttons,
// where it gets the full width: it used to be wedged between the preview
// buttons and HELP INFO and had to wrap into three short lines.
// uiTips() only fills smallTip if nothing earlier in this event (or in the
// Step code) has already set it, and does nothing while the splash is up.
// Any control that wants its own tip must therefore set smallTip BEFORE here.
uiTips()
if smallTip != "" draw_text_ext(12, 1058, smallTip, -1, 1000)
draw_set_valign(fa_bottom)
// V1.96 - was (1050,950), which is now the Clump Var row, and squeezed above
// Seed it crowded the dice. It now sits in the clear space right of the
// Clumping / Clump Var boxes (below Copy/Paste, which ends at y 901), wrapped
// to 330px (two even lines, no orphan word) and bottom-aligned with Clump Var.
draw_text_ext(1395, 955, Tooltip, 15, 330)
draw_set_halign(fa_left)

#endregion


// ============================================================
// AO + COLOUR MAP MULTIPLIED PREVIEW (hold J)
// ============================================================
#region

// Display only - no surface is changed. While J is held, and only when both
// maps are generated, the colour map is drawn again over the canvas and zoom
// view and the AO map is drawn over it with a multiply blend
// (result = destination * source). Works whatever map img is showing.
// ORDER: must come after SURFACE DISPLAY, because it paints over it.
if ao_GenState == 2 and color_GenState == 2 and surface_exists(ao_canvas) and surface_exists(color_canvas)
{
	if keyboard_check_direct(ord("J"))
	{
		gpu_set_blendmode(bm_normal)
		draw_surface_ext(color_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(color_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)

		gpu_set_blendmode_ext(bm_dest_color, bm_zero) // multiply blend
		draw_surface_ext(ao_canvas, 0, 0, 0.25, 0.25, 0, c_white, 1)
		draw_surface_part_ext(ao_canvas, xxx, yyy, 512, 512, Vxpos, Vypos, 1, 1, c_white, 1)

		gpu_set_blendmode(bm_normal)
		draw_set_color(c_white)
		draw_text(8, 1000, "AO x Color (multiplied preview)  shortcut [J]"); Tooltip=""
	}
}

#endregion


// ============================================================
// VIEWER BOX OUTLINE (green box on mini-map)
// ============================================================
#region

if img != 9
{
	// Clamp viewer region to valid range
	// xxx,yyy are in 4096-map pixels and the window is 512 wide, so the
	// largest legal top-left is 4096-512. Dividing by 4 converts to canvas
	// pixels for the box (black outline 1px outside the green one).
	// NOTE: the clamp runs here, AFTER the zoom view was drawn above, so an
	// out-of-range xxx/yyy is corrected one frame late.
	if xxx < 0        xxx = 0
	if yyy < 0        yyy = 0
	if xxx > 4096-512 xxx = 4096-512
	if yyy > 4096-512 yyy = 4096-512

	draw_set_color(c_black)
	draw_rectangle(xxx/4-1, yyy/4-1, (xxx+512)/4+1, (yyy+512)/4+1, 1)
	draw_set_color(c_green)
	draw_rectangle(xxx/4,   yyy/4,   (xxx+512)/4,   (yyy+512)/4,   1)
	draw_set_color(c_white)
}

#endregion


// ============================================================
// UV OVERLAY + LOAD / SAVE ICONS
// ============================================================
#region

// UV preview (right-click UV button or hold U)
// Draws the UV reference image again, now ON TOP of the maps/strands, while
// U is held or the right button is held on the UV button (bottom bar,
// x 985-1017, y 1029-1059). Loading the image (left click on that button) is
// handled in doMainStep, not here.
if (mouse_x > 985 and mouse_x < 1017 and mouse_y > 1029 and mouse_y < 1059 and mouse_check_button(mb_right))
   or keyboard_check(ord("U"))
{
	if instance_exists(obj_UV_Image_Loader) and sprite_exists(obj_UV_Image_Loader.loadedSprite)
	{
		draw_sprite_part_ext(obj_UV_Image_Loader.loadedSprite, 0,
		                     0, 0, 1024/obj_UV_Image_Loader.sc, 1024/obj_UV_Image_Loader.sc,
		                     0, 0, obj_UV_Image_Loader.sc, obj_UV_Image_Loader.sc, c_white, obj_UV_Image_Loader.a)
	}
}

// Load button
// Icon centred at (1110,50) in the top bar, 36x36 hit area. A click fakes the
// L key, so loading itself is the L key event (KeyPress_76). canLoad is set
// true merely by hovering. `over` is the icon's highlight frame.
var over = 0
if mouse_x > 1110-18 and mouse_x < 1110+18 and mouse_y > 50-18 and mouse_y < 50+18
{
	over    = 1
	canLoad = true
	if mouse_check_button_pressed(mb_left)
	{
		projectOnly = false
		fileCustom  = ""
		keyboard_key_press(ord("L"))
		keyboard_key_release(ord("L"))
		loading       = false
		mouse_button  = mb_left
		projectOnly   = false
		canLoad       = true
	}
}
draw_sprite(spr_loadHSD, over, 1110, 50)

// Save button (project only)
// Icon centred at (1160,50). projectOnly = true, then a faked S key: the S key
// event saves the project file without exporting textures.
// In the demo build the icon is drawn faded with a "NO SAVE" label; the click
// test above it is NOT disabled here, so any demo restriction has to be
// enforced in the S key event.
over = 0
if mouse_x > 1160-18 and mouse_x < 1160+18 and mouse_y > 50-18 and mouse_y < 50+18
{
	over = 1
	if mouse_check_button_pressed(mb_left)
	{
		projectOnly = true
		keyboard_key_press(ord("S"))
	}
}
if demoMode == 0 draw_sprite(spr_saveHSD, over, 1160, 50)
if demoMode == 1
{
	draw_sprite_ext(spr_saveHSD, 0, 1160, 50, 1, 1, 0, c_white, 0.3)
	draw_set_halign(fa_middle); draw_set_valign(fa_middle)
	draw_text(1160, 50, "DEMO\nVERSION\nNO SAVE")
	draw_set_halign(fa_left);  draw_set_valign(fa_bottom)
}

#endregion


// ============================================================
// DIVIDING LINE + SIDE MAP MARKER
// ============================================================
#region

draw_set_color(c_red)
draw_line_width(1024, 0, 1024, 1080, 5) // vertical panel divider

// Marker arrow indicating which map is being viewed
// One fixed y per row of the map list, listed in SCREEN order (so the img
// numbers are out of sequence). The y values were placed by eye against
// spr_UI and are not an exact 27px step.
if img == 0 draw_sprite(spr_sideMarker, 0, 1036, 123)
if img == 1 draw_sprite(spr_sideMarker, 0, 1036, 150)
if img == 5 draw_sprite(spr_sideMarker, 0, 1036, 176)
if img == 4 draw_sprite(spr_sideMarker, 0, 1036, 200)
if img == 2 draw_sprite(spr_sideMarker, 0, 1036, 227)
if img == 3 draw_sprite(spr_sideMarker, 0, 1036, 253)
if img == 6 draw_sprite(spr_sideMarker, 0, 1036, 281)
if img == 7 draw_sprite(spr_sideMarker, 0, 1036, 305)
if img == 8 draw_sprite(spr_sideMarker, 0, 1036, 332)
if img == 9 draw_sprite(spr_sideMarker, 0, 1036, 359)

// checkAndOffset() (scripts/checkAndOffset) is the whole SET BUTTON row along
// the bottom of the panel and set positioning on the canvas:
//  - click a set number (80px apart from x=1082, y=1046) -> setSelectedID;
//    clicking the already-selected set solos it (setToSolo)
//  - right click anywhere -> deselect (setSelectedID = -1) and clear the ghost
//  - with a set selected: arrow keys nudge it (Ctrl = 1, Shift = 100,
//    default 20), and dragging on the canvas moves it (xOffset/yOffset)
// It runs this late in the event, so the slider blocks above see a new
// selection on the NEXT frame.
checkAndOffset()
draw_set_font(regFont)

#endregion


// ============================================================
// UI EXTRAS: OVERRIDE INDICATOR DOTS
// ============================================================
#region

// Small coloured dots that show which sets override which slider row.
// uiExtras is set to 1 in Create_0 (a switch to turn all of this off).
// For each set (scan = 0..10, the 11 sets that have buttons) up to two dots:
//  - a 2px dot on the slider row itself, left of the track, on the painted
//    dot for that set (see _dotX / _dotY below).
//    Reading along a row shows which sets override it.
//  - a 3px dot next to that set's number button at the bottom, forming a
//    small cluster per set (x 1100..1130 + 80*set, y 1039/1045/1051). Since
//    V1.97 every per-set override has one, including Wave Freq, the Mixers
//    and per-set colours (grid at the end of this block).
// Colours repeat between rows; the row position tells them apart.
// Rows with no row dot: Distance (row 3, global only), Wave Freq (row 5) and
// the three Mixer rows (14-16); those two still get a cluster dot.
// V1.97 - the row dots are drawn on the centres of the dots painted into
// spr_UI. Measured from a 2x screenshot: the painted dots are centred at
// x = 1121.25 + 7 per set and, per row, at the y in _dotY plus 0.7.
// draw_circle lands about 0.9px right and 0.7px below the point it is given,
// so the numbers below are the painted centres minus that (-1 = row has no
// dots). On a 2x display the result is within half a screen pixel (drawing
// snaps to whole screen pixels, so it cannot get closer). They used to sit
// 1px left, and the 1.91 / 1.96 rows (Thick Rng .. Noise, Clumping, Clump Var)
// about 1.5px low. If spr_UI is redrawn, measure again (a screenshot, then
// the centroid of the dark dots on each row).
var _dotY = [435.2, 463.2, 491.3, -1, 547.1, -1, 602.9, 630.8, 658.8, 686.5, 714.3, 742.1, 770.1, 798.1, -1, -1, -1, 910.1, 938.1];
if uiExtras == 1
{
	for (scan = 0; scan < 11; scan++)
	{
		var _dotX = 1120.35 + (scan * 7);
		// Strand count override (orange)
		draw_set_color(or_color)
		if setCountOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1039, 3, 0)
			draw_circle(_dotX, _dotY[0], 2, 0)
		}
		// Length override (blue)
		draw_set_color(blu_color)
		if setLengthOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1045, 3, 0)
			draw_circle(_dotX, _dotY[1], 2, 0)
		}
		// Spacing override (green)
		draw_set_color(grn_color)
		if setSpacingOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1051, 3, 0)
			draw_circle(_dotX, _dotY[2], 2, 0)
		}
		// Wavyness override (purple)
		draw_set_color(pur_color)
		if setWaveynessOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1039, 3, 0)
			draw_circle(_dotX, _dotY[4], 2, 0)
		}
		// Taper override (red)
		draw_set_color(red_color)
		if setTaperOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1045, 3, 0)
			draw_circle(_dotX, _dotY[6], 2, 0)
		}
		// Vari override (yellow)
		draw_set_color(yel_color)
		if setVariOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1051, 3, 0)
			draw_circle(_dotX, _dotY[7], 2, 0)
		}
		// Y range override (orange)
		draw_set_color(or_color)
		if strandYRanRangeOverrode[scan] != 0
		{
			draw_circle(1112+(scan*80), 1051, 3, 0)
			draw_circle(_dotX, _dotY[8], 2, 0)
		}

		// V1.91 - the remaining notched rows. Row y = 436 + (28*row).
		// Thick Rng row 9, Thick Adj row 10, Thick Var row 11,
		// Fading row 12, Noise row 13.
		draw_set_color(blu_color)
		if setThickMinOverrode[scan] != 0 or setThickMaxOverrode[scan] != 0
			draw_circle(_dotX, _dotY[9], 2, 0)

		draw_set_color(grn_color)
		if setRootThickOverrode[scan] != 0 or setTipThickOverrode[scan] != 0
			draw_circle(_dotX, _dotY[10], 2, 0)

		draw_set_color(pur_color)
		if setThickVaryOverrode[scan] != 0
			draw_circle(_dotX, _dotY[11], 2, 0)

		draw_set_color(yel_color)
		if setFadeInOverrode[scan] != 0 or setFadeOutOverrode[scan] != 0
			draw_circle(_dotX, _dotY[12], 2, 0)

		draw_set_color(red_color)
		if setNoiseAmtOverrode[scan] != 0 or setNoiseFreqOverrode[scan] != 0
			draw_circle(_dotX, _dotY[13], 2, 0)

		// V1.96 - Clumping row 17, Clump Var row 18
		draw_set_color(or_color)
		if setClumpAmtOverrode[scan] != 0 or setClumpCountOverrode[scan] != 0
			draw_circle(_dotX, _dotY[17], 2, 0)

		draw_set_color(blu_color)
		if setClumpStartOverrode[scan] != 0 or setClumpScatterOverrode[scan] != 0
			draw_circle(_dotX, _dotY[18], 2, 0)

		// V1.97 - the set-number cluster now covers every per-set override,
		// not just the first seven. Same colour as that row's dot where the
		// row has one. Cluster grid per set (x + 80*set, y 1039 / 1045 / 1051):
		//          1039         1045         1051
		//   1100   Strands      Length       Spacing      (above)
		//   1106   Waviness     Tapering     Variation    (above)
		//   1112   Wave Freq    Thick Rng    Root Jitter
		//   1118   Thick Adj    Thick Var    Fading
		//   1124   Noise        Clumping     Clump Var
		//   1130   Mixers       Colours
		// Wave Freq and the Mixers have no row dots, so they get their own
		// colours (pink, cyan). The colour dot is drawn in the set's own
		// overridden colour (Variation 1, else 2, else Root, else Tip).
		var _cx = scan * 80
		draw_set_color(make_color_rgb(255, 110, 180))
		if setWaveFreqMinOverrode[scan] != 0 or setWaveFreqMaxOverrode[scan] != 0
			draw_circle(1112+_cx, 1039, 3, 0)
		draw_set_color(blu_color)
		if setThickMinOverrode[scan] != 0 or setThickMaxOverrode[scan] != 0
			draw_circle(1112+_cx, 1045, 3, 0)
		draw_set_color(grn_color)
		if setRootThickOverrode[scan] != 0 or setTipThickOverrode[scan] != 0
			draw_circle(1118+_cx, 1039, 3, 0)
		draw_set_color(pur_color)
		if setThickVaryOverrode[scan] != 0
			draw_circle(1118+_cx, 1045, 3, 0)
		draw_set_color(yel_color)
		if setFadeInOverrode[scan] != 0 or setFadeOutOverrode[scan] != 0
			draw_circle(1118+_cx, 1051, 3, 0)
		draw_set_color(red_color)
		if setNoiseAmtOverrode[scan] != 0 or setNoiseFreqOverrode[scan] != 0
			draw_circle(1124+_cx, 1039, 3, 0)
		draw_set_color(or_color)
		if setClumpAmtOverrode[scan] != 0 or setClumpCountOverrode[scan] != 0
			draw_circle(1124+_cx, 1045, 3, 0)
		draw_set_color(blu_color)
		if setClumpStartOverrode[scan] != 0 or setClumpScatterOverrode[scan] != 0
			draw_circle(1124+_cx, 1051, 3, 0)
		draw_set_color(make_color_rgb(0, 200, 255))
		if setMixerAmt1Overrode[scan] != 0 or setMixerOfs1Overrode[scan] != 0
		or setMixerAmt2Overrode[scan] != 0 or setMixerOfs2Overrode[scan] != 0
		or setMixerAmt3Overrode[scan] != 0 or setMixerOfs3Overrode[scan] != 0
			draw_circle(1130+_cx, 1039, 3, 0)
		var _colDot = -1
		if !variable_instance_exists(id, "setColourOverridesReady") {}   // colour arrays not made yet (Step_0)
		else if setColVarAOverrode[scan] == 1 _colDot = setColVarA[scan]
		else if setColVarBOverrode[scan] == 1 _colDot = setColVarB[scan]
		else if setRootColOverrode[scan] == 1 _colDot = setRootCol[scan]
		else if setTipColOverrode[scan] == 1 _colDot = setTipCol[scan]
		if _colDot != -1
		{
			draw_set_color(c_black)                // ring, so dark colours still show
			draw_circle(1130+_cx, 1045, 4, 0)
			draw_set_color(_colDot)
			draw_circle(1130+_cx, 1045, 3, 0)
		}
	}
}

draw_set_color(c_white)

#endregion


// ============================================================
// MISC UI: FILENAME, STRAND TYPE, COLOUR HIGHLIGHTS, SEED
// ============================================================
#region

// Last loaded filename
// Drawn at (1210,70), inside the Generate button's rectangle.
draw_set_font(smallFont)
draw_text(1210, 70, lastFileName)
draw_set_font(regFont)

// Multi-strand / curl type toggle button
// Bottom bar, x 266-330. moreHairs: 0 = single strand, 1 = multi strand.
// Changes the strands themselves, so it sets pleaseGen.
if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x, mouse_y, 266, 1030, 330, 1050)
{
	moreHairs = 1 - moreHairs
	pleaseGen = true
}
draw_sprite(spr_but_StrandType, moreHairs, 266, 1028)

// V1.96 - preview update mode toggle: LIVE (strands grow in) / BUSY (classic)
// and the smoothing shader toggle. Their helper tips are in uiTips().
// Bottom bar: preview mode x 352-421 (pvMode), smoothing x 428-497 (pvSmooth).
// These are display preferences, not project settings: they do not set
// pleaseGen, and they are written straight to HSD_Settings.ini (section
// "preview") so they survive a restart.
if mouse_check_button_pressed(mb_left) and mouse_y >= 1027 and mouse_y <= 1051
{
	var _prefChanged = false
	if mouse_x >= 352 and mouse_x <= 421 { pvMode = 1 - pvMode; _prefChanged = true }
	if mouse_x >= 428 and mouse_x <= 497 { pvSmooth = 1 - pvSmooth; _prefChanged = true }
	if _prefChanged
	{
		ini_open("HSD_Settings.ini")
		ini_write_real("preview", "updateMode", pvMode)
		ini_write_real("preview", "smooth", pvSmooth)
		ini_close()
	}
}
draw_sprite(spr_but_PreviewMode, pvMode, 356, 1028)
draw_sprite(spr_but_Smooth, pvSmooth, 432, 1028)

// Curl rotation control (visible only in multi-strand mode)
// A tiny vertical slider just right of the strand-type button: a 7px wide
// strip at x 333-340, y 1028-1051, with a dot as its handle.
// curlRotAmt is 0..1: 0 at the bottom (y 1050), 1 at the top (22px higher).
// There is no drag latch: it only responds while the mouse is inside the strip.
if moreHairs == 1
{
	draw_circle(336, 1050-(curlRotAmt*22), 3, 0)
	if mouse_x > 333 and mouse_x < 340 and mouse_y > 1028 and mouse_y < 1051
	{
		if mouse_check_button(mb_left)
		{
			curlRotAmt = clamp((1050 - mouse_y) / 22, 0, 1)
			pleaseGen  = true
		}
	}
}

// Active colour slot highlight sprites
// A frame around whichever swatch is the active slot (the flags mainCalc()
// restored from colourSelectedSlot earlier in this event).
if bkCol_active   == 1 draw_sprite(spr_colHL, 0, 1566, 540)
if ColA_active    == 1 draw_sprite(spr_colHL, 0, 1566, 567)
if ColB_active    == 1 draw_sprite(spr_colHL, 0, 1566, 594)
if RootCol_active == 1 draw_sprite(spr_colHL, 0, 1566, 620)
if TipCol_active  == 1 draw_sprite(spr_colHL, 0, 1566, 647)

// Seed value display
// At (1214,1006), beside the dice. Shows the selected set's own seed (in the
// override colour if that set has one) or the global seedVal. Read-only here.
draw_set_color(tbCol)
if setSelectedID != -1 and randomOverride[setSelectedID] != 0 draw_set_color(tbColOver)
draw_set_font(regFont)
if setSelectedID != -1 draw_text(1214, 1006, string(randomSeedVal[setSelectedID]))
else                    draw_text(1214, 1006, string(seedVal))
draw_set_color(c_white)

#endregion


// ============================================================
// HELP PANEL TOGGLE
// ============================================================
#region

// HELP INFO button: bottom bar, x 846-901. Toggles showHelp. The panel is
// drawn from (0,0), over the canvas, and because it is drawn this late it
// covers everything drawn before it. It does not block input: controls
// underneath still respond to clicks.
if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x, mouse_y, 846, 1027, 901, 1051)
	showHelp = 1 - showHelp

// V1.96 - the panel was remade for 1.96 at double size (2042x2048) and is drawn
// at half scale, so its text stays sharp on high-resolution displays.
if showHelp == 1 draw_sprite_ext(spr_HelpPanel, 0, 0, 0, 0.5, 0.5, 0, c_white, 1)

#endregion


// ============================================================
// STARTUP SPLASH SCREEN
// Dark overlay + a centred card carrying the title, the version, the
// "new in" line and two buttons. LOAD AUTOSAVE only appears when an
// Autosave.txt is actually present, and pulses so it is noticed.
// This replaces the old show_question() popup in doMainStep.
// ============================================================
#region

// Shown while firstTime is true (from launch until a button here, or a
// Generate, clears it). Create_0 skips it when RegenCheck.txt exists at
// launch: it sets firstTime = false, and skipIntro = 1 if the file says "Regen".
// The splash only DRAWS over the UI; it does not stop the code above from
// running, so everything under it is still live (see the card note below).
// Both buttons and Enter set the same three things:
//   firstTime = false            closes the splash
//   readyToCheckAutoloads = 1    read by doMainStep / Step_1 (autosave and autoload gating)
//   dynamicRes = 1               read in Step_1
// and differ only in autoloading (1 = load Autosave.txt, 0 = start fresh).
if firstTime and skipIntro == 0
{
	// ---- one-off autosave probe (splashAutosaveFound starts at -1) ----
	if splashAutosaveFound == -1
	{
		splashAutosaveFound = 0
		var _splashFile = file_text_open_read("Autosave.txt")
		if _splashFile != -1
		{
			splashAutosaveFound = 1
			file_text_close(_splashFile)
		}
	}

	// ---- palette ----
	var _dim     = make_color_rgb(10, 10, 12)
	var _card    = make_color_rgb(26, 26, 30)
	var _edge    = make_color_rgb(70, 70, 78)
	var _accent  = make_color_rgb(90, 200, 130)
	var _muted   = make_color_rgb(140, 140, 148)

	// ---- full screen dim ----
	draw_set_color(_dim)
	draw_set_alpha(0.94)
	draw_rectangle(0, 0, 1920, 1080, 0)
	draw_set_alpha(1)

	// ---- card ----
	// The card is deliberately kept left of x=1190. Draw_0 has already run every
	// slider hit-test by the time the splash draws, so a click landing on the
	// slider column (x 1198-1308) would still nudge a slider underneath.
	var _cx = 845
	var _cl = 500
	var _cr = 1190
	var _ct = 320
	var _cb = 700

	draw_set_color(_card)
	draw_rectangle(_cl, _ct, _cr, _cb, 0)
	draw_set_color(_edge)
	draw_rectangle(_cl, _ct, _cr, _cb, 1)

	// accent rule across the top of the card
	draw_set_color(_accent)
	draw_rectangle(_cl, _ct, _cr, _ct + 3, 0)

	// ---- title ----
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)
	// V1.96 - a proper logo graphic (spr_logoTitle, Orbitron). It replaces the
	// 15pt bigFont stretched 2.4x, which was visibly soft. The sprite is authored
	// at 2x (1240x176) and drawn at half size, so it stays sharp on 4K displays.
	draw_sprite_ext(spr_logoTitle, 0, _cx, _ct + 72, 0.5, 0.5, 0, c_white, 1)

	draw_set_font(regFont)
	draw_set_color(_muted)
	draw_text(_cx, _ct + 128, "v" + string(versionHSD))

	// ---- what is new ----
	draw_set_color(_accent)
	draw_text(_cx, _ct + 158, "New in 1.97  -  Claude / MCP control (Ctrl+Shift+F10), back-to-preview on slider moves, full override dots")

	if demoMode == 1
	{
		draw_set_color(make_color_rgb(220, 170, 60))
		draw_text(_cx, _ct + 186, demoInfo)
	}

	// ---- divider ----
	draw_set_color(_edge)
	draw_line(_cl + 60, _ct + 210, _cr - 60, _ct + 210)

	// ---- buttons ----
	// Each button is 240x54. With an autosave present there are two, either
	// side of the card centre (_cx); otherwise GET STARTED sits alone, centred.
	// _loadL/_loadR and _startL/_startR are the left/right edges used for both
	// drawing and the hit tests.
	var _bw = 240
	var _bh = 54
	var _by = _ct + 258
	var _loadL = 0
	var _loadR = 0
	var _startL = 0
	var _startR = 0

	if splashAutosaveFound == 1
	{
		_loadL  = _cx - 260
		_loadR  = _loadL + _bw
		_startL = _cx + 20
		_startR = _startL + _bw
	}
	else
	{
		_startL = _cx - (_bw / 2)
		_startR = _startL + _bw
	}

	// LOAD AUTOSAVE - only when a file was found, and it pulses
	if splashAutosaveFound == 1
	{
		// gameTick360 counts 0..360 once per step (Step_1), so this pulses
		// 0..1 about every 45 frames. The fill colour is a dark-to-bright
		// green ramp; hovering uses a brighter ramp.
		var _pulse = abs(dsin(gameTick360 * 4))
		var _hovL  = point_in_rectangle(mouse_x, mouse_y, _loadL, _by, _loadR, _by + _bh)

		var _fillR = 20 + (_pulse * 40)
		var _fillG = 60 + (_pulse * 110)
		var _fillB = 34 + (_pulse * 60)
		if _hovL
		{
			_fillR = 40 + (_pulse * 50)
			_fillG = 120 + (_pulse * 120)
			_fillB = 70 + (_pulse * 70)
		}

		draw_set_color(make_color_rgb(_fillR, _fillG, _fillB))
		draw_rectangle(_loadL, _by, _loadR, _by + _bh, 0)
		draw_set_color(_accent)
		draw_rectangle(_loadL, _by, _loadR, _by + _bh, 1)
		draw_rectangle(_loadL - 1, _by - 1, _loadR + 1, _by + _bh + 1, 1)

		draw_set_color(c_white)
		draw_set_font(bigFont)
		draw_text(_loadL + (_bw / 2), _by + (_bh / 2), "LOAD AUTOSAVE")
		draw_set_font(regFont)

		if _hovL and mouse_check_button_pressed(mb_left)
		{
			dynamicRes            = 1
			firstTime             = false
			readyToCheckAutoloads = 1
			autoloading           = 1   // doMainStep performs the load, no popup
		}
	}

	// GET STARTED
	var _hovS = point_in_rectangle(mouse_x, mouse_y, _startL, _by, _startR, _by + _bh)

	draw_set_color(make_color_rgb(44, 44, 50))
	if _hovS draw_set_color(make_color_rgb(64, 64, 72))
	draw_rectangle(_startL, _by, _startR, _by + _bh, 0)
	draw_set_color(_edge)
	if _hovS draw_set_color(c_white)
	draw_rectangle(_startL, _by, _startR, _by + _bh, 1)

	draw_set_color(c_white)
	draw_set_font(bigFont)
	draw_text(_startL + (_bw / 2), _by + (_bh / 2), "GET STARTED")
	draw_set_font(regFont)

	if _hovS and mouse_check_button_pressed(mb_left)
	{
		dynamicRes            = 1
		firstTime             = false
		readyToCheckAutoloads = 1
		autoloading           = 0   // start fresh, leave Autosave.txt untouched
	}

	// Enter always means GET STARTED.
	if keyboard_check_pressed(vk_enter)
	{
		dynamicRes            = 1
		firstTime             = false
		readyToCheckAutoloads = 1
		autoloading           = 0
	}

	// ---- footnotes ----
	draw_set_color(_muted)
	if splashAutosaveFound == 1
	{
		draw_text(_cx, _by + _bh + 34,
			"Previous session found - GET STARTED leaves it untouched.")
	}
	else
	{
		draw_text(_cx, _by + _bh + 34, "No previous session found.")
	}

	draw_text(_cx, _cb + 40, "Please avoid exporting textures to the same folder as the application")

	draw_set_color(c_white)
	draw_set_halign(fa_left)
	draw_set_valign(fa_bottom)
}

#endregion


// ============================================================
// RUNTIME INFO BAR + KEYBOARD SHORTCUTS LEGEND
// ============================================================
// (Empty: there is no code under this heading any more.)



// ============================================================
// HEART ICON (Easter egg)
// ============================================================
#region

// showHeart is toggled by the F7 key event (KeyPress_118). The heart is drawn
// at half size at (1000,1000), bottom right of the canvas. Saturation is 0, so
// the "colour" is a grey whose brightness pulses with gameTick360: it is used
// as the sprite's blend colour, making the heart beat between dark and full.
// The beat is 4x slower when a map is being viewed than in previewer mode.
if showHeart == 1
{
	var beatMul = (img != 9) ? 0.25 : 1
	var hColour = make_color_hsv(1, 0, abs(dsin(gameTick360 * 10 * beatMul)) * 255)
	draw_sprite_ext(s_heart, 0, 1000, 1000, 0.5, 0.5, 0, hColour, 1)
}
draw_set_color(c_white)

#endregion


// ============================================================
// DRAG WINDOW BAR (top 10px strip)
// ============================================================
#region

// Visual hint only: when the mouse is in the top 10 pixels a grey strip and
// the words DRAG WINDOW are drawn. The actual window dragging is not done in
// this event.
if mouse_y < 10
{
	draw_rectangle_color(0, 0, room_width, 10, c_dkgray, c_dkgray, c_ltgray, c_ltgray, 0)
	draw_set_color(c_ltgray)
	draw_line(0, 0, room_width, 0)
	draw_line(0, 10, room_width, 10)
	draw_set_font(smallFont)
	draw_set_color(c_black)
	draw_text(0, 11, "DRAG WINDOW")
}

#endregion


// ============================================================
// EXIT CONFIRMATION DIALOG
// ============================================================
#region

// exiting is set true by User Event 0 (the quit button in the top bar).
// A small box is drawn on the canvas at (330,480)-(640,520). Y or a click on
// the "Y" in the text quits; N, a click on the "N", or any right click
// cancels. The two click rectangles (x 570-605 quits, x 613-635 cancels) are
// fixed numbers at the right-hand end of the box, where the "Y / N" of the
// drawn string falls, so they depend on the font and wording of that string.
if exiting
{
	draw_rectangle_color(330, 480, 640, 520, c_dkgray, c_dkgray, c_black, c_black, 0)
	draw_rectangle_color(330, 480, 640, 520, c_gray, c_gray, c_white, c_white, 1)
	draw_text(340, 510, "Are you sure you want to quit?  Y / N")
	if keyboard_check_pressed(ord("Y")) game_end()
	if keyboard_check_pressed(ord("N")) exiting = false
	if mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, 570, 480, 605, 516) game_end()
	if mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, 613, 480, 635, 516) exiting = false
	if mouse_check_button_pressed(mb_right) exiting = false
}

#endregion


// ============================================================
// FRAME CLEANUP
// ============================================================

// Reset firstCalc flag at end of frame (used to gate heavy work)
firstCalc = 0

// Reset textboxes if Enter pressed
// This is what closes a slider number box after Enter. It must stay at the
// END of the event: each open box has to see the Enter press first (to set
// forceUpdate) before the box is closed here.
if keyboard_check_pressed(vk_enter)
{
	dynamicRes = 1
	reset_textBoxes()
}
