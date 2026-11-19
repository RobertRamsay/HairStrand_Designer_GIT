// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// exportIndividual()  -  save ONE generated map as a PNG
//
// Called every frame from obj_surfaceDweller Draw_0 (map list section), in its
// scope. Does nothing until the left button is pressed on one of the small
// export icons at the right-hand end of the map list.
//
// HIT AREA
//   Column x 1347-1370. Rows are vSpace (27 px) apart, the same rows the map
//   tick boxes use in Draw_0:
//     RGB Mask 103-130   Normal 130-157   Mask 157-184   Color 184-211
//     ID 211-238         Depth 238-265    Flow 265-292   AO 292-319
//     Frizz 319-346 intended (see the note on the last block)
//   If the panel art moves, change these together with Draw_0 and uiTips.
//
// RULES
//   - A map is only saved when its *_GenState is 2 (generated and up to date).
//     0 = off, 1 = ticked but not generated yet: the click then does nothing.
//   - get_save_filename opens the Windows save dialog; "" means cancelled.
//   - Maps are written straight from their 4096 surface with surface_save,
//     except the Normal map (see below).
//   - This writes PNGs only. The project .txt is not touched, and unlike the
//     S-key save this script has no demoMode check of its own.
//
// Fullscreen mode keeps the window "topmost", which would hide the save dialog
// behind it, so topmost is switched off on entry and back on at the end.
// This happens every frame, click or not.
// =============================================================================
function exportIndividual(){
	if fullscreenMode==1 window_set_topmost(0) // for fullscreen mode
		var vSpace=27; // row pitch of the map list
if mouse_check_button_pressed(mb_left)
	{
	if mouse_x>1347 and mouse_x<1370// enable / disable area
		{
			// RGB Mask row (one row above the 130-157 base row)
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
								// nm_canvas is copied to the scratch surface tNormsurf.
								// MULTI strand mode (moreHairs==1) passes it through
								// shd_normal on the way; SINGLE mode copies it as it is.
								// The copy is then turned into a temporary sprite and
								// saved with sprite_save rather than surface_save, and
								// the sprite is freed again straight away.
								// 4096 here is the fixed map size.
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
				

			// Frizz row. NOTE: the top edge uses vSpace*6, not *7, so this
			// test covers y 292-346: the AO row as well as the Frizz row.
			// A click on the AO export icon therefore also reaches this block
			// and, if a Frizz map is generated, opens a second (Frizz) save
			// dialog after the AO one. Suspected typo, left as found.
			// This is also the only row that checks its do* flag as well.
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