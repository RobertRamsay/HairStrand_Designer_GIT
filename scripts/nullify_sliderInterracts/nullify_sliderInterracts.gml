// -----------------------------------------------------------------------------
// nullify_sliderInterracts()  -  let go of every slider
//
// Each slider has a "latch": slider_interract_<name> goes true when the mouse
// is pressed on its track, and while it is true (and the button is held) the
// slider follows the mouse even if the pointer leaves the track.
// This drops all the latches. Runs in obj_surfaceDweller's scope.
//
// Called from Create (which is also what first creates these variables) and
// from Draw_0 immediately before a slider sets its own latch, so only one
// slider can be dragging at a time.
//
// ADDING A SLIDER: add its latch here. If it is missing, the variable does
// not exist until the slider is first clicked (a crash when Draw_0 reads it),
// and it will not be released when another slider is grabbed.
//
// The three arrays at the bottom are per-set controls, one latch per set.
// Uses the instance variable a as its loop counter.
// -----------------------------------------------------------------------------
function nullify_sliderInterracts() {
	slider_interract_rootPosition=false;
	slider_interract_diminish=false;
	slider_interract_strands=false;
	slider_interract_distancings=false;
	slider_interract_setDistancings=false;
	slider_interract_wavyness=false;
	slider_interract_minFreq=false;
	slider_interract_maxFreq=false;
	slider_interract_tapering=false;
	slider_interract_lifeVariant=false;
	slider_interract_minScale=false;
	slider_interract_maxScale=false;
	slider_interract_fadeIn=false;
	slider_interract_fadeOut=false;
	slider_interract_noiseAmt=false;  // V1.90 NOISE
	slider_interract_noiseFreq=false; // V1.90 NOISE
	slider_interract_clump=[false,false,false,false]; // V1.96 CLUMPING  (0 Amount, 1 Count, 2 Start, 3 Scatter)
	slider_interract_frizz=false;
	slider_interract_length=false;
	slider_interract_mixer1=false;
	slider_interract_mixer1_offset=false;
	slider_interract_mixer2=false;
	slider_interract_mixer2_offset=false;
	slider_interract_mixer3=false;
	slider_interract_mixer3_offset=false;
	slider_interract_tipPosition=false;
	slider_interract_tipThick=false;
	slider_interract_rootThick=false;
	slider_interract_thickVary=false;
	slider_interract_yRanRange=false;
	// color sliders
	slider_interract_redHue=false; // Angry Hugh
	slider_interract_grnSat=false; // Alien Satellite
	slider_interract_bluVal=false; // Cold Vally
	

	for (a=0;a<maxSets;a++)
		{
			slider_interract_strandXOffset[a]=false;  // reset this array
			slider_interract_alogrithmInfluence[a]=false;  // reset this array
			slider_interract_taperInfluence[a]=false; // reset this array
		}
	
	


}
