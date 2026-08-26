/// @description Insert description here
// You can write your code in this editor

if canSave and demoMode==0
	{
		if fullscreenMode==1 window_set_topmost(0)
	//quicksave
	//
	
	//
	//saveNameId=string(current_second)+string(current_minute)+string(current_day)+string(current_month)+string(current_year)
	
	// are these used??

	// ?

// ALL AT ONCE SAVING... problems getting al the characters needed for the naming (lowercase and numbers only by the looks of it)
	//if rgbMask_GenState==2
	if !projectOnly {prjName=get_string("Project Name","HSD_");} // no need for a project name call
	
	if prjName!="" 
	{
		//if instance_exists(obj_save) {instance_destroy(obj_save)}
		//	instance_create_depth(0,0,-1000,obj_save)
			
			
			fileCustom = get_save_filename_ext("HSD_Project|*.txt", prjName,"","Please save to a directory outside of the Application.");
			

		if fileCustom != ""
		    {
				saving=true
// initial line
			theFile = file_text_open_write(fileCustom);
			
		file_text_write_string(theFile,string(mainS));
			file_text_writeln(theFile);
			
// instruction line			
		file_text_write_string(theFile,string(instr));
			file_text_writeln(theFile);
			
			// VARIABLES TO SAVE
			#region
// main variables	
var o=obj_surfaceDweller
		file_text_write_string(theFile,"Seed:"+string(o.seedVal)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Blur:"+string(o.var_blur_amount)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"IDmode:"+string(o.idMode)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doRGB:"+string(o.doRGB)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doNorm:"+string(o.doNorm)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doColor:"+string(o.doColor)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doMask:"+string(o.doMask)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doID:"+string(o.doID)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doDepth:"+string(o.doDepth)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doFrizz:"+string(o.doFrizz)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doFlow:"+string(o.doFlow)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doAO:"+string(o.doAO)+";");
			file_text_writeln(theFile);
				
			file_text_write_string(theFile,"Current map:"+string(o.img)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Flip X:"+string(o.dirFlipX)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Flip Y:"+string(o.dirFlipY)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Blue:"+string(o.dirBlue)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Hue:"+string(o.dirHue)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Scale In:"+string(o.scaleIn)+";");  // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Scale Out:"+string(o.scaleOut)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Fade In:"+string(o.fadeIn)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Fade Out:"+string(o.fadeOut)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Background Color (HEX):"+string(dec_to_hex_save(o.colrBack))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation Tone 1 (HEX):"+string(dec_to_hex_save(o.customColVarA))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation Tone 2 (HEX):"+string(dec_to_hex_save(o.customColVarB))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Root Color (HEX):"+string(dec_to_hex_save(o.customRootCol))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Tip Color (HEX):"+string(dec_to_hex_save(o.customTipCol))+";"); 
			file_text_writeln(theFile);
			
			var sets = 11
			for (s=0;s<sets;s++) // support up to 11 sets potentaill greater later on
				{
				file_text_write_string(theFile,"Strand Count Override"+string(s)+":"+string(o.strandCountOverride[s])+";"); 
				file_text_writeln(theFile);
				file_text_write_string(theFile,"Strand Length Override"+string(s)+":"+string(o.strandLengthOverride[s])+";"); 
				file_text_writeln(theFile);
				
				}
	

			file_text_write_string(theFile,"MinScale:"+string(o.minScale)+";"); 
			file_text_writeln(theFile);

			file_text_write_string(theFile,"MaxScale:"+string(o.maxScale)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Color Mode:"+string(o.colorMode)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Tapering:"+string(o.tapering)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Root coverage:"+string(o.root)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Tip coverage:"+string(o.tip)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation:"+string(o.lifeVariant)+";"); 
			file_text_writeln(theFile);

			file_text_write_string(theFile,"Root Position:"+string(o.rootPosition)+";"); 
			file_text_writeln(theFile);

			file_text_write_string(theFile,"Tip Position:"+string(o.tipPosition)+";"); 
			file_text_writeln(theFile);

			file_text_write_string(theFile,"Waviness:"+string(o.wavyness)+";"); 
			file_text_writeln(theFile);

			file_text_write_string(theFile,"Strands:"+string(o.strands)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Reduction:"+string(o.diminish)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Max Strands:"+string(o.maxStrands)+";"); 
			file_text_writeln(theFile);
	
			file_text_write_string(theFile,"Spacing:"+string(o.distancings)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Set Distances:"+string(o.setDistance)+";"); 
			file_text_writeln(theFile);

		
			// New Vars in V 1.301
			var sets = 11
			for (s=0;s<sets;s++) // support up to 10 sets potentaill greater later on
				{
				file_text_write_string(theFile,"Strand X offset"+string(s)+":"+string(o.xOffset[s])+";"); 
				file_text_writeln(theFile);
				file_text_write_string(theFile,"Strand Y offset"+string(s)+":"+string(o.yOffset[s])+";"); 
				file_text_writeln(theFile);
				file_text_write_string(theFile,"Strand algortihm influence"+string(s)+":"+string(o.alogrithmInfluence[s])+";"); 
				file_text_writeln(theFile);
				
				}

			file_text_write_string(theFile,"Waviness Min Frequency:"+string(o.minFreq)+";"); 
			file_text_writeln(theFile);
			
				file_text_write_string(theFile,"Waviness Max Frequency:"+string(o.maxFreq)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Frizz power:"+string(o.frizz)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Mixer 1 amount:"+string(o.mixer1)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Mixer 1 offset:"+string(o.mixer1_offset)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Mixer 2 amount:"+string(o.mixer2)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Mixer 2 offset:"+string(o.mixer2_offset)+";"); 
			file_text_writeln(theFile);
			
									file_text_write_string(theFile,"Mixer 3 amount:"+string(o.mixer3)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Mixer 3 offset:"+string(o.mixer3_offset)+";"); 
			file_text_writeln(theFile);
			// fix 1 thickness ranges new in v1.33 - June16 2020
						file_text_write_string(theFile,"Root Thickness:"+string(o.rootThick)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Tip Thickness:"+string(o.tipThick)+";"); 
			file_text_writeln(theFile);
			
						file_text_write_string(theFile,"Thickness Variation:"+string(o.thickVary)+";"); 
			file_text_writeln(theFile);
			
			// taper influences
			var sets = 11
			for (s=0;s<sets;s++) // support up to 10 sets potentaill greater later on
				{
				file_text_write_string(theFile,"Taper Influence"+string(s)+":"+string(o.taperInfluence[s])+";"); 
				file_text_writeln(theFile);			
				}
			
			// end fix1

			// additional settings (7th July 2020)
			// PREVIEWER OPTI			
			file_text_write_string(theFile,"maxPreviewStrandsPerSet:"+string(maxPreviewStrandsPerSet)+";"); 
				file_text_writeln(theFile);	
			
			file_text_write_string(theFile,"optimalStep:"+string(optimalStep)+";"); 
				file_text_writeln(theFile);	
				
			// save path points and reassign when loaded
			
			for (a=0;a<path_get_number(editingPath[0]);a++)
				{
					var pathX=string(path_get_point_x(editingPath[0],a))
					var pathY=string(path_get_point_y(editingPath[0],a))
					file_text_write_string(theFile,"editingPath[0].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[0].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
				
			for (a=0;a<path_get_number(editingPath[1]);a++)
				{
					var pathX=string(path_get_point_x(editingPath[1],a))
					var pathY=string(path_get_point_y(editingPath[1],a))
					file_text_write_string(theFile,"editingPath[1].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[1].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
				
			for (a=0;a<path_get_number(editingPath[2]);a++)
				{
					var pathX=string(path_get_point_x(editingPath[2],a))
					var pathY=string(path_get_point_y(editingPath[2],a))
					file_text_write_string(theFile,"editingPath[2].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[2].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
			
			// save in the new override stuff if the version is correct
			//if real(verString)>=150
				{
					file_text_write_string(theFile,"***VERSION 1.5 and later specific"+";"); 
					file_text_writeln(theFile);		
					
					
					for (a=0;a<11;a++)
						{

						file_text_write_string(theFile,"setLengthOverrode["+string(a)+"]:"+string(setLengthOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setCountOverrode["+string(a)+"]:"+string(setCountOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setTaperOverrode["+string(a)+"]:"+string(setTaperOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveynessOverrode["+string(a)+"]:"+string(setWaveynessOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveFreqMinOverrode["+string(a)+"]:"+string(setWaveFreqMinOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveFreqMaxOverrode["+string(a)+"]:"+string(setWaveFreqMaxOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setVariOverrode["+string(a)+"]:"+string(setVariOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setSpacingOverrode["+string(a)+"]:"+string(setSpacingOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt1Overrode["+string(a)+"]:"+string(setMixerAmt1Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs1Overrode["+string(a)+"]:"+string(setMixerOfs1Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt2Overrode["+string(a)+"]:"+string(setMixerAmt2Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs2Overrode["+string(a)+"]:"+string(setMixerOfs2Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt3Overrode["+string(a)+"]:"+string(setMixerAmt3Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs3Overrode["+string(a)+"]:"+string(setMixerOfs3Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						//---
						
						file_text_write_string(theFile,"strandSetMixerAdj1["+string(a)+"]:"+string(strandSetMixerAdj1[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerAdj2["+string(a)+"]:"+string(strandSetMixerAdj2[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerAdj3["+string(a)+"]:"+string(strandSetMixerAdj3[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj1["+string(a)+"]:"+string(strandSetMixerOffsetAdj1[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj2["+string(a)+"]:"+string(strandSetMixerOffsetAdj2[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj3["+string(a)+"]:"+string(strandSetMixerOffsetAdj3[a])+";"); 
						file_text_writeln(theFile);	
						
						//---
						
						file_text_write_string(theFile,"strandSetTaperAdj["+string(a)+"]:"+string(strandSetTaperAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWavynessAdj["+string(a)+"]:"+string(strandSetWavynessAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWaveFreqMinAdj["+string(a)+"]:"+string(strandSetWaveFreqMinAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWaveFreqMaxAdj["+string(a)+"]:"+string(strandSetWaveFreqMaxAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetVariAdj["+string(a)+"]:"+string(strandSetVariAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetSpaceAdj["+string(a)+"]:"+string(strandSetSpaceAdj[a])+";"); 
						file_text_writeln(theFile);	
						

						}
						
						// finally save actual global length
						file_text_write_string(theFile,"length:"+string(length)+";"); 
						file_text_writeln(theFile);	
						
						
						// New in 1.53:
						file_text_write_string(theFile,"V1.53 - 21st Nov 2020"); 
						file_text_writeln(theFile);	
						
						// save vars
						for (set=0;set<11;set++)
							{	
							file_text_write_string(theFile,"strandYRanRange["+string(set)+"]:"+string(strandYRanRange[set])+";"); 
							file_text_writeln(theFile);	
						
							file_text_write_string(theFile,"strandYRanRangeOverrode["+string(set)+"]:"+string(strandYRanRangeOverrode[set])+";"); 
							file_text_writeln(theFile);	
							}
						//global
						file_text_write_string(theFile,"yRanRange:"+string(yRanRange)+";"); 
						file_text_writeln(theFile);	
						
						// New in 1.55
						file_text_write_string(theFile,"V1.55 - 28th Dec 2020"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"MultiStrandMode:"+string(moreHairs)+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"MultiStrandMicroCurl:"+string(curlRotAmt)+";"); 
						file_text_writeln(theFile);	
						
								
								
						// need control over this... 0-2 range. TODO
						
				}
			
			
#endregion


			
// SAVE GENERATED MAPS
		
				file_text_close(theFile);
			
				//keyboard_clear(vk_enter) // clear Enter
if !projectOnly // saving the project only?
	{

		if rgbMask_GenState==2 
			{
			keyboard_key_press(vk_enter) // auto Enter	
			file = get_save_filename("Maps|*.png", prjName+"_RGBMask");
			surface_save(canvas,file)
			keyboard_clear(vk_enter)
			}

		if mask_GenState==2 
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Mask");
			surface_save(mask_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
			

		if ao_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_AO");
			surface_save(ao_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
						
		
		if color_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Color");
			surface_save(color_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
			
		if depth_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Depth");
			surface_save(depth_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
			
		if flow_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Flow");
			surface_save(flow_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
						
		
		if frizz_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Frizz");
			surface_save(frizz_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
			
		if id_GenState==2
			{
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_ID");
			surface_save(id_canvas,file)
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}

			
		if norm_GenState==2
			{
			//editme
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
					var normSprite=sprite_create_from_surface(tNormsurf,0,0,4096,4096,0,0,0,0)
				
				//keyboard_key_press(vk_enter) // auto Enter
			keyboard_key_press(vk_enter) // auto Enter
			file = get_save_filename("Maps|*.png", prjName+"_Normal");
			sprite_save(normSprite,0,file)
			sprite_flush(normSprite)
			sprite_delete(normSprite)
			}
			if moreHairs==0
				{
				keyboard_key_press(vk_enter) // auto Enter
				file = get_save_filename("Maps|*.png", prjName+"_Normal");
				surface_save(nm_canvas,file)
				}
			
			//keyboard_key_press(vk_enter) // auto Enter
			keyboard_clear(vk_enter)
			}
			
		
	}//end of save project Only
/*

#region
// MAIN FILE SAVE MODE
	if rgbMask_GenState==2
		{
			var file;
			file = get_save_filename("RGBMaskMap|*.png", "RGBMask_");

		if file != ""
		    {
			surface_save(canvas,file)
			}
		}
		
	if doNorm and  norm_GenState==2// save the ID canvas if active
		{
			var file2;
			file2 = get_save_filename("NormalMap|*.png", "NORM_");
		
		if file2 != ""
			{
				surface_save(nm_canvas,file2)
			}
		}

	
	if doID and id_GenState==2// save the ID canvas if active
		{
			
			var file3;
			file3 = get_save_filename("IDMap|*.png", "ID_");
		
		if file3 != ""
			{
				surface_save(id_canvas,file3)
			}
		}
		
		
	if doColor and color_GenState==2 // save the color canvas if active
		{
		
				var file4;
		file4 = get_save_filename("ColorMap|*.png", "COLOR_");
		

			if file4 != ""
				{
					surface_save(color_canvas,file4)
				}
		}
		
	if doMask and mask_GenState==2 // save the mask canvas if active
		{
		
				var file5;
		file5 = get_save_filename("MaskMap|*.png", "MASK_");
		

			if file5 != ""
				{
					surface_save(mask_canvas,file5)
				}
		}
		
	if doDepth and depth_GenState==2// save the mask canvas if active
		{
		
				var file6;
		file6 = get_save_filename("DepthMap|*.png", "DEPTH_");
		

			if file6 != ""
				{
					surface_save(depth_canvas,file6)
				}
		}
		
		if doFlow and flow_GenState==2 // save the flow canvas if active
		{

				var file7;
		file7 = get_save_filename("FlowMap|*.png", "FLOW_");
		

			if file7 != ""
				{
					surface_save(flow_canvas,file7)
				}
		}
		
		if doAO and ao_GenState==2// save the flow canvas if active
		{
		
		var file8;
		file8 = get_save_filename("AOMap|*.png", "AO_");
		

			if file8 != ""
				{
					surface_save(ao_canvas,file8)
				}
		}
		
		
		if doFrizz and frizz_GenState==2// save the flow canvas if active
		{
		
		var file9;
		file9 = get_save_filename("FrizzMap|*.png", "FRIZZ_");
		

			if file9 != ""
				{
					surface_save(frizz_canvas,file9)
				}
		}
		// END main FILE SAVE MODE
		#endregion
		
		*/
		
		
	keyboard_key_release(ord("S")) // release key system
	keyboard_key_release(vk_enter)
	saving= false
projectOnly=false
			}
		}
		else
		{
				keyboard_key_release(ord("S")) // release key system
	keyboard_key_release(vk_enter)
	saving= false
		mouse_button=mb_left
	mouse_button=mb_left
	projectOnly=false
		}
	}
// do some fake clicks to restore window to be active
				keyboard_key_release(ord("S")) // release key system
	keyboard_key_release(vk_enter)
	saving= false
	mouse_button=mb_left
	mouse_button=mb_left
	projectOnly=false// reset
	if fullscreenMode==1 window_set_topmost(topMostMode) // reset back