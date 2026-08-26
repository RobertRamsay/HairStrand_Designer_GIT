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

	if firstTime == false
	{
		draw_text(1644, 888,
			"\nReset selected overrides (F4)"
			+"\nReset all overrides (F5)"
			+"\nSoft reset (F6)"
			+"\nToggle Heart (F7)"
			+"\nEdit Mixers (F8)"
			+"\nLoad Palette Image (F9)")
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
		draw_set_font(smallFont)
		if aoType==0  {draw_text(1274*ssx,312*ssy,"AO = THIN");aoExtra=0.75}
		if aoType==1  {draw_text(1274*ssx,312*ssy,"AO = DEFAULT");aoExtra=0.87}
		if aoType==2  {draw_text(1274*ssx,312*ssy,"AO = WIDE");aoExtra=1.05}
		if aoType==3  {draw_text(1274*ssx,312*ssy,"AO = EXTREME");aoExtra=1.6}
	draw_set_font(regFont)


			{
			if point_in_rectangle(mouse_x*ssx,mouse_y*ssy,1268*ssx,290*ssy,1350*ssx,310*ssy)
				{
				draw_rectangle(1268*ssx,290*ssy,1350*ssx,310*ssy,1)
				if mouse_check_button_pressed(mb_left) aoType++
				if mouse_check_button_pressed(mb_right) aoType--
				if aoType<0 aoType=3
				if aoType>3 aoType=0
				}
			}
		}


//draw_text(0,1000,"Note: Still working on thickness override and copy paste")