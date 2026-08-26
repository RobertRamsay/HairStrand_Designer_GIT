// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function exportIndividual(){
	if fullscreenMode==1 window_set_topmost(0) // for fullscreen mode
		var vSpace=27;
if mouse_check_button_pressed(mb_left)
	{
	if mouse_x>1347 and mouse_x<1370// enable / disable area
		{
			if mouse_y>130-(vSpace*1) and mouse_y<157-(vSpace*1)
				{				
					if rgbMask_GenState==2 
					{
						var file;
						file = get_save_filename("RGBMaskMap|*.png", "RGBMask_");

						if file != ""
						    {
							surface_save(canvas,file)
							}
						} // save
				}
				
			if mouse_y>130 and mouse_y<157
				{
					if norm_GenState==2 
										{
						var file;
						file = get_save_filename("NormalMap|*.png", "NORM_");
	

						if file != ""
						    {
								//make into proper normal map first...
								if moreHairs==1
									{
									surface_set_target(tNormsurf)
										{
										shader_set(shd_normal)
											{
											draw_surface(nm_canvas,0,0)
											}
										shader_reset()
										}
										surface_reset_target()
									}
								
								if moreHairs==0
									{
									surface_set_target(tNormsurf)
										{
											draw_surface(nm_canvas,0,0)
										}
										surface_reset_target()
									}
								
									
									normSprite=sprite_create_from_surface(tNormsurf,0,0,4096,4096,0,0,0,0)
							//file = get_save_filename("Maps|*.png", prjName+"_Normal");
							sprite_save(normSprite,0,file)
							sprite_flush(normSprite)
							sprite_delete(normSprite)
							//surface_save(nm_canvas,file)
							}
						} // save
				}
			if mouse_y>130+(vSpace*1) and mouse_y<157+(vSpace*1)
				{
					if mask_GenState==2 
										{
						var file;
						file = get_save_filename("MaskMap|*.png", "MASK_");	

						if file != ""
						    {
							surface_save(mask_canvas,file)
							}
						} // save
				}

			if mouse_y>130+(vSpace*2) and mouse_y<157+(vSpace*2)
				{
					if color_GenState==2 
										{
						var file;
						file = get_save_filename("ColorMap|*.png", "COLOR_");

						if file != ""
						    {
							surface_save(color_canvas,file)
							}
						} // save
				}


			if mouse_y>130+(vSpace*3) and mouse_y<157+(vSpace*3) 
				{
					if id_GenState==2 
										{
						var file;
						file = get_save_filename("IDMap|*.png", "ID_");

						if file != ""
						    {
							surface_save(id_canvas,file)
							}
						} // save
				}
				
			if mouse_y>130+(vSpace*4) and mouse_y<157+(vSpace*4)
				{
					if depth_GenState==2 
										{
						var file;
						file = get_save_filename("DepthMap|*.png", "DEPTH_");

						if file != ""
						    {
							surface_save(depth_canvas,file)
							}
						} // save
				}
				
			if mouse_y>130+(vSpace*5) and mouse_y<157+(vSpace*5)
				{
					if flow_GenState==2 
										{
						var file;
						file = get_save_filename("FlowMap|*.png", "FLOW_");

						if file != ""
						    {
							surface_save(flow_canvas,file)
							}
						} // save
				}
	
				
			if mouse_y>130+(vSpace*6) and mouse_y<157+(vSpace*6)
				{
					if ao_GenState==2 
										{
						var file;
						file = get_save_filename("AOMap|*.png", "AO_");	

						if file != ""
						    {
							surface_save(ao_canvas,file)
							}
						} // save
				}
				
				
			if mouse_y>130+(vSpace*6) and mouse_y<157+(vSpace*7)
				{
				if doFrizz and frizz_GenState==2// save the flow canvas if active
					{
		
					var file;
					file = get_save_filename("FrizzMap|*.png", "FRIZZ_");
		

						if file != ""
							{
								surface_save(frizz_canvas,file)
							}
					}
				}
		}
	}
	if fullscreenMode==1 window_set_topmost(1) // for fullscreen mode
	
}