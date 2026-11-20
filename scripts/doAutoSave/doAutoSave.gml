// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// doAutoSave()  -  write the whole project to Autosave.txt
//
// WHAT IT IS
//   The silent project saver. No dialog, no maps: just the settings, as a text
//   file. Runs in obj_surfaceDweller's scope (it reads the settings through
//   "o.", which is obj_surfaceDweller itself, and sets saving / autosaving on
//   the caller).
//
// WHERE THE FILE GOES
//   "Autosave.txt" has no folder, so GameMaker puts it in the game's save
//   area:  %LOCALAPPDATA%\HairStrand_Designer\Autosave.txt
//   It is overwritten in full every time. doAutoLoad() reads it back.
//
// WHEN IT RUNS
//   - doMainStep: every left-mouse release (once the splash has been answered)
//   - obj_surfaceDweller End Step (Step_2): every left-mouse release as well,
//     so one release normally writes the file twice. Harmless, just redundant.
//   - obj_surfaceDweller Alarm 1: a few frames after a colour / colour-override
//     change (noticed by objects/g Begin Step), and straight after a manual
//     S-key project save so the autosave matches it.
//   Nothing is written when demoMode==1, autosave==0 or canSave is false.
//
// FILE FORMAT  (one "Description:value;" per line)
//   The loader does NOT look at the description. Everything down to the end
//   of the V1.91 block is read back BY LINE POSITION, so the order written
//   here must be exactly the order doAutoLoad() reads. One line added, removed
//   or moved in the middle shifts every value after it into the wrong variable.
//
//   In order (line counts in brackets):
//     header "... - Version1.96.0 - ..."   (1)  loader takes the version from
//                                               characters 46-49 of this line
//     instruction line (instr)             (1)
//     Seed, Blur, IDmode                   (3)
//     doRGB doNorm doColor doMask doID doDepth doFrizz doFlow doAO  (9)
//     Current map                          (1)
//     Flow Flip X, Flip Y, Blue, Hue       (4)
//     Global Scale In/Out, Fade In/Out     (4)
//     Background + 4 strand colours, HEX   (5)  RRGGBB via dec_to_hex_save
//     Strand Count / Length Override       (2 x 11 sets)
//     MinScale ... Set Distances           (15)
//     X offset, Y offset, algorithm infl.  (3 x 11 sets)
//     Wave freq min/max, Frizz, Mixer 1-3 amount+offset   (9)
//     Root / Tip Thickness, Thickness Variation           (3)
//     Taper Influence                      (11)
//     maxPreviewStrandsPerSet, optimalStep (2)
//     mixer path points, X then Y          (2 x 11 points x 3 paths)
//     "***VERSION 1.5 and later specific;" (1)  marker, loader checks the text
//     per-set override flags + values      (26 x 11 sets)
//     length                               (1)
//     "V1.53 - 21st Nov 2020"              (1)  then Root Jitter: 2 x 11, + yRanRange
//     "V1.55 - 28th Dec 2020"              (1)  then MultiStrandMode, MicroCurl
//     "V1.70 - 21st Mar 2023"              (1)  then per-set seeds: 2 x 11
//     "V1.71 - 28th Jan 2024"              (1)  then per-set thick min/max: 4 x 11
//     "V1.85 - Per Set Colour Overrides"   (1)  then per-set colours: 8 x 11
//     "V1.90 - Noise"                      (1)  then noiseAmt, noiseFreq
//     "V1.91 - Per Set Thickness Fade Noise" (1) then 14 x 11
//     "V1.96 - Clumping" block (clumpWriteBlock in clumpTools) - found by
//       scanning for its marker, so it is the only part that is position-free.
//
//   Only 11 sets (0-10) are saved, even though the arrays hold maxSets (15).
//
// HOW THIS DIFFERS FROM A MANUAL PROJECT FILE (S key, KeyPress_83)
//   The manual saver writes the same lines but stops after the V1.55 block.
//   Alarm 1 then appends a V1.85 colour block (with 4 extra "global..." lines
//   at its start), the clump block, and "V1.96 - Set Extras" (projectExtras).
//   The autosave has no Set Extras block because it already carries those
//   values in its own V1.70 / V1.71 / V1.90 / V1.91 sections.
//
// ADDING A NEW SAVED VALUE
//   Safest: add it to a marker-found block (clumpWriteBlock/clumpReadFile or
//   extrasWriteBlock/extrasReadFile, or a new block written after them and
//   read in Alarm 1). Those are read by name, so old files keep loading.
//   If it has to go in the positional part, add it at the very END of this
//   function's writes (before the clump block), under a new "Vx.xx - Name"
//   marker line, and add the matching read in the same place in doAutoLoad()
//   guarded by the version number and !file_text_eof. Then decide whether the
//   manual save needs it too (KeyPress_83 / KeyPress_76 / projectExtras),
//   and add it to obj_copy if it is a per-set value.
//   Bump the version text in the header line when the format changes; the
//   same string is also in Create_0, objects/g and Alarm_1.
//
// SIDE EFFECTS
//   Uses the instance variables s, a and set as loop counters (not "var"), so
//   they are overwritten in the caller. fileCustom is left as "Autosave.txt",
//   which is why Alarm 1 / canvasCheck keep the manual save path separately
//   in v185ManualSavePath.
// =============================================================================
function doAutoSave(){
/// @description Insert description here
// You can write your code in this editor


if canSave and demoMode==0 and autosave==1 // demo builds never write a project; autosave=1 is set in Create
	{
	autosaving=1 // tells objects/g and Alarm 1 that file IO is in progress
	//quicksave
	//
	
	//
	//saveNameId=string(current_second)+string(current_minute)+string(current_day)+string(current_month)+string(current_year)
	
	// are these used??

	// ?

// ALL AT ONCE SAVING... problems getting al the characters needed for the naming (lowercase and numbers only by the looks of it)
	//if rgbMask_GenState==2
	//if !projectOnly {prjName=get_string("Project Name","HSD_");} // no need for a project name call
	if prjName=="" prjName="HSD" // ensure save proceeds
	if prjName!="" 
	{
		//if instance_exists(obj_save) {instance_destroy(obj_save)}
		//	instance_create_depth(0,0,-1000,obj_save)
			
			
			fileCustom = "Autosave.txt" // no folder = the save area, %LOCALAPPDATA%\HairStrand_Designer


		if fileCustom != ""
		    {
				saving=true
// initial line
			theFile = file_text_open_write(fileCustom);
			
// Autosaves are always written as the current project format.
// The loader reads the version as real(string_copy(header,46,4)), i.e. the
// "1.96" straight after "Version". Do not change the text before that number
// or its length, or every version check in doAutoLoad / KeyPress_76 breaks.
file_text_write_string(theFile,"Hair Strand Designer - Project File - Version1.97.0 - 20thNov2026 (C) Robert Ramsay");
			file_text_writeln(theFile);
			
// instruction line			
		file_text_write_string(theFile,string(instr));
			file_text_writeln(theFile);
			
			// VARIABLES TO SAVE
			#region
// main variables
// FROM HERE ON, ORDER MATTERS: doAutoLoad() reads these lines back by position.
// The text before the colon is only a label for humans; the loader ignores it.
// The nine do* lines and "Current map" are written but the loader skips over
// them (its assignments are commented out), so which maps are ticked and which
// map is on screen are NOT restored. They must still be written: they hold
// the line positions for everything after them.
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
			
			// Save the true global colours. custom* may be temporarily showing a
			// selected/rendering set while the rest of the legacy code is running.
			file_text_write_string(theFile,"Variation Tone 1 (HEX):"+string(dec_to_hex_save(o.globalColVarA))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation Tone 2 (HEX):"+string(dec_to_hex_save(o.globalColVarB))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Root Color (HEX):"+string(dec_to_hex_save(o.globalRootCol))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Tip Color (HEX):"+string(dec_to_hex_save(o.globalTipCol))+";"); 
			file_text_writeln(theFile);
			
			// "var sets" is a local that hides the instance variable sets for the
			// rest of this function. 11 is the fixed number of sets in the file
			// format; the loader's loops are hard-coded to 11 too.
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
			file_text_write_string(theFile,"maxPreviewStrandsPerSet:"+string(o.maxPreviewStrandsPerSet)+";"); 
				file_text_writeln(theFile);	
			
			file_text_write_string(theFile,"optimalStep:"+string(o.optimalStep)+";"); 
				file_text_writeln(theFile);	
				
			// save path points and reassign when loaded
			// editingPath[0..2] are the three mixer curves (edited in Room_PathEditing).
			// 11 points each, X line then Y line. The loader only reads this
			// section when the header version is 1.36 or later.

			for (a=0;a<11;a++) // V1.95 - the loader reads exactly 11 per path; path_get_number() would desync the entire file if a path ever gained or lost a point
				{
					var pathX=string(path_get_point_x(o.editingPath[0],a))
					var pathY=string(path_get_point_y(o.editingPath[0],a))
					file_text_write_string(theFile,"editingPath[0].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[0].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
				
			for (a=0;a<11;a++) // V1.95
				{
					var pathX=string(path_get_point_x(o.editingPath[1],a))
					var pathY=string(path_get_point_y(o.editingPath[1],a))
					file_text_write_string(theFile,"editingPath[1].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[1].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
				
			for (a=0;a<11;a++) // V1.95
				{
					var pathX=string(path_get_point_x(o.editingPath[2],a))
					var pathY=string(path_get_point_y(o.editingPath[2],a))
					file_text_write_string(theFile,"editingPath[2].X:"+string(pathX)+";"); 
					file_text_writeln(theFile);	
					file_text_write_string(theFile,"editingPath[2].Y:"+string(pathY)+";"); 
					file_text_writeln(theFile);					
				}
			
			// save in the new override stuff if the version is correct
			// The loader compares this whole line, including the ";", and skips
			// EVERYTHING below it if it does not match. Do not reword it.
			// Each set then gets 26 lines: 14 "...Overrode" flags (1 = this set has
			// its own value) followed by the 12 per-set values themselves.
			//if real(verString)>=150
				{
					file_text_write_string(theFile,"***VERSION 1.5 and later specific"+";");
					file_text_writeln(theFile);		
					
					
					for (a=0;a<11;a++)
						{

						file_text_write_string(theFile,"setLengthOverrode["+string(a)+"]:"+string(o.setLengthOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setCountOverrode["+string(a)+"]:"+string(o.setCountOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setTaperOverrode["+string(a)+"]:"+string(o.setTaperOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveynessOverrode["+string(a)+"]:"+string(o.setWaveynessOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveFreqMinOverrode["+string(a)+"]:"+string(o.setWaveFreqMinOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setWaveFreqMaxOverrode["+string(a)+"]:"+string(o.setWaveFreqMaxOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setVariOverrode["+string(a)+"]:"+string(o.setVariOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setSpacingOverrode["+string(a)+"]:"+string(o.setSpacingOverrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt1Overrode["+string(a)+"]:"+string(o.setMixerAmt1Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs1Overrode["+string(a)+"]:"+string(o.setMixerOfs1Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt2Overrode["+string(a)+"]:"+string(o.setMixerAmt2Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs2Overrode["+string(a)+"]:"+string(o.setMixerOfs2Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerAmt3Overrode["+string(a)+"]:"+string(o.setMixerAmt3Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"setMixerOfs3Overrode["+string(a)+"]:"+string(o.setMixerOfs3Overrode[a])+";"); 
						file_text_writeln(theFile);	
						
						//---
						
						file_text_write_string(theFile,"strandSetMixerAdj1["+string(a)+"]:"+string(o.strandSetMixerAdj1[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerAdj2["+string(a)+"]:"+string(o.strandSetMixerAdj2[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerAdj3["+string(a)+"]:"+string(o.strandSetMixerAdj3[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj1["+string(a)+"]:"+string(o.strandSetMixerOffsetAdj1[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj2["+string(a)+"]:"+string(o.strandSetMixerOffsetAdj2[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetMixerOffsetAdj3["+string(a)+"]:"+string(o.strandSetMixerOffsetAdj3[a])+";"); 
						file_text_writeln(theFile);	
						
						//---
						
						file_text_write_string(theFile,"strandSetTaperAdj["+string(a)+"]:"+string(o.strandSetTaperAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWavynessAdj["+string(a)+"]:"+string(o.strandSetWavynessAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWaveFreqMinAdj["+string(a)+"]:"+string(o.strandSetWaveFreqMinAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetWaveFreqMaxAdj["+string(a)+"]:"+string(o.strandSetWaveFreqMaxAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetVariAdj["+string(a)+"]:"+string(o.strandSetVariAdj[a])+";"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"strandSetSpaceAdj["+string(a)+"]:"+string(o.strandSetSpaceAdj[a])+";"); 
						file_text_writeln(theFile);	
						

						}
						
						// finally save actual global length
						file_text_write_string(theFile,"length:"+string(o.length)+";"); 
						file_text_writeln(theFile);	
						
						// New in 1.53:
						// The "Vx.xx - ..." lines from here down are section labels.
						// The loader reads each one as a line in sequence (it does not
						// search for them), and for V1.53 / V1.55 / V1.85 / V1.90 / V1.91
						// it also checks the exact text. Keep them word for word.
						file_text_write_string(theFile,"V1.53 - 21st Nov 2020");
						file_text_writeln(theFile);	
						
						// save vars
						for (set=0;set<11;set++)
							{	
							file_text_write_string(theFile,"strandYRanRange["+string(set)+"]:"+string(o.strandYRanRange[set])+";"); 
							file_text_writeln(theFile);	
						
							file_text_write_string(theFile,"strandYRanRangeOverrode["+string(set)+"]:"+string(o.strandYRanRangeOverrode[set])+";"); 
							file_text_writeln(theFile);	
							}
							//global
						file_text_write_string(theFile,"yRanRange:"+string(o.yRanRange)+";"); 
						file_text_writeln(theFile);	
						
						
						// New in 1.55
						file_text_write_string(theFile,"V1.55 - 28th Dec 2020"); 
						file_text_writeln(theFile);	
						
						file_text_write_string(theFile,"MultiStrandMode:"+string(o.moreHairs)+";"); 
						file_text_writeln(theFile);	
								
						file_text_write_string(theFile,"MultiStrandMicroCurl:"+string(o.curlRotAmt)+";"); 
						file_text_writeln(theFile);	
						
		

					// Per-set seeds: randomOverride = this set uses its own seed,
					// randomSeedVal = that seed. string() keeps only 2 decimals here;
					// the manual save's Set Extras block writes 6 (see projectExtras).
					file_text_write_string(theFile,"V1.70 - 21st Mar 2023");
					file_text_writeln(theFile);
					for (set=0;set<11;set++)
							{	
							file_text_write_string(theFile,"randomOverride["+string(set)+"]:"+string(o.randomOverride[set])+";"); 
							file_text_writeln(theFile);	
						
							file_text_write_string(theFile,"randomSeedVal["+string(set)+"]:"+string(o.randomSeedVal[set])+";"); 
							file_text_writeln(theFile);	
							}
							
							
							// new in 1.71 save min and max thicknesses
									file_text_write_string(theFile,"V1.71 - 28th Jan 2024"); 
		file_text_writeln(theFile);	
					for (set=0;set<11;set++)
							{	
								
							file_text_write_string(theFile,"setThickMinOverrode["+string(set)+"]:"+string(o.setThickMinOverrode[set])+";"); 
							file_text_writeln(theFile);	
						
							file_text_write_string(theFile,"setThickMinAdj["+string(set)+"]:"+string(o.setThickMinAdj[set])+";"); 
							file_text_writeln(theFile);	
							
							file_text_write_string(theFile,"setThickMaxOverrode["+string(set)+"]:"+string(o.setThickMaxOverrode[set])+";"); 
							file_text_writeln(theFile);	
						
							file_text_write_string(theFile,"setThickMaxAdj["+string(set)+"]:"+string(o.setThickMaxAdj[set])+";"); 
							file_text_writeln(theFile);	
							}
							
							// V1.85 - per-set colour overrides. Stored as native colour
							// integers so save/load is lossless and simple.
							// Unlike a manual save, the autosave block has NO four
							// "global..." lines after the marker: it starts at set 0.
							// Alarm 1 re-reads this block after every load and accepts
							// both layouts.
							file_text_write_string(theFile,"V1.85 - Per Set Colour Overrides");
							file_text_writeln(theFile);
							for (set=0;set<11;set++)
								{
								file_text_write_string(theFile,"setColVarAOverrode["+string(set)+"]:"+string(o.setColVarAOverrode[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setColVarA["+string(set)+"]:"+string(o.setColVarA[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setColVarBOverrode["+string(set)+"]:"+string(o.setColVarBOverrode[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setColVarB["+string(set)+"]:"+string(o.setColVarB[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setRootColOverrode["+string(set)+"]:"+string(o.setRootColOverrode[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setRootCol["+string(set)+"]:"+string(o.setRootCol[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setTipColOverrode["+string(set)+"]:"+string(o.setTipColOverrode[set])+";");
								file_text_writeln(theFile);
								file_text_write_string(theFile,"setTipCol["+string(set)+"]:"+string(o.setTipCol[set])+";");
								file_text_writeln(theFile);
								}

							// V1.90 - global NOISE amount + frequency. Appended at
							// the very end so every older project file still loads.
							file_text_write_string(theFile,"V1.90 - Noise");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"noiseAmt:"+string(o.noiseAmt)+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"noiseFreq:"+string(o.noiseFreq)+";");
							file_text_writeln(theFile);

							// V1.91 - per-set thickness / fade / noise overrides.
							// Appended after the V1.90 block, so a 1.90 project
							// simply hits EOF here and keeps its globals.
							file_text_write_string(theFile,"V1.91 - Per Set Thickness Fade Noise");
							file_text_writeln(theFile);
							for (set=0;set<11;set++)
								{
							file_text_write_string(theFile,"setTipThickOverrode["+string(set)+"]:"+string(o.setTipThickOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setTipThickAdj["+string(set)+"]:"+string(o.setTipThickAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setRootThickOverrode["+string(set)+"]:"+string(o.setRootThickOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setRootThickAdj["+string(set)+"]:"+string(o.setRootThickAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setThickVaryOverrode["+string(set)+"]:"+string(o.setThickVaryOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setThickVaryAdj["+string(set)+"]:"+string(o.setThickVaryAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setFadeInOverrode["+string(set)+"]:"+string(o.setFadeInOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setFadeInAdj["+string(set)+"]:"+string(o.setFadeInAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setFadeOutOverrode["+string(set)+"]:"+string(o.setFadeOutOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setFadeOutAdj["+string(set)+"]:"+string(o.setFadeOutAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setNoiseAmtOverrode["+string(set)+"]:"+string(o.setNoiseAmtOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setNoiseAmtAdj["+string(set)+"]:"+string(o.setNoiseAmtAdj[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setNoiseFreqOverrode["+string(set)+"]:"+string(o.setNoiseFreqOverrode[set])+";");
							file_text_writeln(theFile);
							file_text_write_string(theFile,"setNoiseFreqAdj["+string(set)+"]:"+string(o.setNoiseFreqAdj[set])+";");
							file_text_writeln(theFile);
								}

							// V1.96 - clumping. Self-describing block, found by its
							// marker on load (clumpReadFile), so its position does
							// not matter to the positional loader above it.
							// A new positional section must be written ABOVE this line.
							with (o) clumpWriteBlock(other.theFile);


				}
			
			
			
#endregion


			
// SAVE GENERATED MAPS
		
				file_text_close(theFile);
			

		

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
		file5 = get_save_filename("MaskMap|*.png", "Mask_");
		

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
		
		
	// Left over from the manual saver this was copied from: forces S and Enter
	// up so a held key cannot re-trigger a save, and clears the "project only"
	// request flag used by KeyPress_83.
	keyboard_key_release(ord("S")) // release key system
	keyboard_key_release(vk_enter)
	saving= false
	projectOnly=false
			}
		}
		else
		{
			saving= false
			/*
		keyboard_key_release(ord("S")) // release key system
		keyboard_key_release(vk_enter)
		
		mouse_button=mb_left
		mouse_button=mb_left
		projectOnly=false
		*/
		}
	}
// do some fake clicks to restore window to be active
// (the fake clicks are in the commented-out block below; only the flags remain)
// Always cleared, even when nothing was written, because doMainStep sets
// autosaving=1 before calling and would otherwise never autosave again.
saving= false
autosaving=0
/*
		keyboard_key_release(ord("S")) // release key system
		keyboard_key_release(vk_enter)
		saving= false
		mouse_button=mb_left
		mouse_button=mb_left
		projectOnly=false// reset
		*/
}