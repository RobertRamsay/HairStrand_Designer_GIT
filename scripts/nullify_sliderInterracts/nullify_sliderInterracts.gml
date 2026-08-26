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
