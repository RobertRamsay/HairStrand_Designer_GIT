/// @description Mixer editor: draw the curve and its points, handle dragging
// You can write your code in this editor
// -----------------------------------------------------------------------------
// obj_pathEdit Draw. Input is handled here as well as drawing, every frame.
//
// COORDINATES
//   Path points are stored at 4x screen size (the 4096 map against the 1024
//   canvas), and path x = 0 is drawn at the canvas centre, screen x 512. So:
//       screen x = 512 + pathX/4        screen y = pathY/4
//       pathX = (mouse_x - 512) * 4     pathY = mouse_y * 4
//   Every "/4", "*4" and "512" below is that conversion.
//
// CONTROLS
//   left press within 15 px of a point  -> grab it; drag while held
//   right click on a point              -> x back to 0, y to the mouse height
//   Up / Down                           -> next / previous mixer (wraps 0-2)
//   Enter                               -> back to the main room
//
// The right-hand column lists every point's raw X / Y for reference.
// -----------------------------------------------------------------------------
//obj_surfaceDweller.img=9 // lock to preview mode
 draw_set_halign(fa_right)
for (a=0;a<path_get_number(obj_surfaceDweller.editingPath[pathPointer]);a++)
	{

		// Held as strings for the text line; the "/4" maths further down still
		// works because GameMaker converts a numeric string in arithmetic.
		var pathX=string(path_get_point_x(obj_surfaceDweller.editingPath[pathPointer],a))
		var pathY=string(path_get_point_y(obj_surfaceDweller.editingPath[pathPointer],a))
		draw_text(room_width-50,50+(a*20),"Path Point: "+string(a)+" : X = "+pathX+" : Y = "+pathY)
		
			// mode is set afresh for each point, so it only decides which
			// frame of spr_smallNotch THIS point is drawn with (1 = hover).
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
	// A throwaway quarter-size copy of the path, drawn as the curve line and
	// deleted again in the same frame. It is drawn from (512,10), whereas the
	// point markers above use pathY/4 with no +10.
	path_copy=path_duplicate(obj_surfaceDweller.editingPath[pathPointer])
	path_rescale(path_copy,0.25,0.25)
	draw_path(path_copy,512,10,0)
	path_delete(path_copy) // V1.90 - the duplicate leaked one path per frame
	


// Drag. NOTE the test is editPoint>0, not >=0: point 0 (the first point of the
// curve) can be grabbed but never moves with the left button. Only the
// right-click reset above can change point 0. Whether that is deliberate
// (pinning the start of the curve) is not recorded.
// 100 is the path point's speed value, same as every other point.
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
		
		// Same exit as the button / ESC in Draw GUI. img=9 puts the main room
		// back on the Previewer.
		if keyboard_check_pressed(vk_enter)
		{
		obj_surfaceDweller.img=9 // restore img mode
		room_goto(Room_HSD) // back to main room
		}
		
		draw_set_halign(fa_left)