/// @failsafe
// check for canvas errors and do a flash game load
// -----------------------------------------------------------------------------
// EVENT : Begin Step (Step_1). First event of every frame for this object.
//         Frame order in GameMaker: Begin Step -> Alarms -> Key Press/Release
//         events -> Step (Step_0) -> End Step (Step_2) -> Draw (Draw_0) ->
//         Draw GUI (Draw_64). Object g also has a Begin Step that works on this
//         instance (save latch + colour autosave snapshot).
// DOES  : 1. window dragging by the top 20px strip
//         2. surface-loss failsafe (rebuild canvases, restart on the 2nd loss)
//         3. per-frame housekeeping: gameTick360, tooltip clear, caret blink,
//            re-seeding the random stream
//         4. preview quality controls (mouse wheel / PgUp / PgDn, FAST / MED /
//            SLOW / DYNA buttons, F2 motion mode)
//         5. mixer-name clicks -> path editor room
//         6. F3 topmost toggle, F4 reset selected set, F5 reset all sets
//            (the colour half of F4/F5 is in Step_0)
// WRITES: moveWindow/wmx/wmy, count, infoMsg, hCol[], colorHistoryPointer,
//         gameTick360, smallTip, tickytime, optimalStep, maxPreviewStrandsPerSet,
//         dynamicRes, motionDetectMode, topMostMode, and every per-set override
//         flag / value array on F4 / F5.
// -----------------------------------------------------------------------------

// WINDOW DRAG. A left press in the top strip (y 0..20) starts a drag and stores
// where in the window it was grabbed (wmx,wmy, room pixels). While dragging, the
// window follows the desktop mouse. screenScaleX/Y convert room pixels (1920x1080
// layout) to real screen pixels so the grab point stays under the cursor on 4K
// displays (the 1.682 fix noted in Create_0). Right click on the strip snaps the
// window to the top-left of the screen. Any left release ends the drag.

if mouse_check_button_pressed(mb_left) and point_in_rectangle(mouse_x,mouse_y,0,0,1920,20) { 
	moveWindow=1
	wmx=mouse_x;wmy=mouse_y}
	
if moveWindow==1 window_set_position(

display_mouse_get_x()-(wmx*screenScaleX), display_mouse_get_y()-(wmy*screenScaleY)



)

if mouse_check_button_pressed(mb_right) and point_in_rectangle(mouse_x,mouse_y,0,0,1920,20) {window_set_position(0,0) }

if mouse_check_button_released(mb_left) moveWindow=0



// surface checking is crap via functions, do it all in code here
// SURFACE-LOSS FAILSAFE. Surfaces live in video memory and Windows can discard
// them (minimise, lock screen, driver reset, VRAM pressure). If any of the
// eleven 4K canvases has gone:
//   1st time (count becomes 1): beep, killSurfaces() frees and re-creates them
//            all blank, the colour history is cleared. Rendered maps are lost.
//   2nd time (count becomes 2): write RegenCheck.txt and game_restart().
//            Create_0 finds that file on the way back up, deletes it, and sets
//            skipIntro=1 / firstTime=false so the splash is skipped;
//            doMainStep then loads Autosave.txt by itself and Draw_64 shows
//            the "Surfaces have been refreshed" notice.
// canvasCheck() (called from Step_2 and doMainStep) is the gentler version that
// re-creates only the missing surface; it also covers previewSurf[], which this
// test does not.

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
	ex=1300; // ex/ey/slx/sly: old slider anchor instance variables. Draw_0 now
	ey=800;  // declares its own local "var ex/ey/slx/sly" per slider, so these
	slx=ex;  // four are leftovers kept from the original setup block.
	sly=ey;
	count++ // number of surface losses this run; never reset except by restart
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
	// hCol[0..23] are the 24 visible history swatches; colorHistoryPointer is
	// the next slot to write (Draw_0 wraps it at 23). Slot 24 is the dummy
	// slot Step_0 uses to swallow hover-only writes.
				colorHistoryPointer=0
				for (n=0;n<24;n++)
					{
					hCol[n]=c_black
					}
#endregion
// END OF SETUP
	}
		



// PER-FRAME HOUSEKEEPING
// gameTick360: 0..360 frame counter. checkAndOffset() turns it into flashAlpha,
// the pulse of the SOLO marker.
gameTick360++
if gameTick360>360 gameTick360=0



debugMsg="Begin Step" // last event entered - shows where a crash/hang happened
// smallTip is rebuilt from scratch every frame: whatever the mouse is over
// (Draw_0, uiTips, doMainStep) writes it again later this frame.
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
		// Re-seed the global random stream every frame so anything that still
		// calls random() during the frame gets the same numbers each time and
		// the strands do not shimmer. Per-set seeds (randomSeedVal[]) are
		// applied on top of this inside updatePreRands and the renderer.
		// Skipped while a file is loading.
		if !loading random_set_seed(seedVal) // deliberate seed value


			
			// inc /dec maxPreviewStrandsPerSet
// PREVIEW QUALITY: optimalStep. Mouse wheel or PgUp/PgDn (without Ctrl) moves
// optimalStep in steps of 8: up = finer (smaller), down = coarser, max 256.
// (The old comment above mentions maxPreviewStrandsPerSet; those lines are
// commented out, only optimalStep moves.)
// NOTE: optimalStep was the point spacing of the pre-1.96 preview. The V1.96
// progressive preview (previewJob) draws with pvFullStep and its own coarse
// step, and does not read optimalStep. It is still saved/loaded and
// doHighlighting() sets it. maxPreviewStrandsPerSet IS still live: it caps the
// strands previewed per set (previewSetCount).
// CHECK: the lower guard is ">2", so from 8 one more notch gives 0.
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
	


// LEFT-CLICK HOTSPOTS handled in Begin Step
//  - the three mixer names (x 1040..1190, y 820..897): open Room_PathEditing on
//    that mixer. g.pathToEditID (0/1/2) tells the editor which of
//    editingPath[0..2] to load. g is a separate persistent helper object.
//  - the four preview-quality buttons on the bottom bar (y 1027..1051):
//      FAST  20 strands/set, step 80     MED   50 strands/set, step 40
//      SLOW 100 strands/set, step 10     DYNA  30 strands/set, dynamicRes=1
//    100 is the hard ceiling: the pre-random tables hold 100 strands per set.
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
	// DYNA mode: while the left button is held (i.e. something is being
	// dragged) force the coarsest step, 120. The block at the very bottom of
	// this event brings it back down 12 per frame once things are still.
	// readyToCheckAutoloads==1 just means "the splash has been dismissed".
	if mouse_check_button(mb_left) and readyToCheckAutoloads==1 and dynamicRes==1
		{
			optimalStep=120
			
		}

// dynamic optimal setp
// F2: motionDetectMode 0/1. When 1 (and DYNA is on) mouse MOVEMENT alone, not
// just a held button, coarsens the step - see the last block of this event.
	if keyboard_check_pressed(vk_f2) motionDetectMode=1-motionDetectMode

//topmost mode toggle
// F3 only does anything in the fullscreen build (fullscreenMode==1, set in
// Create_0). The load/save events drop topmost while a file dialog is open.
	if keyboard_check_pressed(vk_f3) and fullscreenMode==1 {topMostMode=1-topMostMode;window_set_topmost(topMostMode);}

// reset currently seelcted overrides
// -----------------------------------------------------------------------------
// F4 - RESET THE SELECTED SET (needs a set selected: setSelectedID 0..10)
// Every slider row has a pair of per-set arrays: an "...Overrode" flag (1 = this
// set has its own value) and a value array ("...Adj", strandCountOverride,
// strandLengthOverride, strandYRanRange). Reset = clear the flag AND copy the
// current global slider value back into the set's value, because the calc
// scripts always read the per-set value, never the global.
// The four colour overrides are reset by the F4 block in Step_0; clumping by
// clumpResetSet(). Per-set seeds (randomOverride / randomSeedVal) and the
// X/Y offsets are NOT reset here.
// previewUpdate() notices the changed values by itself (set signatures), so no
// redraw flag is needed.
// -----------------------------------------------------------------------------
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
				clumpResetSet(setSelectedID) // V1.96

				}

		}

// -----------------------------------------------------------------------------
// F5 - RESET EVERY SET. Same as F4, for all maxSets slots (0..14; only 0..10
// are visible). Keep the two lists in step: a new per-set override must be
// added to BOTH blocks, to clearOverrides(), and to the save/load code.
// -----------------------------------------------------------------------------
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
				clumpResetSet(setToReset) // V1.96
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
// DYNA step recovery. o_motionDetector is a marker that trails the mouse (lerp
// 0.2 per frame); distToMouse is the gap between them, so it is large while the
// mouse is moving quickly and falls to 0 when it stops. With F2 motion mode on, a move of more than 20 pixels jumps
// optimalStep to 120 (coarsest). Otherwise, in DYNA mode, optimalStep eases back
// down by 12 per frame until it is 24 or less.
if o_motionDetector.distToMouse>20 and dynamicRes==1 and motionDetectMode==1
	{
		optimalStep=120 
	}
	else
	{
		if optimalStep>24 and dynamicRes==1 optimalStep-=12
	}
	
	
	