// =============================================================================
// resetSurfaces - EMPTY. THIS FUNCTION DOES NOTHING.
//
// The whole body is inside the comment block below, so a call returns
// immediately. It is still CALLED from doMainStep (when a surface is missing
// before a render, and in the "else" branch of every map's background fill)
// and from Draw_0 (when 'canvas' is missing). None of those calls recreate
// anything. What actually brings a lost surface back is canvasCheck() (End
// Step, and the top of doMainStep) and killSurfaces() (Begin Step).
//
// If one of those callers ever does reach its fallback with the surface still
// missing, the surface_set_target that follows it will fail - look at
// canvasCheck, not here.
//
// The old body is kept below for reference. It freed and recreated the nine
// map canvases and reloaded each from a "*_Surface" file if one existed.
// Note that every reload in it draws to 'canvas', whichever map it was for.
// =============================================================================
function resetSurfaces() {
/*
					surface_free(canvas)
					surface_free(color_canvas)
					surface_free(ao_canvas)
					surface_free(depth_canvas)
					surface_free(flow_canvas)
					surface_free(id_canvas)
					surface_free(mask_canvas)
					surface_free(nm_canvas)
					surface_free(frizz_canvas)
				
				//audio_play_sound(Sound1,0,0)
					canvas=surface_create(4096,4096) // out texture surface
					if file_exists("RGB_Surface") 
						{
							
							var surfSprite = sprite_add("RGB_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
						
					flow_canvas=surface_create(4096,4096) // out texture surface
					if file_exists("FLOW_Surface") 
						{
							var surfSprite = sprite_add("FLOW_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
						
					mask_canvas=surface_create(4096,4096) // out texture surface
					if file_exists("MASK_Surface") 
						{
							var surfSprite = sprite_add("MASK_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
						
					nm_canvas=surface_create(4096,4096) // out texture surface
					if file_exists("NM_Surface") 
						{
							var surfSprite = sprite_add("NM_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					id_canvas=surface_create(4096,4096) // will fill out with ID strands in RGBCMY
					if file_exists("ID_Surface") 
						{
							var surfSprite = sprite_add("ID_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					color_canvas=surface_create(4096,4096) // will fill out with ID strands in RGBCMY
					if file_exists("COLOR_Surface") 
						{
							var surfSprite = sprite_add("COLOR_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					depth_canvas=surface_create(4096,4096) // will fill out with a depth pass
					if file_exists("DEPTH_Surface") 
						{
							var surfSprite = sprite_add("DEPTH_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					ao_canvas=surface_create(4096,4096) // will fill out with a depth pass
					if file_exists("AO_Surface") 
						{
							var surfSprite = sprite_add("AO_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					frizz_canvas=surface_create(4096,4096) // will fill out with a depth pass
					if file_exists("FRIZZ_Surface") 
						{
							var surfSprite = sprite_add("FRIZZ_Surface",0,0,0,0,0)
							surface_set_target(canvas)
								{
								draw_sprite(surfSprite,0,0,0)
								}
							surface_reset_target()
						sprite_delete(surfSprite) // free immediately after use
						}
					
					//draw_texture_flush()
			

	// END OF SETUP

*/


}
