/// @description obj_plotCurver: drop and drag dots (not used)
// You can write your code in this editor
// NOT USED (see Create). Middle click / Space creates an obj_curver, which
// places itself at the mouse in its own Create. While the right button is held
// the nearest dot is latched once (gotOne) and follows the mouse until the
// button is released.
if mouse_check_button_pressed(mb_middle) or keyboard_check_pressed(vk_space)
	// plot a curver
	{
		instance_create_depth(0,0,-100,obj_curver)
	}
	
if mouse_check_button(mb_right)
	{
		if !gotOne && instance_exists(obj_curver)
			{
				nearest=instance_nearest(mouse_x,mouse_y,obj_curver)
				if nearest!=-1 
					{
						gotOne=true
					}
			}
		
	}
	
if gotOne
	{
		nearest.x=mouse_x
		nearest.y=mouse_y
	}
	
if mouse_check_button_released(mb_right)
	{
		gotOne=false
		nearest=-1
	}