// Script assets have changed for v2.3.0 see
/// @updatePreRands(value)
/// @param something
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function updatePreRands(argument0){
		//updatePreRands (ALL)
		//random_set_seed(seedVal)
		
		if argument0==-1
			{
			for (e=0;e<11;e++)
				{
				
				random_set_seed(randomSeedVal[e]) // here we can interviene on the randomizer per set...V1.7.0					
				
				preRandLifeVariant[e]=random(lifeVariant*2)
				for (pr=0;pr<100;pr++) // pre randomization feature to keep hairs consistent (see doCalc)
					{
						preRandAmp[e,pr]=random(1000)/10000
						preRandSpacing[e,pr]=random_range(0,strandSetSpaceAdj[e]*10)
						preRandLife[e,pr]=random_range(   
									clamp (hairLength*   (1-(lifeVariant/100)) , 10 , 3900)     ,
									clamp (hairLength*   (1+(lifeVariant/100)) , 10 , 3900)
									)
						preRandFreq[e,pr]=random_range(strandSetWaveFreqMinAdj[e],strandSetWaveFreqMaxAdj[e]) // new in 1.5 20th Oct
						
						//preRandYY[e,pr]=random(strandYRanRange[e])+120+(strandYRanRange[e]/2) // in 1.672
						preRandYY[e,pr]=random_range(-strandYRanRange[e],strandYRanRange[e]*3)+120 // in 1.673
						
						preRandRootRange[e,pr]=random((rootPosition*50))/3
						preRandRoot[e,pr]=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+rootRange))
						preRandStrandDecision[e,pr]=random(100)/100
						preRandStraggleChoice[e,pr]=choose(editingPath[0],editingPath[1],editingPath[2])
						preRandDepth[e,pr]=random(100)/100
						preRandDepthAdd[e,pr]=clamp(random_range(-100,100)/1000,0,1)
						
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
				}
			}
		else
		{ // optimised approach.
			var c=clamp(argument0,0,10);
			preRandLifeVariant[c]=random(lifeVariant*2)
			for (pr=0;pr<100;pr++) // pre randomization feature to keep hairs consistent (see doCalc)
					{
						preRandAmp[c,pr]=random(1000)/10000
						preRandSpacing[c,pr]=random_range(0,strandSetSpaceAdj[c]*10)
						preRandLife[c,pr]=random_range(   
									clamp (hairLength*   (1-(lifeVariant/100)) , 10 , 3900)     ,
									clamp (hairLength*   (1+(lifeVariant/100)) , 10 , 3900)
									)
						preRandFreq[c,pr]=random_range(strandSetWaveFreqMinAdj[c],strandSetWaveFreqMaxAdj[c]) // new in 1.5 20th Oct
						preRandYY[c,pr]=random_range(-strandYRanRange[c],strandYRanRange[c]*3)+120 // V1.94 - was a different band to the all-sets path above
						preRandRootRange[c,pr]=random((rootPosition*50))/3
						preRandRoot[c,pr]=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+rootRange))
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
		}
		
		
}

