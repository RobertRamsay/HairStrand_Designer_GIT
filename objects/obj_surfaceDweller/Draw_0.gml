/// @description PREVIEW STRANDS - Draw Event
// Main draw event for the Hair Strand Designer preview/control panel.
// Handles: UI drawing, map toggle buttons, slider controls, colour pickers,
//          blur pass, surface display, and all mouse/keyboard interactions.

debugMsg = "Preview Strands"

// ============================================================
// UI BASE + PALETTE IMAGE
// ============================================================
#region

draw_sprite(spr_UI, 0, 0, 0) // draw base UI

// Draw custom palette image if one is loaded
if newPalImg != -1
{
	var piw = 254 / sprite_get_width(newPalImg)
	var pih = 180 / sprite_get_height(newPalImg)
	draw_sprite_ext(newPalImg, 0, 1645, 542, piw, pih, 0, c_white, 1)
}

// Import palette button - dim when not hovered
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
	if mouse_check_button_pressed(mb_right) { newPalImg=-1; sprite_flush(newPalImg); sprite_delete(newPalImg) }
}

generating = false

#endregion


// ============================================================
// GENERATE SHORTCUT (G KEY)
// ============================================================
#region

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

var vSpace  = 26
var placeY  = 107

// Draw gen-state indicators for each map channel
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
draw_set_color(colrBack)
if img == 9 draw_rectangle(0, 0, 1023, 1023, 0)

// Draw UV reference image if loaded
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

if mouse_check_button(mb_left) firstCalc = 1

if mouse_check_button_pressed(mb_left)
{
	// --- Enable / disable column (x: 1241–1270) ---
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
	exportIndividual()

	// --- Generate button (main) ---
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

if sprite_exists(ghostSprite) and !mouse_check_button(mb_right)
	draw_sprite_part_ext(ghostSprite, 0, 0, 0, 1024, 1024, 0, 0, 1, 1, c_white, 0.4)

mainCalc() // === MAIN STRAND CALCULATION ===

draw_set_color(c_white)
if pleaseGen draw_sprite(spr_genMessage, 0, 512, 32)

#endregion


// ============================================================
// RANDOMISATION DICE BUTTON
// ============================================================
#region

if point_in_rectangle(mouse_x, mouse_y, 1056, 980, 1086, 1010)
{
	smallTip = "Click the dice to randomize the strand seed number\nRight click to randomise all non-overridden sets"

	

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
			if randomOverride[s] == 1 seedVal = randomSeedVal[setSelectedID]
			randomOverride[setSelectedID]    = 1
			randomSeedVal[setSelectedID]     = seedVal + 1
		}
		else
		{
			// Affect all non-overridden sets
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


// ============================================================
// SLIDER: STRAND COUNT
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436
var sly  = ey
var slx  = ex + strands
if setSelectedID != -1 slx = ex + strandCountOverride[setSelectedID]

// Activate slider on press within range
if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_strands = true }
	}
}

// Drag slider
if mouse_check_button(mb_left) && slider_interract_strands
{
	over = 1
	slx  = clamp(mouse_x, ex, ex+100)
	reset_textBoxes()
	pleaseGen = true

	if setSelectedID != -1
	{
		strandCountOverride[setSelectedID] = clamp(slx-ex, 0, 100)
		setCountOverrode[setSelectedID]    = 1
	}
	else
	{
		strands = clamp(slx-ex, 0, 100)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setCountOverrode[setChange] != 1 strandCountOverride[setChange] = strands
		}
	}
}

// Draw notch and value
draw_set_color(c_gray)
if (setSelectedID != -1 && setCountOverrode[setSelectedID] != 0) draw_set_color(or_color)
draw_set_valign(fa_bottom)
draw_set_halign(fa_left)
if setSelectedID == -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strands), sly);                                draw_text(1318, ey+11, string(strands)) }
if setSelectedID != -1 { draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+strandCountOverride[setSelectedID]), sly);    draw_text(1318, ey+11, string(strandCountOverride[setSelectedID])) }
draw_set_color(c_white)

// Textbox click
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom)
	draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(strands))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandCountOverride[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(textBox_strands_value)), ey-9, 1320+string_width(string(strands)), ey+7, 2)
	draw_set_color(c_white)

	// Numpad input
	#region
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

	// Regular keyboard input
	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		if str == "" str = "0"
		if keyboard_lastkey == 8 // backspace
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_strands_value = str

	// Clamp and apply
	if real(textBox_strands_value) > 100 { textBox_strands_value="100"; str="100" }
	if setSelectedID != -1
	{
		strandCountOverride[setSelectedID] = clamp(real(textBox_strands_value), 0, 100)
		setCountOverrode[setSelectedID]    = 1
	}
	else
	{
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setCountOverrode[setChange] != 1 strandCountOverride[setChange] = strands
		}
	}

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
var ey   = 436 + (28*2)
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setSpacingOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(distancings))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetSpaceAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(distancings)), ey-9, 1320+string_width(string(distancings)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		distancings = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_distancings_value = str

	if real(textBox_distancings_value) > 100 { textBox_distancings_value="100"; str="100" }
	distancings = clamp(real(textBox_distancings_value), 0, 100)
	if setSelectedID != -1
	{
		strandSetSpaceAdj[setSelectedID]  = distancings
		setSpacingOverrode[setSelectedID] = 1
	}
	else
	{
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
var ey   = 436 + (28*3)
var sly  = ey
var slx  = ex + setDistance

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
	setDistance = clamp(slx-ex, 0, 100)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+100), sly)
draw_set_color(c_gray)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318, ey+11, string(setDistance))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(setDistance)), ey-9, 1320+string_width(string(setDistance)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		setDistance = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_setDistance_value = str

	if real(textBox_setDistance_value) > 100 { textBox_setDistance_value="100"; str="100" }
	setDistance = clamp(real(textBox_setDistance_value), 0, 100)

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
var ey   = 436 + (28*4)
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setWaveynessOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(wavyness))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetWavynessAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(wavyness)), ey-9, 1320+string_width(string(wavyness)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		wavyness = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_wavyness_value = str

	if real(textBox_wavyness_value) > 100 { textBox_wavyness_value="100"; str="100" }
	wavyness = clamp(real(textBox_wavyness_value), 0, 100)
	if setSelectedID != -1
	{
		strandSetWavynessAdj[setSelectedID]  = wavyness
		setWaveynessOverrode[setSelectedID]  = 1
	}
	else
	{
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

// ---- Min Freq (left half) ----
#region

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
		strandSetWaveFreqMinAdj[setSelectedID]  = clamp(slx-ex, 0, 40)
		setWaveFreqMinOverrode[setSelectedID]   = 1
	}
	else
	{
		minFreq = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMinOverrode[setChange] != 1 strandSetWaveFreqMinAdj[setChange] = minFreq
		}
	}
}

draw_set_color(c_gray)
if (setSelectedID != -1 && setWaveFreqMinOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(minFreq))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetWaveFreqMinAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(minFreq)), ey-9, 1320+string_width(string(minFreq)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		minFreq = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_minFreq_value = str

	if real(textBox_minFreq_value) > 40 { textBox_minFreq_value="40"; str="40" }
	minFreq = clamp(real(textBox_minFreq_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetWaveFreqMinAdj[setSelectedID]  = minFreq
		setWaveFreqMinOverrode[setSelectedID]   = 1
	}
	else
	{
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMinOverrode[setChange] != 1 strandSetWaveFreqMinAdj[setChange] = minFreq
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FREQ MIN

// ---- Max Freq (right half) ----
#region

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
		strandSetWaveFreqMaxAdj[setSelectedID]  = clamp(slx-ex, 0, 40)
		setWaveFreqMaxOverrode[setSelectedID]   = 1
	}
	else
	{
		maxFreq = clamp(slx-ex, 0, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMaxOverrode[setChange] != 1 strandSetWaveFreqMaxAdj[setChange] = maxFreq
		}
	}
	draw_set_color(c_white)
}

draw_set_color(c_gray)
if (setSelectedID != -1 && setWaveFreqMaxOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
		if setSelectedID == -1 { str = string(maxFreq);                                  textBox_mixer1_value  = string(maxFreq) }
		if setSelectedID != -1 { str = string(strandSetWaveFreqMaxAdj[setSelectedID]);   textBox_maxFreq_value = string(strandSetWaveFreqMaxAdj[setSelectedID]) }
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_maxFreq = 0 }

if textBox_maxFreq == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318+34, ey+11, string(maxFreq))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318+34, ey+11, string(strandSetWaveFreqMaxAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(maxFreq)), ey-9, 1320+34+string_width(string(maxFreq)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		maxFreq = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_maxFreq_value = str

	if real(textBox_maxFreq_value) > 40 { textBox_maxFreq_value="40"; str="40" }
	maxFreq = clamp(real(textBox_maxFreq_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetWaveFreqMaxAdj[setSelectedID] = maxFreq
		// note: setWaveFreqMaxOverrode intentionally not set here (legacy behaviour)
	}
	else
	{
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setWaveFreqMaxOverrode[setChange] != 1 strandSetWaveFreqMaxAdj[setChange] = maxFreq
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
var ey   = 436 + (28*6)
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setTaperOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(tapering))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetTaperAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(tapering)), ey-9, 1320+string_width(string(tapering)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		tapering = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_tapering_value = str

	if real(textBox_tapering_value) > 100 { textBox_tapering_value="100"; str="100" }
	tapering = clamp(real(textBox_tapering_value), 0, 100)
	if setSelectedID != -1
	{
		strandSetTaperAdj[setSelectedID] = tapering
		setTaperOverrode[setSelectedID]  = 1
	}
	else
	{
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
var ey   = 436 + (28*7)
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setVariOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(lifeVariant))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetVariAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(str)), ey-9, 1320+string_width(string(str)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		lifeVariant = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "1"
		}
		keyboard_lastkey = -1
	}
	textBox_lifeVariant_value = str

	if real(textBox_lifeVariant_value) > 100 { textBox_lifeVariant_value="100"; str="100" }
	lifeVariant = clamp(real(textBox_lifeVariant_value), 1, 100)
	if setSelectedID != -1
	{
		strandSetVariAdj[setSelectedID] = lifeVariant
		setVariOverrode[setSelectedID]  = 1
	}
	else
	{
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
var ey   = 436 + (28*8)
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

draw_set_color(c_gray)
if (setSelectedID != -1 && strandYRanRangeOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(yRanRange))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandYRanRange[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(str)), ey-9, 1320+string_width(string(str)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		yRanRange = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "1"
		}
		keyboard_lastkey = -1
	}
	textBox_YRanRange_value = str

	if real(textBox_YRanRange_value) > 100 { textBox_YRanRange_value="100"; str="100" }
	yRanRange = clamp(real(textBox_YRanRange_value), 1, 100)
	if setSelectedID != -1
	{
		strandYRanRange[setSelectedID]         = yRanRange
		strandYRanRangeOverrode[setSelectedID] = 1
	}
	else
	{
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

	if setSelectedID != -1
	{
		setThickMinAdj[setSelectedID]      = clamp(slx-ex, 1, 40)
		setThickMinOverrode[setSelectedID] = 1
	}
	else
	{
		minScale = clamp(slx-ex, 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMinOverrode[setChange] != 1 setThickMinAdj[setChange] = minScale
		}
	}
}

draw_set_color(c_gray)
if (setSelectedID != -1 && setThickMinOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(minScale))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(setThickMinAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(minScale)), ey-9, 1320+string_width(string(minScale)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		minScale = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_minScale_value = str

	if real(textBox_minScale_value) > 40 { textBox_minScale_value="40"; str="40" }
	minScale = clamp(real(textBox_minScale_value), 0, 40)
	if setSelectedID != -1
	{
		setThickMinAdj[setSelectedID]      = real(str)
		setThickMinOverrode[setSelectedID] = 1
	}
	else
	{
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMinOverrode[setChange] != 1 setThickMinAdj[setChange] = real(str)
			else minScale = clamp(real(textBox_minScale_value), 0, 40)
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

	if setSelectedID != -1
	{
		setThickMaxAdj[setSelectedID]      = clamp(slx-ex, 1, 40)
		setThickMaxOverrode[setSelectedID] = 1
	}
	else
	{
		maxScale = clamp(slx-ex, 1, 40)
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMaxOverrode[setChange] != 1 setThickMaxAdj[setChange] = maxScale
		}
	}
}

draw_set_color(c_gray)
if (setSelectedID != -1 && setThickMaxOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318+34, ey+11, string(maxScale))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318+34, ey+11, string(setThickMaxAdj[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(maxScale)), ey-9, 1320+34+string_width(string(maxScale)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		maxScale = real(str)
		if maxScale < 1 { maxScale=1; str=1 }
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_maxScale_value = str

	if real(textBox_maxScale_value) > 40 { textBox_maxScale_value="40"; str="40" }
	maxScale = clamp(real(textBox_maxScale_value), 0, 40)
	if setSelectedID != -1
	{
		setThickMaxAdj[setSelectedID]      = real(str)
		setThickMaxOverrode[setSelectedID] = 1
	}
	else
	{
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setThickMaxOverrode[setChange] != 1 setThickMaxAdj[setChange] = real(str)
			else maxScale = clamp(real(textBox_maxScale_value), 0, 40)
		}
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: THICKNESS MAX


// ============================================================
// DUAL SLIDERS: TIP THICK + ROOT THICK (root/tip thickness range)
// ============================================================

// ---- Tip Thick (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*10)
var sly  = ey
var slx  = ex + tipThick

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_tipThick = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_tipThick
{
	over     = 1
	slx      = clamp(mouse_x, ex, ex+40); pleaseGen = true
	tipThick = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318, ey+11, string(tipThick))
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                    = string(tipThick)
		textBox_tipThick       = 1
		textBox_tipThick_value = string(tipThick)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_tipThick = 0 }

if textBox_tipThick == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318, ey+11, string(tipThick))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(tipThick)), ey-9, 1320+string_width(string(tipThick)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		tipThick = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_tipThick_value = str

	if real(textBox_tipThick_value) > 40 { textBox_tipThick_value="40"; str="40" }
	tipThick = clamp(real(textBox_tipThick_value), 0, 40)

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

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_rootThick = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_rootThick
{
	over      = 1
	slx       = clamp(mouse_x, ex, ex+40); pleaseGen = true
	rootThick = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318+34, ey+11, string(rootThick))
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                     = string(rootThick)
		textBox_rootThick       = 1
		textBox_rootThick_value = string(rootThick)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_rootThick = 0 }

if textBox_rootThick == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318+34, ey+11, string(rootThick))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(rootThick)), ey-9, 1320+34+string_width(string(rootThick)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		rootThick = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_rootThick_value = str

	if real(textBox_rootThick_value) > 40 { textBox_rootThick_value="40"; str="40" }
	rootThick = clamp(real(textBox_rootThick_value), 0, 40)

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: ROOT THICK


// ============================================================
// SLIDER: THICK VARY (thickness variance)
// ============================================================
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*11)
var sly  = ey
var slx  = ex + thickVary

if mouse_x >= ex and mouse_x <= ex+100
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_thickVary = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_thickVary
{
	over      = 1
	slx       = clamp(mouse_x, ex, ex+100); pleaseGen = true
	thickVary = clamp(slx-ex, 0, 100)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+100), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318, ey+11, string(thickVary))
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                    = string(thickVary)
		textBox_thickVary      = 1
		textBox_thickVary_value = string(thickVary)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_thickVary = 0 }

if textBox_thickVary == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318, ey+11, string(thickVary))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(thickVary)), ey-9, 1320+string_width(string(thickVary)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		thickVary = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_thickVary_value = str

	if real(textBox_thickVary_value) > 100 { textBox_thickVary_value="100"; str="100" }
	thickVary = clamp(real(textBox_thickVary_value), 0, 100)

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: THICK VARY


// ============================================================
// DUAL SLIDERS: FADE IN + FADE OUT
// ============================================================

// ---- Fade In (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*12)
var sly  = ey
var slx  = ex + fadeIn

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_fadeIn = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_fadeIn
{
	over   = 1
	slx    = clamp(mouse_x, ex, ex+40); pleaseGen = true
	fadeIn = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318, ey+11, string(fadeIn))
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                  = string(fadeIn)
		textBox_fadeIn       = 1
		textBox_fadeIn_value = string(fadeIn)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_fadeIn = 0 }

if textBox_fadeIn == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318, ey+11, string(fadeIn))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(fadeIn)), ey-9, 1320+string_width(string(fadeIn)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		fadeIn = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_fadeIn_value = str

	if real(textBox_fadeIn_value) > 40 { textBox_fadeIn_value="40"; str="40" }
	fadeIn = clamp(real(textBox_fadeIn_value), 0, 40)

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

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_fadeOut = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_fadeOut
{
	over    = 1
	slx     = clamp(mouse_x, ex, ex+40); pleaseGen = true
	fadeOut = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318+34, ey+11, string(fadeOut))
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                   = string(fadeOut)
		textBox_fadeOut       = 1
		textBox_fadeOut_value = string(fadeOut)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_fadeOut = 0 }

if textBox_fadeOut == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318+34, ey+11, string(fadeOut))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(fadeOut)), ey-9, 1320+34+string_width(string(fadeOut)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		fadeOut = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_fadeOut_value = str

	if real(textBox_fadeOut_value) > 40 { textBox_fadeOut_value="40"; str="40" }
	fadeOut = clamp(real(textBox_fadeOut_value), 0, 40)

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: FADE OUT


// ============================================================
// DUAL SLIDERS: NOISE AMOUNT + NOISE FREQUENCY  (V1.90)
// Row 13, directly under Fading.
// Amount 0 = off. Above 0 enables the per-point three-octave deviation.
// ============================================================

// ---- Noise Amount (left) ----
#region

var over = 0
var ex   = 1198
var ey   = 436 + (28*13)
var sly  = ey
var slx  = ex + noiseAmt

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_noiseAmt = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_noiseAmt
{
	over     = 1
	slx      = clamp(mouse_x, ex, ex+40); pleaseGen = true
	noiseAmt = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318, ey+11, string(noiseAmt))
draw_set_color(c_white)

if mouse_x > 1312 and mouse_y > ey-10 and mouse_x < 1340 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                    = string(noiseAmt)
		textBox_noiseAmt       = 1
		textBox_noiseAmt_value = string(noiseAmt)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_noiseAmt = 0 }

if textBox_noiseAmt == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318, ey+11, string(noiseAmt))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(noiseAmt)), ey-9, 1320+string_width(string(noiseAmt)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		noiseAmt = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_noiseAmt_value = str

	if real(textBox_noiseAmt_value) > 40 { textBox_noiseAmt_value="40"; str="40" }
	noiseAmt = clamp(real(textBox_noiseAmt_value), 0, 40)

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

if mouse_x >= ex and mouse_x <= ex+40
{
	if mouse_y > sly-10 and mouse_y < sly+10
	{
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_noiseFreq = true }
	}
}

if mouse_check_button(mb_left) && slider_interract_noiseFreq
{
	over      = 1
	slx       = clamp(mouse_x, ex, ex+40); pleaseGen = true
	noiseFreq = clamp(slx-ex, 0, 40)
}

draw_sprite(spr_smallNotch, over, clamp(slx, ex, ex+40), sly)
draw_set_color(c_gray)
draw_set_valign(fa_bottom); draw_set_halign(fa_left)
draw_text(1318+34, ey+11, string(noiseFreq))
draw_set_color(c_white)

if mouse_x > 1347 and mouse_y > ey-10 and mouse_x < 1376 and mouse_y < ey+10
{
	if mouse_check_button_pressed(mb_left)
	{
		reset_textBoxes(); pleaseGen = true
		str                     = string(noiseFreq)
		textBox_noiseFreq       = 1
		textBox_noiseFreq_value = string(noiseFreq)
	}
}
else { if mouse_check_button_pressed(mb_left) textBox_noiseFreq = 0 }

if textBox_noiseFreq == 1
{
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_text(1318+34, ey+11, string(noiseFreq))
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(noiseFreq)), ey-9, 1320+34+string_width(string(noiseFreq)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		noiseFreq = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_noiseFreq_value = str

	if real(textBox_noiseFreq_value) > 40 { textBox_noiseFreq_value="40"; str="40" }
	noiseFreq = clamp(real(textBox_noiseFreq_value), 0, 40)

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: NOISE FREQUENCY


// ============================================================
// SLIDER: STRAND LENGTH
// ============================================================
#region

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
		strandLengthOverride[setSelectedID] = clamp(slx-ex, 0, 100) * 38
		setLengthOverrode[setSelectedID]    = 1
	}
	else
	{
		length = clamp(slx-ex, 0, 100) * 38
		for (setChange = 0; setChange < 12; setChange++)
		{
			if setLengthOverrode[setChange] != 1 strandLengthOverride[setChange] = length
		}
	}
	draw_set_color(c_white)
}

draw_set_color(c_gray)
if (setSelectedID != -1 && setLengthOverrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(length))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandLengthOverride[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(length)), ey-9, 1320+string_width(string(length)), ey+7, 2)
	draw_set_color(c_white)

	#region // Numpad input (allows up to 4 digits)
	if string_length(str) <= 4
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

	if keyboard_lastkey != -1 and string_length(str) < 6
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		length = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_length_value = str

	if real(textBox_length_value) > 3800 { textBox_length_value="3800"; str="3800" }
	length = clamp(real(textBox_length_value), 1, 3800)
	if setSelectedID != -1
	{
		strandLengthOverride[setSelectedID] = length
		setLengthOverrode[setSelectedID]    = 1
	}
	else
	{
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerAmt1Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(mixer1))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetMixerAdj1[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(mixer1)), ey-9, 1320+string_width(string(mixer1)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer1 = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer1_value = str

	if real(textBox_mixer1_value) > 40 { textBox_mixer1_value="40"; str="40" }
	mixer1 = clamp(real(textBox_mixer1_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerAdj1[setSelectedID]   = mixer1
		setMixerAmt1Overrode[setSelectedID] = 1
	}
	else
	{
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

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj1[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs1Overrode[setSelectedID]     = 1
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerOfs1Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318+34, ey+11, string(mixer1_offset))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj1[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(mixer1_offset)), ey-9, 1320+34+string_width(string(mixer1_offset)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer1_offset = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer1_offset_value = str

	if real(textBox_mixer1_offset_value) > 40 { textBox_mixer1_offset_value="40"; str="40" }
	mixer1_offset = clamp(real(textBox_mixer1_offset_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj1[setSelectedID] = mixer1_offset
		setMixerOfs1Overrode[setSelectedID]     = 1
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerAmt2Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(mixer2))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetMixerAdj2[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(mixer2)), ey-9, 1320+string_width(string(mixer2)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer2 = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer2_value = str

	if real(textBox_mixer2_value) > 40 { textBox_mixer2_value="40"; str="40" }
	mixer2 = clamp(real(textBox_mixer2_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerAdj2[setSelectedID]   = mixer2
		setMixerAmt2Overrode[setSelectedID] = 1
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

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj2[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs2Overrode[setSelectedID]     = 1
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerOfs2Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318+34, ey+11, string(mixer2_offset))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj2[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(mixer2_offset)), ey-9, 1320+34+string_width(string(mixer2_offset)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer2_offset = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer2_offset_value = str

	if real(textBox_mixer2_offset_value) > 40 { textBox_mixer2_offset_value="40"; str="40" }
	mixer2_offset = clamp(real(textBox_mixer2_offset_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj2[setSelectedID] = mixer2_offset
		setMixerOfs2Overrode[setSelectedID]     = 1
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerAmt3Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318, ey+11, string(mixer3))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318, ey+11, string(strandSetMixerAdj3[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+string_width(string(mixer3)), ey-9, 1320+string_width(string(mixer3)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer3 = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer3_value = str

	if real(textBox_mixer3_value) > 40 { textBox_mixer3_value="40"; str="40" }
	mixer3 = clamp(real(textBox_mixer3_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerAdj3[setSelectedID]   = mixer3
		setMixerAmt3Overrode[setSelectedID] = 1
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

	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj3[setSelectedID] = clamp(slx-ex, 0, 40)
		setMixerOfs3Overrode[setSelectedID]     = 1
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

draw_set_color(c_gray)
if (setSelectedID != -1 && setMixerOfs3Overrode[setSelectedID] != 0) draw_set_color(or_color)
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
	draw_set_color(c_black)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	if setSelectedID == -1 draw_text(1318+34, ey+11, string(mixer3_offset))
	if setSelectedID != -1 { draw_set_color(or_editColor); draw_text(1318+34, ey+11, string(strandSetMixerOffsetAdj3[setSelectedID])) }
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1320+34+string_width(string(mixer3_offset)), ey-9, 1320+34+string_width(string(mixer3_offset)), ey+7, 2)
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

	if keyboard_lastkey != -1 and string_length(str) < 4
	{
		if keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57)
			str += keyboard_lastchar
		mixer3_offset = real(str)
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str)-1)
			if str == "" str = "0"
		}
		keyboard_lastkey = -1
	}
	textBox_mixer3_offset_value = str

	if real(textBox_mixer3_offset_value) > 40 { textBox_mixer3_offset_value="40"; str="40" }
	mixer3_offset = clamp(real(textBox_mixer3_offset_value), 0, 40)
	if setSelectedID != -1
	{
		strandSetMixerOffsetAdj3[setSelectedID] = mixer3_offset
		setMixerOfs3Overrode[setSelectedID]     = 1
	}

	if keyboard_check_pressed(vk_enter) forceUpdate = 1
}

#endregion
// END SLIDER: MIXER 3 OFFSET


// ============================================================
// COLOUR SLIDERS: ROOT POSITION + TIP POSITION
// ============================================================

// ---- Root Position ----
#region

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
if mouse_check_button_released(mb_left) nullify_sliderInterracts()


// ============================================================
// STRAND COUNT DISPLAY (per-set totals row)
// ============================================================
#region

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

draw_set_color(colrBack)    draw_rectangle(1569, 541, 1631, 565, 0)
draw_set_color(customColVarA)  draw_rectangle(1569, 568, 1631, 592, 0)
draw_set_color(customColVarB)  draw_rectangle(1569, 595, 1631, 619, 0)
draw_set_color(customRootCol)  draw_rectangle(1569, 622, 1631, 646, 0)
draw_set_color(customTipCol)   draw_rectangle(1569, 649, 1631, 673, 0)

// Old / new colour comparison bar
draw_set_color(storeColor) draw_rectangle(1658, 760, 1771, 790, 0)
draw_set_color(newColor)   draw_rectangle(1772, 760, 1885, 790, 0)

#endregion


// ============================================================
// COLOUR MODE BUTTONS (RGB / HSV / Grey)
// ============================================================
#region

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

draw_set_color(c_gray)

// Build hex string from current colour components
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
	draw_set_color(c_black)
	draw_set_font(regFont)
	if tickytime > 0.5 and tickytime < 0.9
		draw_line_width(1536+string_width(string(str2)), 733, 1536+string_width(string(str2)), 719, 2)

	// Backspace
	if keyboard_lastkey == 8
		str2 = string_copy(str2, 1, string_length(str2)-1)

	// Character input (hex digits 0-9, a-f, A-F)
	if keyboard_lastkey != -1 and string_length(str2) <= 5
	{
		if (keyboard_lastkey == 46 or (keyboard_lastkey >= 48 and keyboard_lastkey <= 57))
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

// ID strand-vs-set toggle
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

draw_set_halign(fa_left)
var Vxpos = 1390
var Vypos = 21

tick += 4
if tick > 359.99 tick = 0

// During generation: show imgOverride canvas centered on current set


{
	// Helper: flash colour for "not generated" warning
	var tt     = abs(sin(degtorad(tick)))
	var pcolor = make_color_rgb(tt*255, tt*128, tt*32)

	// ---- RGB Mask ----
	if img == 0
	{
		
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
draw_text(360, 1035, smallTip)
draw_set_valign(fa_bottom)
draw_text(1050, 950, Tooltip)
draw_set_halign(fa_left)

#endregion


// ============================================================
// AO + COLOUR MAP MULTIPLIED PREVIEW (hold J)
// ============================================================
#region

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

checkAndOffset()
draw_set_font(regFont)

#endregion


// ============================================================
// UI EXTRAS: OVERRIDE INDICATOR DOTS
// ============================================================
#region

if uiExtras == 1
{
	for (scan = 0; scan < 11; scan++)
	{
		// Strand count override (orange)
		draw_set_color(or_color)
		if setCountOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1039, 3, 0)
			draw_circle(1120+(scan*7),  435,  2, 0)
		}
		// Length override (blue)
		draw_set_color(blu_color)
		if setLengthOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1045, 3, 0)
			draw_circle(1120+(scan*7),  463,  2, 0)
		}
		// Spacing override (green)
		draw_set_color(grn_color)
		if setSpacingOverrode[scan] != 0
		{
			draw_circle(1100+(scan*80), 1051, 3, 0)
			draw_circle(1120+(scan*7),  491,  2, 0)
		}
		// Wavyness override (purple)
		draw_set_color(pur_color)
		if setWaveynessOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1039, 3, 0)
			draw_circle(1120+(scan*7),  547,  2, 0)
		}
		// Taper override (red)
		draw_set_color(red_color)
		if setTaperOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1045, 3, 0)
			draw_circle(1120+(scan*7),  603,  2, 0)
		}
		// Vari override (yellow)
		draw_set_color(yel_color)
		if setVariOverrode[scan] != 0
		{
			draw_circle(1106+(scan*80), 1051, 3, 0)
			draw_circle(1120+(scan*7),  631,  2, 0)
		}
		// Y range override (orange)
		draw_set_color(or_color)
		if strandYRanRangeOverrode[scan] != 0
		{
			draw_circle(1112+(scan*80), 1051, 3, 0)
			draw_circle(1120+(scan*7),  659,  2, 0)
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
draw_set_font(smallFont)
draw_text(1210, 70, lastFileName)
draw_set_font(regFont)

// Multi-strand / curl type toggle button
if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x, mouse_y, 266, 1030, 330, 1050)
{
	moreHairs = 1 - moreHairs
	pleaseGen = true
}
draw_sprite(spr_but_StrandType, moreHairs, 266, 1028)

// Curl rotation control (visible only in multi-strand mode)
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
if bkCol_active   == 1 draw_sprite(spr_colHL, 0, 1566, 540)
if ColA_active    == 1 draw_sprite(spr_colHL, 0, 1566, 567)
if ColB_active    == 1 draw_sprite(spr_colHL, 0, 1566, 594)
if RootCol_active == 1 draw_sprite(spr_colHL, 0, 1566, 620)
if TipCol_active  == 1 draw_sprite(spr_colHL, 0, 1566, 647)

// Seed value display
draw_set_color(c_gray)
draw_set_font(regFont)
if setSelectedID != -1 draw_text(1214, 1006, string(randomSeedVal[setSelectedID]))
else                    draw_text(1214, 1006, string(seedVal))
draw_set_color(c_white)

#endregion


// ============================================================
// HELP PANEL TOGGLE
// ============================================================
#region

if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x, mouse_y, 846, 1027, 901, 1051)
	showHelp = 1 - showHelp

if showHelp == 1 draw_sprite(spr_HelpPanel, 0, 0, 0)

#endregion


// ============================================================
// STARTUP SPLASH SCREEN
// ============================================================
#region

if firstTime and skipIntro == 0
{
	draw_set_font(bigFont)
	draw_set_color(c_black)
	draw_set_alpha(0.90)
	draw_rectangle(0, 0, 1920, 1080, 0)
	draw_set_alpha(1)
	draw_set_color(c_white)
	draw_set_halign(fa_center)

	if demoMode == 1 draw_text((1920/2)+2, 300, demoInfo)
	draw_text((1920/2)+2, 300, "Hair Strand Designer " + string(versionHSD))
	

	draw_set_font(regFont)

	

	draw_set_halign(fa_center)
	draw_set_color(c_ltgray)
	draw_text((1920/2)+2, 480,
		"Please avoid exporting textures to the same folder as the application")


	draw_set_color(c_white)
	draw_text((1920/2), 520, "Press Enter or click to get started.")
	draw_set_color(c_black)
	draw_set_halign(fa_left)

	if keyboard_check_pressed(vk_enter) or mouse_check_button_pressed(mb_left) or mouse_check_button_pressed(mb_right)
	{
		dynamicRes          = 1
		firstTime           = false
		readyToCheckAutoloads = 1
	}
}

#endregion


// ============================================================
// RUNTIME INFO BAR + KEYBOARD SHORTCUTS LEGEND
// ============================================================



// ============================================================
// HEART ICON (Easter egg)
// ============================================================
#region

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
if keyboard_check_pressed(vk_enter)
{
	dynamicRes = 1
	reset_textBoxes()
}
