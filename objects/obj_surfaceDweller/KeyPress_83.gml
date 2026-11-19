/// @description Key S - save project file and export the finished maps
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 83 = "S". Also fired by two buttons in Draw_0 via
//         keyboard_key_press(ord("S")): the export button (top right, sets
//         projectOnly=false first) and the project-save button.
// DOES  : 1. asks for a project name (skipped when projectOnly is true)
//         2. asks where to save, writes the LEGACY section of the project .txt
//         3. unless projectOnly, exports every finished map (GenState 2) as PNG,
//            one save dialog per map
//         Disabled in the demo (demoMode) and while canSave is false (a render
//         is running: G sets canSave=false, doMainStep sets it true at the end).
//
// WHAT THIS EVENT DOES NOT WRITE
//   Per-set colours, clumping, noise, per-set thickness / fade / noise overrides
//   and per-set seeds are NOT written here. Alarm 1 appends them as marker-headed
//   blocks next frame, after this event has closed the file. Object g latches
//   that request (v185ManualSavePending, alarm[1]=2) in its Begin Step and S key
//   events. So a complete project file = this event + Alarm 1.
//
// FILE FORMAT: one "Description:value;" per line, read back BY POSITION by
//   KeyPress_76 (L). The order of the writes below IS the file format. Do not
//   insert, remove or reorder a line without making the same change in
//   KeyPress_76, and prefer adding new data to a marker block instead.
//   doAutoSave() is a separate, longer writer for Autosave.txt.
//
// READS : everything it saves (through "o", which is this same instance), the
//         nine *_GenState flags, moreHairs, projectOnly, prjName.
// WRITES: prjName, fileCustom, theFile, file, saving, projectOnly.
// -----------------------------------------------------------------------------

if canSave and demoMode==0
	{
		// a topmost window would sit in front of the dialogs; restored on the last line
		if fullscreenMode==1 window_set_topmost(0)
	//quicksave
	//
	
	//
	//saveNameId=string(current_second)+string(current_minute)+string(current_day)+string(current_month)+string(current_year)
	
	// are these used??

	// ?

// ALL AT ONCE SAVING... problems getting al the characters needed for the naming (lowercase and numbers only by the looks of it)
	//if rgbMask_GenState==2
	// prjName is the default file name for the project and the prefix of every
	// exported map (prjName+"_Color" etc.). Cancelling the name box returns ""
	// and abandons the whole save (the else-branch near the bottom).
	if !projectOnly {prjName=get_string("Project Name","HSD_");} // no need for a project name call
	
	if prjName!="" 
	{
		//if instance_exists(obj_save) {instance_destroy(obj_save)}
		//	instance_create_depth(0,0,-1000,obj_save)
			
			
			fileCustom = get_save_filename_ext("HSD_Project|*.txt", prjName,"","Please save to a directory outside of the Application.");
			

		if fileCustom != ""
		    {
				// saving=true pauses the renderer (doMainStep tests !saving) and
				// the colour autosave check in object g while the file is open.
				saving=true
// initial line
			// open_write replaces any existing file of that name.
			theFile = file_text_open_write(fileCustom);

		// LINE 1: header. The loaders take the format version from it (the four
		// characters after "Version"). Object g's Begin Step has already set
		// mainS to the current header this frame.
		file_text_write_string(theFile,string(mainS));
			file_text_writeln(theFile);
			
// instruction line			
		file_text_write_string(theFile,string(instr));
			file_text_writeln(theFile);
			
			// VARIABLES TO SAVE
			#region
// main variables
// "o" is this object itself (this code was lifted from obj_save, where it had to
// reach across). o.x and plain x are the same variable here; both styles appear.
// LINES 3..: seed, blur, ID mode, the nine map tick-boxes, the current view.
// The loader reads the nine do* lines and "Current map" but ignores them.
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
			
			// The five colours as six hex digits RRGGBB (dec_to_hex_save).
			// CAREFUL: customColVarA/B, customRootCol and customTipCol are the
			// UI-facing colours. If a set is selected when S is pressed these
			// four lines hold THAT SET's colours, not the project globals.
			// That is why Alarm 1 appends the true global* values and every
			// set's colours in the V1.85 block, and why the loader lets that
			// block win. Only a pre-1.85 build would rely on these four lines.
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
			
			// "var sets" is a local = 11 sets written (0..10). It hides the
			// instance variable sets (10) for the rest of this event.
			// Count and length are written for every set whether or not the
			// set's override flag is on; the flags come later in the file.
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
			// The three mixer curves, two lines per point (X then Y), path 0 then
			// 1 then 2. This writes however many points each path has, but the
			// loader (KeyPress_76) always reads exactly 11 per path. They agree
			// only while every mixer path has 11 points; if the path editor ever
			// allows adding or removing points, every line after this section
			// would be read out of step.

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
			// MARKER 1. The loader compares the whole line, including the ';',
			// so this text must not change. After it, for each set 0..10, 26
			// lines: 8 override flags, 6 mixer override flags, 6 mixer values,
			// 6 other per-set values - in the order written below.
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
						// MARKER 2 (exact text, no ';'). Per-set root Y jitter
						// range + its override flag, then the global value.
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
						// MARKER 3 (exact text). Multi-strand mode and micro curl.
						// Last section written by this event; Alarm 1's blocks
						// are appended after it.
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
// The project file is closed first. Alarm 1 re-opens it in append mode next
// frame to add the colour / clump / extras blocks.
// Then, unless only the project was wanted, each map whose GenState is 2
// (rendered and finished) is written as a 4096x4096 PNG. A map that is ticked
// but not rendered (state 1) or off (state 0) is skipped silently - "my map did
// not export" usually means it was not re-rendered after a change.
// One Save dialog per map, default name prjName+"_<Map>". keyboard_key_press
// (vk_enter) just before each dialog is the "auto Enter" trick meant to accept
// the default name without a click; keyboard_clear(vk_enter) undoes it after.
// The returned name is not checked: a cancelled dialog gives "" and
// surface_save is still called with it.

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
			// NORMAL MAP has two export paths:
			//  moreHairs==1 (multi strand): nm_canvas holds a height/bump
			//    picture (drawn with spr_stranderBUMP), so it is run through
			//    shd_normal into tNormsurf to become a real normal map, copied
			//    to a temporary sprite, saved, and the sprite freed.
			//  moreHairs==0 (single strand): nm_canvas already holds normal-map
			//    colours (spr_nm on a 128,128,255 base) and is saved directly.
			// "var normSprite" here is a local and hides the instance variable
			// of the same name from Create_0.
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


	// End of a completed save. The dialogs swallow key-ups, so S and Enter are
	// released by hand or GameMaker would think they are still held (and S
	// would not register as "pressed" next time). The same clean-up is repeated
	// in the cancel branch and once more unconditionally at the very end.
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