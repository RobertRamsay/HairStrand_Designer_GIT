/// @description Insert description here
// You can write your code in this editor
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

if skipIntro==1 and pleaseGen
	{
		draw_set_font(regFont)
	draw_set_color(c_black)
	draw_text(9,29,"Surfaces have been refreshed, please Re-Render(G) if you need to.")
	draw_set_color(c_white)
	draw_text(10,30,"Surfaces have been refreshed, please Re-Render(G) if you need to.")
	}
	
var ssx=1//screenScaleX
var ssy=1//screenScaleY

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