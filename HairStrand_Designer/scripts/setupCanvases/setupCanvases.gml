// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function setupCanvases(){
// SETUP CANVASES
//audio_play_sound(Sound1,0,0)
#region
	ex=1300;
	ey=800;
	slx=ex;
	sly=ey;
	count++
	infoMsg="Count:"+string(count)
	
	if !surface_exists(canvas) canvas=surface_create(surfSize,surfSize) // out texture surface
	if !surface_exists(flow_canvas) flow_canvas=surface_create(surfSize,surfSize) // out texture surface
	if !surface_exists(mask_canvas) mask_canvas=surface_create(surfSize,surfSize) // out texture surface
	if !surface_exists(nm_canvas) nm_canvas=surface_create(surfSize,surfSize) // out texture surface
	if !surface_exists(id_canvas) id_canvas=surface_create(surfSize,surfSize) // will fill out with ID strands in RGBCMY
	if !surface_exists(color_canvas) color_canvas=surface_create(surfSize,surfSize) // will fill out with ID strands in RGBCMY
	if !surface_exists(depth_canvas) depth_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
	if !surface_exists(ao_canvas) ao_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
	if !surface_exists(frizz_canvas) frizz_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
	if !surface_exists(blurSurface) blurSurface=surface_create(surfSize,surfSize) // will fill out with a blur
	if !surface_exists(tNormsurf) tNormsurf=surface_create(surfSize,surfSize) // will fill out with a blur
if count>1 
	{
	var regenFile=file_text_open_write("RegenCheck.txt")
		{
		file_text_write_string(regenFile,"Regen");
		file_text_writeln(regenFile);
		}
		file_text_close(regenFile)
		
	// Free surfaces that already exist before the !surface_exists guards above
	// re-create them below - no leaks
	if surface_exists(canvas)       surface_free(canvas)
	if surface_exists(flow_canvas)  surface_free(flow_canvas)
	if surface_exists(mask_canvas)  surface_free(mask_canvas)
	if surface_exists(nm_canvas)    surface_free(nm_canvas)
	if surface_exists(id_canvas)    surface_free(id_canvas)
	if surface_exists(color_canvas) surface_free(color_canvas)
	if surface_exists(depth_canvas) surface_free(depth_canvas)
	if surface_exists(ao_canvas)    surface_free(ao_canvas)
	if surface_exists(frizz_canvas) surface_free(frizz_canvas)
	if surface_exists(blurSurface)  surface_free(blurSurface)
	if surface_exists(tNormsurf)    surface_free(tNormsurf)
	draw_texture_flush()
	//game_restart()
	}

// Only create these if they don't already exist (guards above may have just freed them)
if !surface_exists(frizz_canvas) frizz_canvas = surface_create(surfSize, surfSize)
if !surface_exists(tNormsurf)    tNormsurf    = surface_create(surfSize, surfSize)
if !surface_exists(blurSurface)  blurSurface  = surface_create(surfSize, surfSize)
	
	surface_set_target(flow_canvas)

				// draw Flow backdrop

				
					draw_set_color(make_color_rgb(0,0,0))
					//draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
			
					
				surface_reset_target()
	
				surface_set_target(nm_canvas)

				// draw NM backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
				surface_reset_target()
				
				
				surface_set_target(tNormsurf)

				// draw NM backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
				surface_reset_target()
				
				
				
				
				
				
				surface_set_target(blurSurface)

				// draw color for blur

					{
					//draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_white,1);
					//draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					surface_reset_target()
				
				
				
				surface_set_target(canvas)

				// draw color backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					surface_reset_target()
								
				surface_set_target(ao_canvas)

				// draw AO backdrop

					{
					draw_set_color(make_color_rgb(200,200,200))
					//draw_clear_alpha(c_white,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					
					if file_exists("ao.png")
						{
						if sprite_exists(aoSprite) sprite_delete(aoSprite) // free old before reloading
						aoSprite=sprite_add("ao.png",0,0,0,0,0)
						}
					if sprite_exists(aoSprite) draw_sprite(aoSprite,0,0,0)
					
					}	
				
			surface_reset_target()
			
			surface_set_target(color_canvas)

				// draw color backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
			surface_reset_target()
			
			surface_set_target(mask_canvas)

				// draw color backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
			surface_reset_target()

				
				
			surface_set_target(id_canvas)

				// draw black backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
				surface_reset_target()
				
				
			surface_set_target(depth_canvas)

				// draw black backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
				surface_reset_target()
				
				surface_set_target(frizz_canvas)

				// draw black backdrop

					{
					draw_set_color(make_color_rgb(0,0,0))
					draw_clear_alpha(c_black,0);
					draw_rectangle(0,0,4095,4095,0)
					draw_set_color(c_white)
					}
					
				surface_reset_target()
				
				
				
				
				// color history
				colorHistoryPointer=0
				for (n=0;n<24;n++)
					{
					hCol[n]=c_black
					}
#endregion
// END OF SETUP
}