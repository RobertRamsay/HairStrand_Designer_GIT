// Script assets have changed for v2.3.0 see
/// @updatePreRands(value)
/// @param something
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// updatePreRands - builds the PRE-RANDOM TABLES
//
// Every random per-strand value (position, length, thickness, wave, depth ...)
// is rolled HERE, once, into tables indexed [set, strand]: 11 sets x 100
// strands. The preview (doCalc, called from previewDrawStrands) and the final
// render (doMainStep) both just read the tables, which is the reason strand 37
// of set 4 looks the same in the preview, in the render, and after a reload.
//
// ARGUMENT   -1 = rebuild all 11 sets.   0..10 = rebuild that one set.
//
// CALLED BY  Create_0 (-1), doAutoLoad (-1), and preRandsRefresh() in previewJob
//            (one set), which doMainStep runs every step and which only calls
//            this for a set whose inputs changed.
//            If a new slider is added that feeds a table below, add it to
//            preRandInputSig() in previewJob too, or the table will not rebuild
//            when that slider moves.
//
// THE TWO BRANCHES MUST STAY IDENTICAL. The "-1" branch and the single-set
// branch are the same code written twice (loop variable e versus c). A set must
// come out the same whichever branch built it, so any change has to be made in
// both.
//
// RANDOM STREAM ORDER - DO NOT REORDER, INSERT OR REMOVE DRAWS.
// Each set starts from random_set_seed(randomSeedVal[set]) and then takes its
// numbers in this fixed order:
//     1 draw            preRandLifeVariant
//     then per strand, 100 times:
//       Amp, Spacing, Life (thrown away, kept as a place-holder), Freq, YY,
//       RootRange, Root (two draws), StrandDecision, StraggleChoice, Depth,
//       DepthAdd, and in Multi Strand mode only: SubSprite, AngChoice, Curling
//     then per strand, 100 times:
//       Life (the one that is used), ThickBase
// Adding or removing one draw anywhere shifts every value after it, for every
// existing project. New tables go at the END, in a new loop, as the second loop
// was. Because Multi Strand mode (moreHairs==1) takes three extra draws per
// strand, switching it changes the values of the first loop from strand 1
// onward - a set is not the same hair in the two modes.
//
// SIDE EFFECT  random_set_seed() moves the game's one global random stream.
//              Anything that calls random() afterwards continues from here.
//
// The table size is 100 strands. Readers must never index past 99 - doMainStep
// caps strandSet at 100 and the preview count is capped at 100 for this reason.
// The loop counters e and pr are instance variables, not locals (c is a local).
// =============================================================================
function updatePreRands(argument0){
		//updatePreRands (ALL)
		//random_set_seed(seedVal)
		
		if argument0==-1
			{
			for (e=0;e<11;e++)
				{
				
				random_set_seed(randomSeedVal[e]) // here we can interviene on the randomizer per set...V1.7.0					
				
				// V1.95 - was random(lifeVariant*2). lifeVariant is a per-strand working
				// variable, so this used whichever set the last preview pass ended on -
				// a different value before and after a reload.
				// One value per SET: extra length added to the whole set (0..Variation*2).
				preRandLifeVariant[e]=random(strandSetVariAdj[e]*2)
				for (pr=0;pr<100;pr++) // pre randomization feature to keep hairs consistent (see doCalc)
					{
						preRandAmp[e,pr]=random(1000)/10000 // 0..0.1 - wave amplitude factor
						preRandSpacing[e,pr]=random_range(0,strandSetSpaceAdj[e]*10) // root X inside the set's span (4096-space px). Also decides the clump bin.
						// NOTE: this value is overwritten by the appended loop below.
						// The draw itself must stay - it holds the stream position for
						// every pre-random after it, so deleting it would change every
						// existing project.
						preRandLife[e,pr]=random_range(   
									clamp (hairLength*   (1-(lifeVariant/100)) , 10 , 3900)     ,
									clamp (hairLength*   (1+(lifeVariant/100)) , 10 , 3900)
									)
						preRandFreq[e,pr]=random_range(strandSetWaveFreqMinAdj[e],strandSetWaveFreqMaxAdj[e]) // new in 1.5 20th Oct
						
						//preRandYY[e,pr]=random(strandYRanRange[e])+120+(strandYRanRange[e]/2) // in 1.672
						preRandYY[e,pr]=random_range(-strandYRanRange[e],strandYRanRange[e]*3)+120 // in 1.673
						// ^ start Y of the strand in 4096 space, before the set's yOffset
						
						// RootRange and Root: how far down the strand the root tint reaches.
						preRandRootRange[e,pr]=random((rootPosition*50))/3
						// V1.95 - was +rootRange, another leftover per-strand global. Use the
						// range generated for this strand on the line above, which is what
						// doCalc pairs it with anyway.
						preRandRoot[e,pr]=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+preRandRootRange[e,pr]))
						preRandStrandDecision[e,pr]=random(100)/100
						preRandStraggleChoice[e,pr]=choose(editingPath[0],editingPath[1],editingPath[2])
						preRandDepth[e,pr]=random(100)/100 // 0..1 - RGB-mask red channel and the colour A/B blend
						preRandDepthAdd[e,pr]=clamp(random_range(-100,100)/1000,0,1) // 0..0.1 (the negative half clamps to 0), added to Depth
						
						// Multi Strand mode only: sprite sub-image, base rotation and
						// per-point curl. These three draws are skipped in Single
						// Strand mode - see RANDOM STREAM ORDER in the header.
						if moreHairs==1 {
						preRandSubSprite[e,pr]=choose(0,0,0,1,2,3,4)
						preRandAngChoice[e,pr]=choose(0,0,30,45,90,180,270)
						preRandCurling[e,pr]=random_range(-curlRotAmt*5,curlRotAmt*5)
						}
						if moreHairs==0 {
						preRandSubSprite[e,pr]=0
						preRandAngChoice[e,pr]=0
						preRandCurling[e,pr]=0
						}

					}

				// ---------------------------------------------------------------
				// life and thickness were the only two per-strand values still
				// being rolled live inside doCalc, which meant the renderer could
				// only match them for the strands the PREVIEW happened to have
				// drawn. They are tables now, so both paths read the same numbers
				// for all 100 strands regardless of the preview quality setting.
				// This second loop is appended deliberately: inserting draws into
				// the loop above would have shifted every existing pre-random.
				// ---------------------------------------------------------------
				// LENGTH: the set's own length if it has one, else the global
				// 'length', plus the per-set extra. Each strand then lands within
				// +/- Variation% of that, clamped to 10..3900 points. 3900 is the
				// hard limit the rest of the program is sized for (the 4000-entry
				// point arrays in doMainStep, the mixer cache, the clump leader paths).
				// Must match how doMainStep and previewDrawStrands work out hairLength.
				var _lvA = strandSetVariAdj[e]
				var _hlA = strandLengthOverride[e]
				if _hlA<=0 _hlA = length
				_hlA += preRandLifeVariant[e]

				// THICKNESS: a random base multiplier per strand, between
				// ThickVary/100 and ThickVary/20, clamped to 0.8..maxScale - or to
				// the set's own min / max where those are overridden.
				var _tvA = setThickVaryAdj[e]
				var _tbLoA = 0.8
				var _tbHiA = maxScale
				if setThickMinOverrode[e]==1 _tbLoA = setThickMinAdj[e]
				if setThickMaxOverrode[e]==1 _tbHiA = setThickMaxAdj[e]

				for (pr=0;pr<100;pr++)
					{
					preRandLife[e,pr]=random_range(
								clamp(_hlA*(1-(_lvA*0.01)),10,3900),
								clamp(_hlA*(1+(_lvA*0.01)),10,3900))
					preRandThickBase[e,pr]=clamp(random_range(_tvA/100,_tvA/20),_tbLoA,_tbHiA)
					}
				}
			}
		else
		{ // optimised approach.
			// SINGLE-SET BRANCH - a line-for-line copy of the loop body above with
			// c in place of e. Keep the two identical, draw for draw.
			var c=clamp(argument0,0,10);

			// The all-sets branch seeds per set; this one never did, so every value
			// it produced depended on wherever the global stream happened to sit.
			// Harmless while every caller passes -1, but this is the branch the
			// local-preview rebuild would use, so it has to be seeded the same way.
			random_set_seed(randomSeedVal[c])
			preRandLifeVariant[c]=random(strandSetVariAdj[c]*2) // V1.95 - see the all-sets path
			for (pr=0;pr<100;pr++) // pre randomization feature to keep hairs consistent (see doCalc)
					{
						preRandAmp[c,pr]=random(1000)/10000
						preRandSpacing[c,pr]=random_range(0,strandSetSpaceAdj[c]*10)
						// overwritten below; the draw holds the stream position - see above
						preRandLife[c,pr]=random_range(   
									clamp (hairLength*   (1-(lifeVariant/100)) , 10 , 3900)     ,
									clamp (hairLength*   (1+(lifeVariant/100)) , 10 , 3900)
									)
						preRandFreq[c,pr]=random_range(strandSetWaveFreqMinAdj[c],strandSetWaveFreqMaxAdj[c]) // new in 1.5 20th Oct
						preRandYY[c,pr]=random_range(-strandYRanRange[c],strandYRanRange[c]*3)+120 // V1.94 - was a different band to the all-sets path above
						preRandRootRange[c,pr]=random((rootPosition*50))/3
						preRandRoot[c,pr]=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+preRandRootRange[c,pr])) // V1.95 - see above
						preRandStrandDecision[c,pr]=random(100)/100
						preRandStraggleChoice[c,pr]=choose(editingPath[0],editingPath[1],editingPath[2])
						preRandDepth[c,pr]=random(100)/100	
						preRandDepthAdd[c,pr]=clamp(random_range(-100,100)/1000,0,1)
						
						if moreHairs==1 {
						preRandSubSprite[c,pr]=choose(0,0,0,1,2,3,4)
						preRandAngChoice[c,pr]=choose(0,0,30,45,90,180,270)
						preRandCurling[c,pr]=random_range(-curlRotAmt*5,curlRotAmt*5)
						}
						if moreHairs==0 {
						preRandSubSprite[c,pr]=0
						preRandAngChoice[c,pr]=0
						preRandCurling[c,pr]=0
						}
					}

			// see the all-sets path above
			var _lvB = strandSetVariAdj[c]
			var _hlB = strandLengthOverride[c]
			if _hlB<=0 _hlB = length
			_hlB += preRandLifeVariant[c]

			var _tvB = setThickVaryAdj[c]
			var _tbLoB = 0.8
			var _tbHiB = maxScale
			if setThickMinOverrode[c]==1 _tbLoB = setThickMinAdj[c]
			if setThickMaxOverrode[c]==1 _tbHiB = setThickMaxAdj[c]

			for (pr=0;pr<100;pr++)
				{
				preRandLife[c,pr]=random_range(
							clamp(_hlB*(1-(_lvB*0.01)),10,3900),
							clamp(_hlB*(1+(_lvB*0.01)),10,3900))
				preRandThickBase[c,pr]=clamp(random_range(_tvB/100,_tvB/20),_tbLoB,_tbHiB)
				}
		}
		
		
}

