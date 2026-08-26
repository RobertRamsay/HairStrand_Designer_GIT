// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function doCalc(){
	

						    
							
						
							thicknessBase = clamp(random_range(thickVary/100,thickVary/20),0.8,maxScale)
							strandThickBase[b,v]=thicknessBase // store
							// DEPTH TONE
							//var d=clamp(24+((231/(floor((strands)-(b*diminish))))*v),24,255) // new limited base at 24
							//var d=clamp(floor((255/strandSet)*v),20,255)
							//depthTone=make_color_rgb(d,d,d);
							
							// SPACING
							//xx=(320-(strandSetSpaceAdj[b]*10))+((strandSetSpaceAdj[b]*10)/2)+((random_range(0,strandSetSpaceAdj[b]*10)+(b*((setDistance*2)*5)))) 
							// new pre rand 1.50
							xx=(320-(strandSetSpaceAdj[b]*10))+((strandSetSpaceAdj[b]*10)*0.5)+((preRandSpacing[b,v]+(b*((setDistance*2)*5)))) 
							strandXX[b,v]=xx
					
							//strandYOffset[s]=0
							setXpos=(320-(strandSetSpaceAdj[b]*10))+(strandSetSpaceAdj[b]*10)+(b*((setDistance*2)*5)) 
							sx=xx
							strandXOffset[b]=setXpos
							
							// LIFE 
							//life=(hairLength-(lifeVariant*20))+random((lifeVariant*20))
							
							life=random_range(   
							clamp (hairLength*   (1-(lifeVariant*0.01)) , 10 , 3900)     ,
							clamp (hairLength*   (1+(lifeVariant*0.01)) , 10 , 3900)
							)
							/*
							life=random_range(   
							clamp (hairLength*   (1-(preRandLifeVariant[b]/100)) , 10 , 3900)     ,
							clamp (hairLength*   (1+(preRandLifeVariant[b]/100)) , 10 , 3900)
							)
							*/ // this one is a tricky beast...will revisit
							
							// new pre rand 1.50
							//life=preRandLife[b,v] // this one doesnt quite work as intended...
							
							strandLife[b,v]=life
									
						
						// only re-random if ... 
						// we are changing  sliders... not the previewer counts or detailing!
						// BUG**
						
							//avgLife=median(life,avgLife)
							// new pre rand 1.50
							// new pre rand 1.50
							//dpth=random(100)/100
							dpth=preRandDepth[b,v]
							strandDepth[b,v]=dpth
							//Freqcontrol

							//freq=random_range(minFreq,maxFreq)
							//freq=random_range(strandSetWaveFreqMinAdj[b],strandSetWaveFreqMaxAdj[b]) // new in 1.5 20th Oct
							// new pre rand 1.50
							freq=preRandFreq[b,v]
							strandFrq[b,v]=freq
							
							// new pre rand 1.50
							//amp=random(1000)/10000
							amp = preRandAmp[b,v] //=random(1000)/10000
							strandAmp[b,v]=amp
							
							yp=0;
							// new pre rand 1.50
							//yy=random(20)+120
							yy=preRandYY[b,v] // 1.673
							strandYY[b,v]=yy
							strandYOffset[b]=yy
							
							nx=0;
							// new pre rand 1.50
							//rootRange=random((rootPosition*50))/3 //500 // can we define this?
							rootRange=preRandRootRange[b,v]
							strandRootRange[b,v]=rootRange
							
							// new pre rand 1.50
							
							//root=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+rootRange))
							root=preRandRoot[b,v]
							strandRoot[b,v]=root
							
							tip=((tipPosition*10))
							
							// new pre rand 1.50
							//strandDecision=random(100)/100 // influence of the strand 0.00 - 1.00
							strandDecision=preRandStrandDecision[b,v]
							strandDecide[b,v]=strandDecision
							
							// new pre rand 1.50
							//straggleChoice=choose(editingPath[0],editingPath[1],editingPath[2]);
							straggleChoice=preRandStraggleChoice[b,v]
							strandStraggleChoice[b,v]=straggleChoice
							// the [arrays] can be recalled up to a certain number in the final render...
			
							subSpriteChoice=preRandSubSprite[b,v]
							angChoice=preRandAngChoice[b,v]

							// ------------------------------------------------
							// V1.86 NOISE - per-strand setup.
							// Phases are hashed from the set seed + set/strand
							// index, so the result is seed-driven and repeatable
							// WITHOUT drawing from the random stream (drawing
							// from it here would shift every existing project).
							// ------------------------------------------------
							noiseOn=0
							noiseP1=0; noiseP2=0; noiseP3=0
							noiseS1=0; noiseS2=0; noiseS3=0
							noiseAmpS=0

							if noiseAmt>0
								{
								noiseOn=1
								var _nA=(v*12.9898)+(b*78.233)+(randomSeedVal[b]*37.719)
								noiseP1=frac(abs(sin(_nA)        *43758.5453))*1440
								noiseP2=frac(abs(sin(_nA+17.31)  *43758.5453))*1440
								noiseP3=frac(abs(sin(_nA+53.77)  *43758.5453))*1440
								var _nCyc=1440/max(life,1)
								noiseS1=_nCyc*1.0   // ~1 slow sweep down the fibre
								noiseS2=_nCyc*2.7
								noiseS3=_nCyc*6.3
								noiseAmpS=(noiseAmt*0.01)*(life*noiseScale)
								}

}
