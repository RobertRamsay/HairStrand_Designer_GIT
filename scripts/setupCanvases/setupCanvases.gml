// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// THE SURFACES (all owned by obj_surfaceDweller)
//   Eleven 4096x4096 (surfSize) surfaces - nine output maps and two scratch:
//     canvas        RGB mask  (R variation, G root, B tip)      view img 0
//     nm_canvas     normal map (a height map in Multi Strand)   view img 1
//     id_canvas     ID map                                      view img 2
//     depth_canvas  depth map                                   view img 3
//     color_canvas  colour map                                  view img 4
//     mask_canvas   opacity mask                                view img 5
//     flow_canvas   flow / direction map                        view img 6
//     ao_canvas     ambient occlusion                           view img 7
//     frizz_canvas  frizz map                                   view img 8
//     blurSurface   scratch for the blur (B key, Draw_0)
//     tNormsurf     scratch used when the normal map is saved / exported
//   plus previewSurf[0..10], 1024x1024, one per strand set (created in Create_0,
//   drawn by previewJob).
//
//   Surfaces live in video memory and Windows can discard them at any time
//   (alt-tab, resolution change, sleep). The CONTENT is lost when that happens;
//   the scripts below only bring back blank surfaces.
//
// WHO DOES WHAT
//   setupCanvases       (this file) first-time creation + background fill.
//   canvasCheck         every step: recreate any single surface that is missing.
//   killSurfaces        free everything and recreate it all clean.
//   resetSurfaces       EMPTY - body commented out. Calls to it do nothing.
//   quickClearSurfaces  EMPTY - body commented out. Calls to it do nothing.
//
// The backgrounds painted by these scripts are only the idle state. At the
// start of every render doMainStep (MAP INITIALIZATION) fills each enabled map
// again with its real background, and those colours are the ones that matter
// for the saved textures. Keep the two in mind separately: e.g. frizz is
// cleared to black here but filled 128 grey for a render.
//
// -----------------------------------------------------------------------------
// setupCanvases - CALLED BY Create_0 only, once.
// Creates the eleven 4096 surfaces, fills each with its idle background, loads
// ao.png (if the file exists) onto the AO canvas, and resets the colour history.
// Also sets a few unrelated UI variables (ex, ey, slx, sly) and bumps 'count'.
//
// The "if count>1" block is a leftover from when this ran more than once: on a
// second run it writes RegenCheck.txt and FREES all eleven surfaces, after
// which only frizz_canvas, tNormsurf and blurSurface are recreated before the
// fills below. With the single call from Create_0, count is 1 and the block
// is skipped.
//
// The fills use a hard-coded 4095 where the creation uses surfSize. They agree
// only while surfSize is 4096.
// =============================================================================
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
	// (Only three of the eleven are re-created below - see the header.)
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
	
	// ---- idle background fills, one block per surface ----
	// Black for flow, normal, tNormsurf, RGB mask, colour, mask, ID, depth and
	// frizz; white for blurSurface; 200 grey for AO.
	// Several blocks clear to transparent black and then draw a black
	// rectangle over the top. (canvasCheck and killSurfaces do the clear only.)
	// This runs from Create, before doMainStep has ever switched alpha
	// writes off.
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
					
					// Optional ao.png in the working directory is loaded as aoSprite
					// and stamped over the grey. canvasCheck re-stamps the same
					// sprite if the AO canvas is ever recreated.
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
				// (24 recent-colour slots, all reset to black; n is an instance variable)
				colorHistoryPointer=0
				for (n=0;n<24;n++)
					{
					hCol[n]=c_black
					}
#endregion
// END OF SETUP
}