// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function clearOverrides(){

// Both manual load and autoload set loading=true before calling this function.
// Alarm 1 performs the authoritative V1.85 colour restore on the next frame,
// after the legacy loader has finished and closed the project file.
if variable_instance_exists(id,"loading") and loading
	{
	v185LoadRecoveryPending=1
	alarm[1]=1
	}

for (a=0;a<20;a++)
	{
	//
	setSelected[a]=0 // no sets are sected for overrides. 1.43
	setSelectedID=-1 // the ID of the selected 1.43
	// override flags (so we know what should be globally affected)
	// can be locally reset or all reset later
	setLengthOverrode[a]=0 // has this been overrode?
	setCountOverrode[a]=0 // has this been overrode? // yes defaults!
	setTaperOverrode[a]=0 // has this been overrode?
	setWaveynessOverrode[a]=0 // has this been overrode?
	setWaveFreqMinOverrode[a]=0 // has this been overrode?
	setWaveFreqMaxOverrode[a]=0 // has this been overrode?
	setVariOverrode[a]=0 // has this been overrode?
	setSpacingOverrode[a]=0 // has this been overrode?
	setVariOverrode[a]=0
	strandYRanRangeOverrode[a]=0
	
	// per-set colour override flags
	setColVarAOverrode[a]=0
	setColVarBOverrode[a]=0
	setRootColOverrode[a]=0
	setTipColOverrode[a]=0

	}
	
for (s=0;s<maxSets;s++) // support up to 32 sets maybe greater later on
	{
	//strandCountOverride[s]=25
	//strandLengthOverride[s]=3800
	
	setMixerAmt1Overrode[s]=0 // amounts and offsets ... (array based) can get rid of non array based?
	setMixerOfs1Overrode[s]=0 // 
	setMixerAmt2Overrode[s]=0 // 
	setMixerOfs2Overrode[s]=0 // 
	setMixerAmt3Overrode[s]=0 // 
	setMixerOfs3Overrode[s]=0 // 


	//new in 1.43
	// mixer readjusters
	strandSetMixerAdj1[s]=10 // default 10
	strandSetMixerAdj2[s]=2 // default 2
	strandSetMixerAdj3[s]=1 // default 1
	strandSetMixerOffsetAdj1[s]=0
	strandSetMixerOffsetAdj2[s]=0
	strandSetMixerOffsetAdj3[s]=0
	
	//other override values
	strandSetTaperAdj[s]=10 // default 10
	strandSetWavynessAdj[s]=16 // default 16
	strandSetWaveFreqMinAdj[s]=1 // default 1
	strandSetWaveFreqMaxAdj[s]=10 // default 10
	strandSetVariAdj[s]=6 // default 6
	strandSetSpaceAdj[s]=21 // distancings=21
	
	
	}
}