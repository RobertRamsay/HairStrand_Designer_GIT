/// @description Insert description here
// You can write your code in this editor
//img=9


// some things need a little reset before loading

for (nC=0;nC<12;nC++)
				{							
					setSelected[nC]=0 //deactivate all
					setSelectedID=-1 // reset
					
				}

if canLoad
	{
	if fullscreenMode==1 window_set_topmost(0) // temp disable
			
			fileCustom = get_open_filename_ext("HSD_Project|*.txt", prjName,"","Please load a HSD file.");
		if fileCustom!="" theFile = file_text_open_read(fileCustom);

		if theFile != ""  and fileCustom!=""//okay to open
		    {
				loading=true
// initial line
			//var theFile = file_text_open_read(fileCustom);
			
			// clear overrides
					clearOverrides()
					
			lastFileName=fileCustom
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
			maxPreviewStrandsPerSet=analise(tString)
			
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


	keyboard_key_release(ord("L"))
	loading= false
		mouse_button=mb_left
	mouse_button=mb_left
	projectOnly=false//
canLoad=true

//img=9 // reset to previewer

//if string_copy(mainS,46,4)=="1.36"  // limit to this version
			{
			for (a=0;a<11;a++)
				{
				path_change_point(editingPath[0],a,pathLoadAx[a],pathLoadAy[a],100)
				path_change_point(editingPath[1],a,pathLoadBx[a],pathLoadBy[a],100)
				path_change_point(editingPath[2],a,pathLoadCx[a],pathLoadCy[a],100)
				}
			}
			
				
			