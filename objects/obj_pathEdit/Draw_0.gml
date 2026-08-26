/// @description Insert description here
// You can write your code in this editor
//obj_surfaceDweller.img=9 // lock to preview mode
 draw_set_halign(fa_right)
for (a=0;a<path_get_number(obj_surfaceDweller.editingPath[pathPointer]);a++)
	{

		var pathX=string(path_get_point_x(obj_surfaceDweller.editingPath[pathPointer],a))
		var pathY=string(path_get_point_y(obj_surfaceDweller.editingPath[pathPointer],a))
		draw_text(room_width-50,50+(a*20),"Path Point: "+string(a)+" : X = "+pathX+" : Y = "+pathY)
		
			if point_distance(mouse_x,mouse_y,512+(pathX/4),pathY/4)<15  
			{
				mode=1
				if mouse_check_button_pressed(mb_left)
					{			
						editPoint=a			
					}
				if mouse_check_button_pressed(mb_right)
					{ //reset x 
						editPoint=a
						path_change_point(obj_surfaceDweller.editingPath[pathPointer],editPoint,0,mouse_y*4,100)
					}
			}
			else
			{
				mode=0
			}
			draw_sprite(spr_smallNotch,mode,512+(pathX/4) ,pathY/4)
	}
	
	// drawing a representation
	path_copy=path_duplicate(obj_surfaceDweller.editingPath[pathPointer])
	path_rescale(path_copy,0.25,0.25)
	draw_path(path_copy,512,10,0)
	path_delete(path_copy) // V1.90 - the duplicate leaked one path per frame
	


if mouse_check_button(mb_left) and editPoint>0
	{
		path_change_point(obj_surfaceDweller.editingPath[pathPointer],editPoint,(mouse_x-512)*4,mouse_y*4,100)
	}
	if mouse_check_button_released(mb_left)
	{
		editPoint=-1
		mode=0
	}

	
	if keyboard_check_pressed(vk_up)
		{
			pathPointer++
			if pathPointer>2 pathPointer=0
		}
		
			if keyboard_check_pressed(vk_down)
		{
			pathPointer--
			if pathPointer<0 pathPointer=2
		}
		
		
		draw_text(room_width-50,1000,"Mixer editor V1.1\n"+
		"Mixer: "+string(pathPointer+1)+"  (UP/DOWN to switch)\n"+
		"Select the mixer from the UI panel\n"+
		"EXIT MIXER EDITOR - bottom centre, or press ENTER/ESC.\nRight click on any point to zero out the X-position.")
		
		if keyboard_check_pressed(vk_enter) 
		{
		obj_surfaceDweller.img=9 // restore img mode
		room_goto(Room_HSD) // back to main room
		}
		
		draw_set_halign(fa_left)