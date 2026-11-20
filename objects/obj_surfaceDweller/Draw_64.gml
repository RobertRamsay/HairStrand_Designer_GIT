/// @description Draw GUI - title/FPS line, function-key buttons, AO width button
// -----------------------------------------------------------------------------
// EVENT : Draw GUI (event number 64). Runs every frame AFTER Draw_0, on top of it.
// DOES  : 1. title text with version, mouse position and FPS (handy for finding
//            the pixel coordinates used all over Draw_0)
//         2. the six function-key buttons F4..F9
//         3. the "surfaces refreshed" notice after a surface-loss restart
//         4. the AO width button (aoType -> aoExtra)
// READS : canDrawUI (set to 1 by object g, Begin Step, once firstTime is false -
//         i.e. once the splash has been dismissed), firstTime, fullscreenMode,
//         topMostMode, skipIntro, pleaseGen, ao_GenState, versionHSD.
// WRITES: uiKeyHeld, aoType, aoExtra. Leaves font=regFont, valign=fa_bottom,
//         halign=fa_left behind for the next frame's Draw_0.
// NOTE  : coordinates are room/GUI pixels on the fixed 1920x1080 layout.
//         Tooltips for these buttons are in uiTips(), not here.
// -----------------------------------------------------------------------------
//draw_text (mouse_x, mouse_y, string(xxx)+":"+string(yyy))

#region

if canDrawUI==1
{
	draw_set_color(c_gray)
	draw_set_font(regFont)
	draw_text(1390, 20, "Hair Strand Designer v" + string(versionHSD)
	                    + "   X:" + string(mouse_x) + "  Y:" + string(mouse_y)
	                    + "  FPS:" + string(fps))
	draw_set_color(c_white)

	draw_set_font(smallFont)
	draw_set_valign(fa_bottom)
	draw_set_halign(fa_left)
	draw_set_color(c_white)

	if fullscreenMode == 1 draw_text(1644, 848, "Toggle Topmost [F3]: " + string(topMostMode))

	// V1.96 - the function-key list is now a block of buttons. Each one taps
	// its key for a frame, so it runs exactly what the key itself runs.
	// Helper tips are in uiTips().
	// How the tap works: a click calls keyboard_key_press() and remembers the key
	// in uiKeyHeld; the line below releases it on the NEXT frame. In between,
	// GameMaker fires the real Key Press event (F6..F9 -> KeyPress_117..120) and
	// keyboard_check_pressed() sees it (F4/F5 are polled in Step_0 and Step_1).
	// Button order = sprite frame of spr_but_Tools: 0 F4 reset set, 1 F5 reset
	// all, 2 F6 restart, 3 F7 heart, 4 F8 mixers, 5 F9 palette.
	// Layout: 3 columns 72px apart from x=1644, 2 rows 30px apart from y=848,
	// each button 64x23. Hidden until the splash is dismissed (firstTime false).
	if uiKeyHeld != -1 { keyboard_key_release(uiKeyHeld); uiKeyHeld = -1 }
	if firstTime == false
	{
		var _toolKeys = [vk_f4, vk_f5, vk_f6, vk_f7, vk_f8, vk_f9]
		for (var _tb = 0; _tb < 6; _tb++)
		{
			var _tbx = 1644 + ((_tb mod 3) * 72)
			var _tby = 848 + ((_tb div 3) * 30)
			var _tbOver = point_in_rectangle(mouse_x, mouse_y, _tbx, _tby, _tbx + 64, _tby + 23)
			draw_sprite_ext(spr_but_Tools, _tb, _tbx, _tby, 1, 1, 0, _tbOver ? c_white : make_color_rgb(215, 215, 215), 1)
			if _tbOver and mouse_check_button_pressed(mb_left)
			{
				keyboard_key_press(_toolKeys[_tb])
				uiKeyHeld = _toolKeys[_tb]
			}
		}
	}
	draw_set_font(regFont)
}

#endregion

// The startup version / "new in" information now lives on the splash card
// drawn at the end of the Draw event, so nothing is drawn over it here.

// Surface-loss notice: removed in V1.97. After the automatic restart in Step_1
// (RegenCheck.txt, skipIntro==1) the maps are stale, so the "Changes Made,
// Please Press G or Generate" banner in the Draw event already says to render
// again; a second line of text here only overlapped it.
	
var ssx=1//screenScaleX
var ssy=1//screenScaleY
// (ssx / ssy are leftovers - nothing below uses them)

// AO WIDTH BUTTON (1272,290, 64x23 - beside the AO row of the map list).
// aoType 0..3 picks how wide the ambient-occlusion shadow is stamped around each
// strand; aoExtra is the number the renderer actually uses (doMainStep, AO Map
// Draw: it scales spr_aoPlotter and sets the pass count). Left click = next,
// right click = previous, wrapping. aoType is also the frame of spr_but_AO.
// Hidden (and aoExtra frozen) once the AO map is finished (ao_GenState==2).
// Clicking the AO enable box in Draw_0 drops ao_GenState back to 0, which
// brings the button back.
// The Create_0 default aoExtra=1.55 is replaced by this table on the first frame
// the button is visible (aoType 1 -> 0.87).

	if ao_GenState!=2 and firstTime!=1 and canDrawUI==1
		{
		// V1.96 - AO width is a button now (was plain text)
		if aoType==0  aoExtra=0.75
		if aoType==1  aoExtra=0.87
		if aoType==2  aoExtra=1.05
		if aoType==3  aoExtra=1.6
		var _aoOver = point_in_rectangle(mouse_x,mouse_y,1272,290,1336,313)
		draw_sprite_ext(spr_but_AO, aoType, 1272, 290, 1, 1, 0, _aoOver ? c_white : make_color_rgb(215, 215, 215), 1)

			{
			if _aoOver
				{
				if mouse_check_button_pressed(mb_left) aoType++
				if mouse_check_button_pressed(mb_right) aoType--
				if aoType<0 aoType=3
				if aoType>3 aoType=0
				}
			}
		}


//draw_text(0,1000,"Note: Still working on thickness override and copy paste")