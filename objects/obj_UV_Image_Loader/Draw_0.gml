// draw the UV overlay
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
		