/// @description Mixer editor exit button (V1.90)
// obj_surfaceDweller is persistent and keeps drawing the whole main UI in this
// room, so this button lives in Draw GUI to guarantee it sits on top of it.
// Leaving the editor was previously only discoverable via ENTER, the main UI's
// X, or ESC - none of which are visible from here.

// Kept clear of the 0-20px window drag strip and of every main-UI hit region,
// all of which start at x >= 985.
var _bl = 30
var _bt = 30
var _br = 300
var _bb = 74

var _hov = point_in_rectangle(mouse_x, mouse_y, _bl, _bt, _br, _bb)

var _fill = make_color_rgb(44, 44, 50)
var _edge = make_color_rgb(110, 110, 120)
if _hov
	{
	_fill = make_color_rgb(150, 50, 50)
	_edge = c_white
	}

draw_set_color(_fill)
draw_rectangle(_bl, _bt, _br, _bb, 0)
draw_set_color(_edge)
draw_rectangle(_bl, _bt, _br, _bb, 1)

draw_set_font(bigFont)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_color(c_white)
draw_text((_bl + _br) / 2, (_bt + _bb) / 2 - 6, "EXIT MIXER EDITOR")

draw_set_font(smallFont)
draw_set_color(make_color_rgb(170, 170, 178))
draw_text((_bl + _br) / 2, _bb - 12, "ENTER  /  ESC")

draw_set_font(regFont)
draw_set_halign(fa_left)
draw_set_valign(fa_bottom)
draw_set_color(c_white)

// ESC is handled by obj_surfaceDweller's Key Press event, but that object is
// only here because it is persistent. Handle it locally too so the editor can
// always be left, and so the button and the key share one exit path.
if (_hov and mouse_check_button_pressed(mb_left)) or keyboard_check_pressed(vk_escape)
	{
	obj_surfaceDweller.img = 9   // restore preview mode
	room_goto(Room_HSD)
	}
