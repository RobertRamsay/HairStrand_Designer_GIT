// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// clearOverrides()  -  put every set back to "follow the global sliders"
//
// Runs in obj_surfaceDweller's scope. Called only at the start of a project
// load (KeyPress_76 for the L key, and doAutoLoad), BEFORE the file is parsed,
// so nothing from the previous project is left in a set the new file does
// not mention.
//
// WHAT IT DOES
//   - clears every per-set "...Overrode" flag (0 = set follows the global)
//   - deselects all sets (setSelected[], setSelectedID=-1)
//   - puts the older per-set values (mixers, taper, wave, variation, spacing)
//     back to fixed defaults
//   - copies the CURRENT globals into the V1.91 per-set thickness/fade/noise
//     values, and resets clumping per set (clumpResetSet)
//   It does not touch per-set colours (the loaders / Alarm 1 handle those),
//   per-set seeds, X/Y offsets, the per-set count/length values (only their
//   flags are cleared) or the globals themselves.
//
// LOAD SIDE EFFECT (easy to miss)
//   When loading==true this also sets v185LoadRecoveryPending and alarm[1]=1.
//   That is what makes obj_surfaceDweller Alarm 1 re-open the file next frame
//   and read the marker blocks (V1.85 colours, V1.96 Clumping, V1.96 Set
//   Extras). So a loader MUST set loading=true before calling this, or those
//   blocks are never read.
//
// ORDER TRAP
//   During a load this runs before the new globals have been read, so the
//   V1.91 arrays are seeded from the OLD project's globals. doAutoLoad
//   re-seeds them itself after reading; KeyPress_76 does it at its end
//   (v191ManualLoadOk); extrasReadFile does it again if its block is present.
//
// Uses the instance variables a and s as loop counters.
// =============================================================================
function clearOverrides(){

// Both manual load and autoload set loading=true before calling this function.
// Alarm 1 performs the authoritative V1.85 colour restore on the next frame,
// after the legacy loader has finished and closed the project file.
if variable_instance_exists(id,"loading") and loading
	{
	v185LoadRecoveryPending=1
	alarm[1]=1
	}

// 20 is more than any set count in use: maxSets is 15 and files hold sets 0-10.
// The mixer flags are cleared in the second loop below.
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
	setVariOverrode[a]=0 // (repeat of the line two above; harmless)
	strandYRanRangeOverrode[a]=0
	
	// per-set colour override flags
	setColVarAOverrode[a]=0
	setColVarBOverrode[a]=0
	setRootColOverrode[a]=0
	setTipColOverrode[a]=0

	// V1.91 - thickness / fade / noise per-set override flags
	setThickMinOverrode[a]=0
	setThickMaxOverrode[a]=0
	setTipThickOverrode[a]=0
	setRootThickOverrode[a]=0
	setThickVaryOverrode[a]=0
	setFadeInOverrode[a]=0
	setFadeOutOverrode[a]=0
	setNoiseAmtOverrode[a]=0
	setNoiseFreqOverrode[a]=0

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
	// Fixed numbers, not the current globals (unlike the V1.91 block below).
	// A V1.5+ project file overwrites all of these straight afterwards.
	strandSetTaperAdj[s]=10 // default 10
	strandSetWavynessAdj[s]=16 // default 16
	strandSetWaveFreqMinAdj[s]=1 // default 1
	strandSetWaveFreqMaxAdj[s]=10 // default 10
	strandSetVariAdj[s]=6 // default 6
	strandSetSpaceAdj[s]=21 // distancings=21

	// V1.91 - seed the new per-set arrays from the current globals so a project
	// saved before 1.91 still renders exactly as it did.
	setThickMinAdj[s]=minScale
	setThickMaxAdj[s]=maxScale
	setTipThickAdj[s]=tipThick
	setRootThickAdj[s]=rootThick
	setThickVaryAdj[s]=thickVary
	setFadeInAdj[s]=fadeIn
	setFadeOutAdj[s]=fadeOut
	setNoiseAmtAdj[s]=noiseAmt
	setNoiseFreqAdj[s]=noiseFreq

	// V1.96 - clump overrides off, values from the globals. A load replaces
	// all of this from the file's clump block (Alarm 1, clumpReadFile).
	clumpResetSet(s)

	}
}