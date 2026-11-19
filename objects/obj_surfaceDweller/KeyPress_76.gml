/// @description Key L - load a project file (legacy section)
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 76 = "L". Also fired by the load button in Draw_0,
//         which calls keyboard_key_press(ord("L")) then keyboard_key_release.
// DOES  : asks for a project .txt, then reads the LEGACY section of the file -
//         the part every version since 1.2x has written - into the globals and
//         the per-set arrays, and moves the three mixer paths to the saved points.
//
// THE FILE FORMAT, AND WHY ORDER MATTERS
//   Every line is "Description:value;". The description is for humans only:
//   analise() / analiseString() just take what is after the first ':'.
//   So this event reads BY POSITION: line N of the file goes to the Nth read
//   below. KeyPress_83 (S) writes the lines in exactly the same order.
//     - never insert, remove or reorder a read here without doing the same to
//       the write in KeyPress_83, or every later value shifts by one line
//     - a line that is read but whose assignment is commented out (doRGB etc.)
//       must STILL be read, to stay in step
//     - loops read 11 sets (0..10) because that is what the saver writes
//   Newer data is not added here at all. It goes in marker-headed blocks at the
//   end of the file (per-set colours, clumping, set extras) which Alarm 1 reads
//   on the next frame by searching for the marker text.
//   doAutoLoad() is the autosave's version of this reader; Autosave.txt has
//   extra lines, so the two are not interchangeable.
//
// SEQUENCE OF A LOAD
//   this event : clearOverrides() (which also schedules Alarm 1), read the
//                legacy section, loading=true .. false, v191ManualLoadOk
//   Step_0     : same frame - a pre-1.85 header makes it treat colours as global
//   Alarm 1    : next frame - colour / clump / extras blocks, pleaseGen, mainS
//                reset to the current header
//
// WRITES: almost every project setting; see the reads below. Also loading,
//         lastFileName, mainS, instr, *_GenState, pleaseGen, img,
//         pathLoad?x/y[], localUpdateSet, forceUpdate, v191ManualLoadOk.
// CHECK : theFile is opened below but this event never calls file_text_close()
//         on it (doAutoLoad does close its file).
// -----------------------------------------------------------------------------
//img=9


// some things need a little reset before loading
// Deselect every set first, so the loaded values land in the globals and Step_0
// does not route the loaded colours into whichever set happened to be selected.

for (nC=0;nC<12;nC++)
				{							
					setSelected[nC]=0 //deactivate all
					setSelectedID=-1 // reset
					
				}

if canLoad
	{
	// a topmost window would sit in front of the file dialog
	if fullscreenMode==1 window_set_topmost(0) // temp disable

			// Blocking dialog. Returns "" if cancelled; then theFile keeps
			// whatever it held before and the else-branch at the bottom runs.
			// theFile starts as "" in Create_0, which is what the != "" test
			// below is really checking on a first load.
			fileCustom = get_open_filename_ext("HSD_Project|*.txt", prjName,"","Please load a HSD file.");
		if fileCustom!="" theFile = file_text_open_read(fileCustom);

		if theFile != ""  and fileCustom!=""//okay to open
		    {
				loading=true
// initial line
			//var theFile = file_text_open_read(fileCustom);
			
			// clear overrides
			// clearOverrides() zeroes every per-set override flag and refills
			// the per-set value arrays from the CURRENT globals (the outgoing
			// project's - hence the V1.91 re-seed at the bottom of this event).
			// Because loading is true it also sets v185LoadRecoveryPending and
			// alarm[1]=1, which is what runs Alarm 1 next frame.
					clearOverrides()

			// lastFileName is how Alarm 1 knows which file to re-open.
			lastFileName=fileCustom
		// LINE 1: the header. mainS now holds the FILE's header, so
		// real(string_copy(mainS,46,4)) below is the file's version (e.g. 1.36).
		// Alarm 1 puts the current header back afterwards.
		mainS=file_text_read_string(theFile);
			file_text_readln(theFile);
			
			
// instruction line			
		instr=file_text_read_string(theFile);
			file_text_readln(theFile);
			
			// VARIABLES TO LOAD
			#region
// main variables	
//var o=obj_surfaceDweller
var tString="" ;// temp string for reading and analizing

		    tString=file_text_read_string(theFile);//,"Seed:"+string(o.seedVal)+";");
			file_text_readln(theFile);
			seedVal=analise(tString) 

// here are the rest of the variables to load
// main variables
// Each three-line group below is: read the line, step to the next line, store.
// analise() returns the number after ':'. Line order from here: Blur, IDmode,
// then nine "do<Map>" flags and "Current map" which are read and DISCARDED (the
// assignments are commented out so a load does not switch maps on or change
// the view), then the flow-map flags, scale/fade, the five colours, and on.

		    tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			var_blur_amount=analise(tString) 

			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			idMode=analise(tString) 
					
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doRGB=analise(tString) 
				
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doNorm=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doColor=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doMask=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doID=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doDepth=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doFrizz=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doFlow=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//doAO=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			//img=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			dirFlipX=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			dirFlipY=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			dirBlue=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			dirHue=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			scaleIn=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			scaleOut=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			fadeIn=analise(tString) 
			
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			fadeOut=analise(tString) 
			
			// colors are 24bit values
			// Stored as six hex digits RRGGBB (written by dec_to_hex_save).
			// analiseString() strips the trailing ';', then each pair of digits
			// is converted with hex_to_dec and recombined with make_color_rgb.
			// Order: background, variation A, variation B, root, tip.
			// These are the LEGACY colour fields. In a 1.85+ file they hold
			// whatever the UI was showing at save time (possibly a selected
			// set's colours); the true globals and per-set colours come from the
			// colour block Alarm 1 reads, which overrides the four strand
			// colours set here. colrBack is only stored here.
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tString=analiseString(tString); // 6A5034
			colrBack=make_color_rgb(hex_to_dec(string_copy(tString,1,2)) ,  hex_to_dec(string_copy(tString,3,2)) ,  hex_to_dec(string_copy(tString,5,2)) ); // make color
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tString=analiseString(tString); // 6A5034
			customColVarA=make_color_rgb(hex_to_dec(string_copy(tString,1,2)) ,  hex_to_dec(string_copy(tString,3,2)) ,  hex_to_dec(string_copy(tString,5,2)) ); // make color
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tString=analiseString(tString); // 6A5034
			customColVarB=make_color_rgb(hex_to_dec(string_copy(tString,1,2)) ,  hex_to_dec(string_copy(tString,3,2)) ,  hex_to_dec(string_copy(tString,5,2)) ); // make color
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tString=analiseString(tString);
			// issue with this becoming green ... saving issue?
			customRootCol=make_color_rgb(hex_to_dec(string_copy(tString,1,2)) ,  hex_to_dec(string_copy(tString,3,2)) ,  hex_to_dec(string_copy(tString,5,2)) ); // make color
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tString=analiseString(tString); // 6A5034;
			
			customTipCol=make_color_rgb(hex_to_dec(string_copy(tString,1,2)) ,  hex_to_dec(string_copy(tString,3,2)) ,  hex_to_dec(string_copy(tString,5,2)) ); // make color
	//	newColor=customTipCol;
					if bkCol_active==1 {newColor=colrBack}
					if ColA_active==1 {newColor=customColVarA}
					if ColB_active==1 {newColor=customColVarB}
					if RootCol_active==1 {newColor=customRootCol}
					if TipCol_active==1 {newColor=customTipCol}

			
			
			// NOTE: "var sets" is a LOCAL that hides the instance variable sets
			// (which is 10) for the rest of this event. Here it means "number
			// of sets in the file" = 11. Two lines per set: count, length.
			var sets = 11
			for (s=0;s<sets;s++) // support up to 10 sets potentaill greater later on
				{
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				strandCountOverride[s]=analise(tString)
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				strandLengthOverride[s]=analise(tString) // perfect way to analise our readIn
				
				}


			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			minScale=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			maxScale=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			colorMode=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tapering=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			root=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tip=analise(tString) 
			

			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			lifeVariant=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			rootPosition=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tipPosition=analise(tString) 
			

			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			wavyness=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			strands=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			diminish=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			maxStrands=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			distancings=analise(tString) 
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			setDistance=analise(tString) 
			
			
			// New Vars in V 1.286
			// Three lines per set: X offset, Y offset, algorithm influence.
			var sets = 11
			for (s=0;s<sets;s++) // support up to 11 sets potentaill greater later on
				{
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				xOffset[s]=analise(tString) 
				
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				yOffset[s]=analise(tString) 
				
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				alogrithmInfluence[s]=analise(tString) 
				}


			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			minFreq=analise(tString)

			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			maxFreq=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			frizz=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer1=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer1_offset=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer2=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer2_offset=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer3=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			mixer3_offset=analise(tString)
			
			// fix 1 thickness ranges new in v1.33 - June16 2020
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			rootThick=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			tipThick=analise(tString)
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			thickVary=analise(tString)

			var sets = 11
			for (s=0;s<sets;s++) // support up to 10 sets potentaill greater later on
				{
				tString=file_text_read_string(theFile);
				file_text_readln(theFile);
				taperInfluence[s]=analise(tString)
				}

			// end fix 1 : Root+Tip thickness, Thick variation and Taper influences.
			
			// additional settings (7th July 2020)
			// PREVIEWER OPTI			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			maxPreviewStrandsPerSet=min(analise(tString),100) // V1.94 - the strand*/preRand* caches hold 100
			
			tString=file_text_read_string(theFile);
			file_text_readln(theFile);
			optimalStep=analise(tString)

			//FALLBACK incase older save:
			// PREVIEWER OPTI		
			if maxPreviewStrandsPerSet==0 or optimalStep==0
				{
				maxPreviewStrandsPerSet=8 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
				optimalStep=64 // for optimising the display update (16) higher is more optimised
				}
				
			// make genstates based on do's
			// The do* flags were NOT loaded (see above), so these are the map
			// tick-boxes as they are now. Any map that was finished (state 2)
			// drops to 1 "ticked, needs rendering" or 0 "off": the 4K canvases
			// still show the previous project until G is pressed.
			// pleaseGen resets the render pointers; img=9 returns to the previewer.

			ao_GenState=doAO
			color_GenState=doColor
			depth_GenState=doDepth
			flow_GenState=doFlow
			frizz_GenState=doFrizz
			id_GenState=doID
			mask_GenState=doMask
			norm_GenState=doNorm
			rgbMask_GenState=doRGB
			pleaseGen=true
			img=9
			// new in V1.36 15th July 2020
						// save path points and reassign when loaded
		
			//if real(versionHSD)==1.36

			// MIXER PATH POINTS (files from 1.36 on). Version test: characters
			// 46-49 of the header are the version number, see Step_0.
			// 11 points for each of the three mixer paths A, B, C; two lines per
			// point (X then Y) = 66 lines. They go into pathLoad?x/y[] here and
			// are applied to editingPath[0..2] at the bottom of this event.
			// The reader assumes exactly 11 points per path. The saver writes
			// path_get_number() points, so the two only agree while each mixer
			// path has 11 points.
			if real(string_copy(mainS,46,4))>=1.36
			{
				
				{
				for (z1=0;z1<11;z1++)
					{
						tString=file_text_read_string(theFile);
						file_text_readln(theFile);
						pathLoadAx[z1]=real(analiseString(tString));
						tString=file_text_read_string(theFile);
						file_text_readln(theFile);
						pathLoadAy[z1]=real(analiseString(tString));
					}
				
				for (z2=0;z2<11;z2++)
					{
					tString=file_text_read_string(theFile);
						file_text_readln(theFile);
						pathLoadBx[z2]=real(analiseString(tString));
						tString=file_text_read_string(theFile);
						file_text_readln(theFile);
						pathLoadBy[z2]=real(analiseString(tString));
					}
			
				for (z3=0;z3<11;z3++)
					{

								{
								tString=file_text_read_string(theFile);
								file_text_readln(theFile);
								pathLoadCx[z3]=real(analiseString(tString));
								tString=file_text_read_string(theFile);
								file_text_readln(theFile);
								pathLoadCy[z3]=real(analiseString(tString));
								}
						
					}
				
				
				}
			}// limit this loading to V1.36
			
					// load in the new override stuff if the version is correct
			//if real(string_copy(mainS,46,4))>1.43
			// From here the reader uses MARKER LINES instead of the version
			// number, but still in a fixed order: it reads the next line and
			// compares it with the expected marker. If it matches, the section
			// follows; if not, the section is skipped (and that line is used up).
			// Marker 1 - note the ';' is part of the text being compared.
			// Section: for each set 0..10, 26 lines in this order:
			//   8 override flags  (length, count, taper, waviness, freq min,
			//                      freq max, variation, spacing)
			//   6 mixer flags     (amount 1, offset 1, amount 2, offset 2, ...)
			//   6 mixer values    (amounts 1-3, then offsets 1-3)
			//   6 other values    (taper, waviness, freq min, freq max,
			//                      variation, spacing)
			// then one line: the global length.
				{
					tString=file_text_read_string(theFile);
					file_text_readln(theFile);
					if tString="***VERSION 1.5 and later specific;"
						{
							// access v1.43 specific vars

						// load the new override stuff
						for (b=0;b<11;b++)
							{
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setLengthOverrode[b]=real(analiseString(tString));
							
			
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setCountOverrode[b]=real(analiseString(tString));
					
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setTaperOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setWaveynessOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setWaveFreqMinOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setWaveFreqMaxOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setVariOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setSpacingOverrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerAmt1Overrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerOfs1Overrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerAmt2Overrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerOfs2Overrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerAmt3Overrode[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							setMixerOfs3Overrode[b]=real(analiseString(tString));
							
							//---
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerAdj1[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerAdj2[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerAdj3[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerOffsetAdj1[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerOffsetAdj2[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetMixerOffsetAdj3[b]=real(analiseString(tString));
							
							//---
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetTaperAdj[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetWavynessAdj[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetWaveFreqMinAdj[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetWaveFreqMaxAdj[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetVariAdj[b]=real(analiseString(tString));
							
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							strandSetSpaceAdj[b]=real(analiseString(tString));
						
							
							}
			
							// finally load actual global length
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							length=real(analiseString(tString));
							
							// version 1.53 specific...
							// Marker 2 (no ';' on this one). Section: per set,
							// Y jitter range then its override flag; then the
							// global yRanRange.
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							// detects "" if there is nothing on that line.
							if tString=="V1.53 - 21st Nov 2020" // version check for new vars
								{
									// read specific vars
									// root variation
									for (set=0;set<11;set++)
										{	
										tString=file_text_read_string(theFile);
										file_text_readln(theFile);
										strandYRanRange[set]=real(analiseString(tString));
										tString=file_text_read_string(theFile);
										file_text_readln(theFile);
										strandYRanRangeOverrode[set]=real(analiseString(tString));
										}
										//read global value
										tString=file_text_read_string(theFile);
										file_text_readln(theFile);
										yRanRange=real(analiseString(tString));
								}
								
								// version 1.55 specific...
							// Marker 3. Section: moreHairs (0 single strand /
							// 1 multi strand mode) and curlRotAmt (micro curl).
							// This is the last thing the legacy reader takes.
							// Everything after it in the file belongs to Alarm 1.
							tString=file_text_read_string(theFile);
							file_text_readln(theFile);
							// detects "" if there is nothing on that line.
							if tString=="V1.55 - 28th Dec 2020" // version check for new vars
								{
									// read specific vars
									// root variation
								
										tString=file_text_read_string(theFile);
										file_text_readln(theFile);
										moreHairs=real(analiseString(tString));
		
										tString=file_text_read_string(theFile);
										file_text_readln(theFile);
										curlRotAmt=real(analiseString(tString));
								}
								
							

			
						}
						
						
						
						
						
				}


			
#endregion

			v191ManualLoadOk=1

			}
			else
			{
				// filename was no good
							//	keyboard_key_release(ord("L")) // release key system
	keyboard_key_release(vk_enter)
	loading= false
		mouse_button=mb_left
	mouse_button=mb_left
	projectOnly=false//
			}

	} // end of canLoad
	if fullscreenMode==1 window_set_topmost(1) // reenable

// TIDY-UP, runs whether or not a file was loaded.
// The file dialog swallows the key-up, so GameMaker would go on believing L (and
// Enter, used to confirm the dialog) is held; release them by hand.
// "mouse_button=mb_left" is the old trick noted in KeyPress_83 as a fake click
// to give the window focus back.
// loading goes back to false HERE, in the same frame. Alarm 1 does not depend on
// it: it runs off v185LoadRecoveryPending.

	keyboard_key_release(ord("L"))
	loading= false
		mouse_button=mb_left
	mouse_button=mb_left
	projectOnly=false//
canLoad=true

//img=9 // reset to previewer

//if string_copy(mainS,46,4)=="1.36"  // limit to this version
// APPLY THE MIXER PATHS. Moves points 0..10 of the three live mixer paths to the
// pathLoad?x/y[] positions (speed 100). Runs on every L press, cancelled or not;
// on a cancel pathLoad* still holds the last loaded (or Create_0 default) points,
// so any unsaved edits made in the path editor since then are put back.
// previewUpdate() notices path changes through previewPathHash().
			{
			for (a=0;a<11;a++)
				{
				path_change_point(editingPath[0],a,pathLoadAx[a],pathLoadAy[a],100)
				path_change_point(editingPath[1],a,pathLoadBx[a],pathLoadBy[a],100)
				path_change_point(editingPath[2],a,pathLoadCx[a],pathLoadCy[a],100)
				}
			}

// V1.91 - clearOverrides() ran BEFORE this event parsed the file, so the per-set
// arrays were seeded from the OUTGOING globals. Re-seed them from the globals the
// file just supplied, otherwise every render path keeps using the old project's
// thickness / fade / noise while the UI shows the new values.
// (doAutoLoad does this correctly already; only the manual L path needed it.)
// Gated on an actual load: pressing L and then cancelling the file dialog must
// not force a full rebuild, which would flash the whole preview blank.
if v191ManualLoadOk==1
	{
	for (var _reseedSet=0;_reseedSet<maxSets;_reseedSet++)
		{
		if setThickMinOverrode[_reseedSet]==0  setThickMinAdj[_reseedSet]=minScale
		if setThickMaxOverrode[_reseedSet]==0  setThickMaxAdj[_reseedSet]=maxScale
		if setTipThickOverrode[_reseedSet]==0  setTipThickAdj[_reseedSet]=tipThick
		if setRootThickOverrode[_reseedSet]==0 setRootThickAdj[_reseedSet]=rootThick
		if setThickVaryOverrode[_reseedSet]==0 setThickVaryAdj[_reseedSet]=thickVary
		if setFadeInOverrode[_reseedSet]==0    setFadeInAdj[_reseedSet]=fadeIn
		if setFadeOutOverrode[_reseedSet]==0   setFadeOutAdj[_reseedSet]=fadeOut
		if setNoiseAmtOverrode[_reseedSet]==0  setNoiseAmtAdj[_reseedSet]=noiseAmt
		if setNoiseFreqOverrode[_reseedSet]==0 setNoiseFreqAdj[_reseedSet]=noiseFreq
		}
	// Clumping is restored by Alarm 1 (clumpReadFile) once the file is closed.
	localUpdateSet=-1
	forceUpdate=1
	previewCanvasComplete=0
	v191ManualLoadOk=0
	}
			
				
			