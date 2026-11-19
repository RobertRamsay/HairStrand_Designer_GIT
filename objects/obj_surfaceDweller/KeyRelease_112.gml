/// @description Key F1 (release) - type in a seed value
// -----------------------------------------------------------------------------
// EVENT : Key Release, key code 112 = F1. Fires when F1 is let go.
// DOES  : asks for a seed with a blocking dialog. If the answer is non-zero it
//         becomes seedVal and is written to randomSeedVal[]:
//           - no set selected (setSelectedID==-1): every set gets it
//           - a set selected: only that set gets it
//         seedUpdate=1 then makes previewUpdate() (previewJob) redraw all sets.
//         The pre-random tables are rebuilt by preRandsRefresh() because
//         randomSeedVal is one of their inputs.
// WRITES: seedValstring (despite the name it holds a number), seedVal,
//         randomSeedVal[], seedUpdate.
// NOTE  : randomOverride[] is not touched here. A seed of 0 is ignored because
//         the test is "if seedValstring".
// -----------------------------------------------------------------------------
//img=9
	{
	seedValstring=seedVal
	seedValstring=get_integer("Enter a seed value",random_get_seed())
	
    }
	
	if seedValstring {random_set_seed(seedValstring) ;seedVal=seedValstring
		if setSelectedID==-1
		for (b=0;b<maxSets;b++)
			{
			randomSeedVal[b]=seedVal
			}
		else
		{
			randomSeedVal[setSelectedID]=seedVal
		}
		seedUpdate=1

		}
	
	

