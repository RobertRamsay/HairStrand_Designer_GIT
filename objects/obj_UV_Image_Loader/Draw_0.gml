// draw the UV overlay
// obj_UV_Image_Loader Draw. Despite the line above, the image itself is drawn
// by obj_surfaceDweller Draw_0. This event only handles the opacity slider on
// the bottom bar, just left of the loader button:
//   - draws the slider's notch at x 977; y runs from 1059 (a=0) up to 1029 (a=1)
//   - while the left button is held inside x 974-981, y 1028-1060, sets
//     a = (1060 - mouse_y) / 30, clamped to 0-1
// The else branch destroys the object if its sprite does not exist. Note that
// cancelling the file dialog does NOT get here: Create then uses sprite_null,
// which is a real sprite asset in the project, so sprite_exists is true and
// the object stays alive with that placeholder as its image.
if sprite_exists(loadedSprite)
	{
	// draw the opacity notch
	draw_circle(977,1059-(a*30),3,0)
	}
	else
	{
		with(self){instance_destroy()}
	}
	
	if mouse_x>974 and mouse_x<981
		{
			if mouse_y>1028 and mouse_y<1060
				{
					if mouse_check_button(mb_left)
						{
							a=clamp(((1060-mouse_y)/30),0,1)
						}
				}
		}
		