/// @failsafe
// check for canvas errors and do a flash game load





if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x,mouse_y,0,0,1920,20) { 
	moveWindow=1
	wmx=mouse_x;wmy=mouse_y}
	
if moveWindow==1 window_set_position(

display_mouse_get_x()-(wmx*screenScaleX), display_mouse_get_y()-(wmy*screenScaleY)



)

if mouse_check_button_pressed(mb_right) and point_in_rectangle(mouse_x,mouse_y,0,0,1920,20) {window_set_position(0,0) }

if mouse_check_button_released(mb_left) moveWindow=0



// surface checking is crap via functions, do it all in code here

if !surface_exists(canvas) or
	!surface_exists(ao_canvas) or
	!surface_exists(nm_canvas) or
	!surface_exists(mask_canvas) or
	!surface_exists(color_canvas) or
	!surface_exists(flow_canvas) or
	!surface_exists(id_canvas) or
	!surface_exists(frizz_canvas) or
	!surface_exists(depth_canvas) or
	!surface_exists(blurSurface) or
	!surface_exists(tNormsurf)
	{
	audio_play_sound(Sound1,0,0)
	
	// killSurfaces() frees everything safely then recreates and clears all canvases
	killSurfaces()
	
// SETUP CANVASES
#region
	ex=1300;
	ey=800;
	slx=ex;
	sly=ey;
	count++
	infoMsg="Count:"+string(count)
	
if count>1 
	{
	var regenFile=file_text_open_write("RegenCheck.txt")
		{
		file_text_write_string(regenFile,"Regen");
		file_text_writeln(regenFile);
		}
		file_text_close(regenFile)
	
	game_restart()
	}


	// color history
				colorHistoryPointer=0
				for (n=0;n<24;n++)
					{
					hCol[n]=c_black
					}
#endregion
// END OF SETUP
	}
		



gameTick360++
if gameTick360>360 gameTick360=0



debugMsg="Begin Step"
smallTip="" // clear the tooltip
tickytime+=0.025 // text box caret blink - quarter of the old speed
if tickytime>=1 tickytime=0
/*
if !surface_exists(canvas) or !surface_exists(nm_canvas) or !surface_exists(mask_canvas) or !surface_exists(depth_canvas) or
!surface_exists(color_canvas) or !surface_exists(flow_canvas) or !surface_exists(id_canvas) or !surface_exists(ao_canvas)
	{
	// do a flash restart
	
	game_end()
	// if any of the surfaces lose focus

	//game_load(game_id) // later this will be a project load
	//
	}
	
	*/
		//	seedVal=random_get_seed() // get seed value having both of these functions getting and setting will lock the hairs randomness
		if !loading random_set_seed(seedVal) // deliberate seed value
		

			
			// inc /dec maxPreviewStrandsPerSet
if (mouse_wheel_up() ) or (keyboard_check_pressed(vk_pageup) && !keyboard_check(vk_control))
	{		
		if optimalStep>2 optimalStep-=8
		//if maxPreviewStrandsPerSet<60 maxPreviewStrandsPerSet++
	}
	
if (mouse_wheel_down() ) or (keyboard_check_pressed(vk_pagedown) && !keyboard_check(vk_control))
	{
		if optimalStep<256 optimalStep+=8
		//if maxPreviewStrandsPerSet>1 maxPreviewStrandsPerSet--
	}
	

			
if mouse_check_button_pressed(mb_left)  // edit mixers clicking mixer edit mixers select 
	{
	if point_in_rectangle(mouse_x,mouse_y,1040,820,1190,840)
		{
		g.pathToEditID=0;room_goto(Room_PathEditing)
		}
	if point_in_rectangle(mouse_x,mouse_y,1040,841,1190,869)
		{
		g.pathToEditID=1;room_goto(Room_PathEditing)
		}
	if point_in_rectangle(mouse_x,mouse_y,1040,869,1190,897)
		{
		g.pathToEditID=2;room_goto(Room_PathEditing)
		}
	
		
		if point_in_rectangle(mouse_x,mouse_y,3,1027,60,1051) // fast
		{
			maxPreviewStrandsPerSet=20 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
			optimalStep=80 // for optimising the display update (16) higher is more optimised
			dynamicRes=0
		}
		
		if point_in_rectangle(mouse_x,mouse_y,66,1027,120,1051) // med
		{
			maxPreviewStrandsPerSet=50 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
			optimalStep=40 // for optimising the display update (16) higher is more optimised
			dynamicRes=0
		}
		
		if point_in_rectangle(mouse_x,mouse_y,124,1027,180,1051) // slow
		{
			maxPreviewStrandsPerSet=100 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
			optimalStep=10 // for optimising the display update (16) higher is more optimised
			dynamicRes=0
		}
		
		if point_in_rectangle(mouse_x,mouse_y,182,1027,237,1051) // dyna
		{
			maxPreviewStrandsPerSet=30
			dynamicRes=1
		}
		
	}
	
	// dynamic res
	if mouse_check_button(mb_left) and readyToCheckAutoloads==1 and dynamicRes==1
		{
			optimalStep=120
			
		}

// dynamic optimal setp
	if keyboard_check_pressed(vk_f2) motionDetectMode=1-motionDetectMode

//topmost mode toggle
	if keyboard_check_pressed(vk_f3) and fullscreenMode==1 {topMostMode=1-topMostMode;window_set_topmost(topMostMode);}

// reset currently seelcted overrides
	if keyboard_check_pressed(vk_f4)
		{
			if setSelectedID!=-1
				{
				
			
				// override flags (so we know what should be globally affected)
				// can be locally reset or all reset later
				setLengthOverrode[setSelectedID]=0 // has this been overrode?
				setCountOverrode[setSelectedID]=0 // has this been overrode? // yes defaults!
				setTaperOverrode[setSelectedID]=0 // has this been overrode?
				setWaveynessOverrode[setSelectedID]=0 // has this been overrode?
				setWaveFreqMinOverrode[setSelectedID]=0 // has this been overrode?
				setWaveFreqMaxOverrode[setSelectedID]=0 // has this been overrode?
				setVariOverrode[setSelectedID]=0 // has this been overrode?
				setSpacingOverrode[setSelectedID]=0 // has this been overrode?
				setVariOverrode[setSelectedID]=0
				strandYRanRangeOverrode[setSelectedID]=0
				
				setMixerAmt1Overrode[setSelectedID]=0 // amounts and offsets ... (array based) can get rid of non array based?
				setMixerOfs1Overrode[setSelectedID]=0 // 
				setMixerAmt2Overrode[setSelectedID]=0 // 
				setMixerOfs2Overrode[setSelectedID]=0 // 
				setMixerAmt3Overrode[setSelectedID]=0 // 
				setMixerOfs3Overrode[setSelectedID]=0 // 
				
				// the amounts need to reflect global values now
				strandCountOverride[setSelectedID]=strands
				strandLengthOverride[setSelectedID]=length
				strandSetMixerAdj1[setSelectedID]=mixer1 // default 10
				strandSetMixerAdj2[setSelectedID]=mixer2  // default 2
				strandSetMixerAdj3[setSelectedID]=mixer3  // default 1
				strandSetMixerOffsetAdj1[setSelectedID]=mixer1_offset
				strandSetMixerOffsetAdj2[setSelectedID]=mixer2_offset
				strandSetMixerOffsetAdj3[setSelectedID]=mixer3_offset
				
				strandSetTaperAdj[setSelectedID]=tapering // default 10
				strandSetWavynessAdj[setSelectedID]=wavyness // default 16
				strandSetWaveFreqMinAdj[setSelectedID]=minFreq // default 1
				strandSetWaveFreqMaxAdj[setSelectedID]=maxFreq // default 10
				strandSetVariAdj[setSelectedID]=lifeVariant // default 6
				strandSetSpaceAdj[setSelectedID]=distancings // distancings=21
				strandYRanRange[setSelectedID]=yRanRange // jitterY

				// V1.91 - the rest of the notched rows. setThickMin/Max were
				// already overridable but were never cleared here.
				setThickMinOverrode[setSelectedID]=0
				setThickMaxOverrode[setSelectedID]=0
				setTipThickOverrode[setSelectedID]=0
				setRootThickOverrode[setSelectedID]=0
				setThickVaryOverrode[setSelectedID]=0
				setFadeInOverrode[setSelectedID]=0
				setFadeOutOverrode[setSelectedID]=0
				setNoiseAmtOverrode[setSelectedID]=0
				setNoiseFreqOverrode[setSelectedID]=0

				setThickMinAdj[setSelectedID]=minScale
				setThickMaxAdj[setSelectedID]=maxScale
				setTipThickAdj[setSelectedID]=tipThick
				setRootThickAdj[setSelectedID]=rootThick
				setThickVaryAdj[setSelectedID]=thickVary
				setFadeInAdj[setSelectedID]=fadeIn
				setFadeOutAdj[setSelectedID]=fadeOut
				setNoiseAmtAdj[setSelectedID]=noiseAmt
				setNoiseFreqAdj[setSelectedID]=noiseFreq

				}

		}
		
if keyboard_check_pressed(vk_f5)
		{
		for (setToReset=0;setToReset<maxSets;setToReset++)
			{
				// can be locally reset or all reset later
				setLengthOverrode[setToReset]=0 // has this been overrode?
				setCountOverrode[setToReset]=0 // has this been overrode? // yes defaults!
				setTaperOverrode[setToReset]=0 // has this been overrode?
				setWaveynessOverrode[setToReset]=0 // has this been overrode?
				setWaveFreqMinOverrode[setToReset]=0 // has this been overrode?
				setWaveFreqMaxOverrode[setToReset]=0 // has this been overrode?
				setVariOverrode[setToReset]=0 // has this been overrode?
				setSpacingOverrode[setToReset]=0 // has this been overrode?
				setVariOverrode[setToReset]=0
				strandYRanRangeOverrode[setToReset]=0
				
				setMixerAmt1Overrode[setToReset]=0 // amounts and offsets ... (array based) can get rid of non array based?
				setMixerOfs1Overrode[setToReset]=0 // 
				setMixerAmt2Overrode[setToReset]=0 // 
				setMixerOfs2Overrode[setToReset]=0 // 
				setMixerAmt3Overrode[setToReset]=0 // 
				setMixerOfs3Overrode[setToReset]=0 // 
				
				// the amounts need to reflect global values now
				strandCountOverride[setToReset]=strands
				strandLengthOverride[setToReset]=length
				strandSetMixerAdj1[setToReset]=mixer1 // default 10
				strandSetMixerAdj2[setToReset]=mixer2  // default 2
				strandSetMixerAdj3[setToReset]=mixer3  // default 1
				strandSetMixerOffsetAdj1[setToReset]=mixer1_offset
				strandSetMixerOffsetAdj2[setToReset]=mixer2_offset
				strandSetMixerOffsetAdj3[setToReset]=mixer3_offset
				
				strandSetTaperAdj[setToReset]=tapering // default 10
				strandSetWavynessAdj[setToReset]=wavyness // default 16
				strandSetWaveFreqMinAdj[setToReset]=minFreq // default 1
				strandSetWaveFreqMaxAdj[setToReset]=maxFreq // default 10
				strandSetVariAdj[setToReset]=lifeVariant // default 6
				strandSetSpaceAdj[setToReset]=distancings // distancings=21
				strandYRanRange[setToReset]=yRanRange // jitterY

				// V1.91 - the rest of the notched rows
				setThickMinOverrode[setToReset]=0
				setThickMaxOverrode[setToReset]=0
				setTipThickOverrode[setToReset]=0
				setRootThickOverrode[setToReset]=0
				setThickVaryOverrode[setToReset]=0
				setFadeInOverrode[setToReset]=0
				setFadeOutOverrode[setToReset]=0
				setNoiseAmtOverrode[setToReset]=0
				setNoiseFreqOverrode[setToReset]=0

				setThickMinAdj[setToReset]=minScale
				setThickMaxAdj[setToReset]=maxScale
				setTipThickAdj[setToReset]=tipThick
				setRootThickAdj[setToReset]=rootThick
				setThickVaryAdj[setToReset]=thickVary
				setFadeInAdj[setToReset]=fadeIn
				setFadeOutAdj[setToReset]=fadeOut
				setNoiseAmtAdj[setToReset]=noiseAmt
				setNoiseFreqAdj[setToReset]=noiseFreq
			}
		
		}
		
		/*
if keyboard_check_pressed(vk_tab) // the famouse randomise button
		{
		if setSelectedID==-1
			{
			for (setToReset=0;setToReset<32;setToReset++)
				{
					// can be locally reset or all reset later
				
					setLengthOverrode[setToReset]=1 // has this been overrode?
					setCountOverrode[setToReset]=1 // has this been overrode? // yes defaults!
					setTaperOverrode[setToReset]=1 // has this been overrode?
					setWaveynessOverrode[setToReset]=1 // has this been overrode?
					setWaveFreqMinOverrode[setToReset]=1 // has this been overrode?
					setWaveFreqMaxOverrode[setToReset]=1 // has this been overrode?
					setVariOverrode[setToReset]=1 // has this been overrode?
					setSpacingOverrode[setToReset]=1 // has this been overrode?
					setVariOverrode[setToReset]=1
					strandYRanRangeOverrode[setToReset]=1
				
					setMixerAmt1Overrode[setToReset]=1 // amounts and offsets ... (array based) can get rid of non array based?
					setMixerOfs1Overrode[setToReset]=1 // 
					setMixerAmt2Overrode[setToReset]=1 // 
					setMixerOfs2Overrode[setToReset]=1 // 
					setMixerAmt3Overrode[setToReset]=1 // 
					setMixerOfs3Overrode[setToReset]=1 // 
				
					// the amounts need to reflect global values now
					strandCountOverride[setToReset]=irandom(50)+20
					strandLengthOverride[setToReset]=irandom(2400)+1300
					strandSetMixerAdj1[setToReset]=irandom(40)// default 10
					strandSetMixerAdj2[setToReset]=irandom(40)  // default 2
					strandSetMixerAdj3[setToReset]=irandom(40)  // default 1
					strandSetMixerOffsetAdj1[setToReset]=irandom(40)
					strandSetMixerOffsetAdj2[setToReset]=irandom(40)
					strandSetMixerOffsetAdj3[setToReset]=irandom(40)
				
					strandSetTaperAdj[setToReset]=irandom(100)// default 10
					strandSetWavynessAdj[setToReset]=irandom(100) // default 16
					strandSetWaveFreqMinAdj[setToReset]=irandom(40) // default 1
					strandSetWaveFreqMaxAdj[setToReset]=irandom(40) // default 10
					strandSetVariAdj[setToReset]=irandom(100) // default 6
					strandSetSpaceAdj[setToReset]=irandom(100) // distancings=21
					strandYRanRange[setToReset]=irandom(100) // jitterY
				}
			}
			else
			{
					setLengthOverrode[setSelectedID]=1 // has this been overrode?
					setCountOverrode[setSelectedID]=1 // has this been overrode? // yes defaults!
					setTaperOverrode[setSelectedID]=1 // has this been overrode?
					setWaveynessOverrode[setSelectedID]=1 // has this been overrode?
					setWaveFreqMinOverrode[setSelectedID]=1 // has this been overrode?
					setWaveFreqMaxOverrode[setSelectedID]=1 // has this been overrode?
					setVariOverrode[setSelectedID]=1 // has this been overrode?
					setSpacingOverrode[setSelectedID]=1 // has this been overrode?
					setVariOverrode[setSelectedID]=1
					strandYRanRangeOverrode[setSelectedID]=1
				
					setMixerAmt1Overrode[setSelectedID]=1 // amounts and offsets ... (array based) can get rid of non array based?
					setMixerOfs1Overrode[setSelectedID]=1 // 
					setMixerAmt2Overrode[setSelectedID]=1 // 
					setMixerOfs2Overrode[setSelectedID]=1 // 
					setMixerAmt3Overrode[setSelectedID]=1 // 
					setMixerOfs3Overrode[setSelectedID]=1 // 
				
					// the amounts need to reflect global values now
					strandCountOverride[setSelectedID]=irandom(50)+20
					strandLengthOverride[setSelectedID]=irandom(2400)+1300
					strandSetMixerAdj1[setSelectedID]=irandom(40)// default 10
					strandSetMixerAdj2[setSelectedID]=irandom(40)  // default 2
					strandSetMixerAdj3[setSelectedID]=irandom(40)  // default 1
					strandSetMixerOffsetAdj1[setSelectedID]=irandom(40)
					strandSetMixerOffsetAdj2[setSelectedID]=irandom(40)
					strandSetMixerOffsetAdj3[setSelectedID]=irandom(40)
				
					strandSetTaperAdj[setSelectedID]=irandom(100)// default 10
					strandSetWavynessAdj[setSelectedID]=irandom(100) // default 16
					strandSetWaveFreqMinAdj[setSelectedID]=irandom(40) // default 1
					strandSetWaveFreqMaxAdj[setSelectedID]=irandom(40) // default 10
					strandSetVariAdj[setSelectedID]=irandom(100) // default 6
					strandSetSpaceAdj[setSelectedID]=irandom(100) // distancings=21
					strandYRanRange[setSelectedID]=irandom(100) // jitterY
			}
		}		
		*/

// motion based
if o_motionDetector.distToMouse>20 and dynamicRes==1 and motionDetectMode==1
	{
		optimalStep=120 
	}
	else
	{
		if optimalStep>24 and dynamicRes==1 optimalStep-=12
	}
	
	
	