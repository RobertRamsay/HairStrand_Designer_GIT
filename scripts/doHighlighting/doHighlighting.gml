// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function doHighlighting(){
#region
if img==9 
	{
	optimalStep=160
	if dance==0 random_set_seed(seedVal) // just a seed
	//if dance==1 randomize()
	seedVal=random_get_seed()
	
	numSel=0
		//SET
		for (b=0;b<sets+1;b++) // number of sets // this will be flexible based on user adding or removing sets. 
		//We can start with 8 sets with their own XY starting positions, user will define positioning manually. 
			{
			leftmost=0;rightmost=0
			topmost=0;bottommost=0
			
			if (setToSolo==b or setToSolo==-1) // skip whole calcs..
				{
				// choose a start point within a set area
					setID=b				
					sx=xx 
				// lifeVariant is ALSO the global 'Variation' setting that the slider and
				// text box write. Assigning the per-set value to it here overwrote the
				// typed value every frame, which is why the Variation box would not take
				// an edit. Use a local for the per-set working value instead.
				var _lvS=strandSetVariAdj[b]
				// V1.95 - unconditional, matching mainCalc / doMainStep
				var _hlH = strandLengthOverride[b]
				if _hlH<=0 _hlH = length
				hairLength = _hlH + preRandLifeVariant[b]
				/*
				if setLengthOverrode[b]==1 {hairLength=strandLengthOverride[b]+preRandLifeVariant[b]} // assign new value
				else
				{hairLength=3500}
*/
				if setCountOverrode[b]==1
					{strandSet=strandCountOverride[b]}
					else
					{strandSet=strands}
				
					//STRAND
					for (v=0;v<clamp(strandSet,0,maxPreviewStrandsPerSet) ;v++) // Main loop for each full strand of each set max of 5 for previewer
						//v=0
						//if v<(strands-(b*diminish)) 
							{
							doCalc()	
							//if firstCalc==1 doCalc() else doCalcSoft() // this was okay for a while but doesnt update properly
							
							
							for(n=0;n<life;n+=optimalStep) // MAIN LOOP through strand-plot of a single hair strand
								{

									// root and tip color pre 1.43
									// if root>n {rt=1-(clamp(n/root,0,1))}
									// if life-tip>n {tp=1-(clamp(abs((life-tip-n))/tip,0,1))}
									
									// new 1.43 version
									if root>n {rt=1-(clamp((n*(3800/life))/root,0,1))} else rt=0.01
									if life- tip   >n {tp=1-(clamp(abs((life-tip-n))/ (tip*(life/3800))   ,0,1))}
									
								// check scale
								//if (n<scaleIn)	
							
				// SCALE control for thickness
				// this is where we can introduce the extra controls in V1.301
								
								// Orig
								//var cmx=rootThick/30 // clamp(mouse_x/512,0,1)
								//var cmy=tipThick/30 //clamp(mouse_y/512,0,1)
								sc=clamp(n/scaleIn*(clamp(((life-n)/scaleOut),0,100)),minScale*(0.05+(padding/1000)),maxScale*(0.05+(padding/1000))) // litle extra for padding...
								//var scx=(lerp(  minScale*(0.05+(padding/1000)) ,maxScale*(0.05+(padding/1000))*2, dsin ( n/life*90 ) ))
								//var scy=(lerp(  minScale*(0.05+(padding/1000)) ,maxScale*(0.05+(padding/1000))*2, dcos ( n/life*90 ) ))
								//var scz=(lerp(  minScale*(0.05+(padding/1000)) ,maxScale*(0.05+(padding/1000)), dsin ( n/life*180) ))
								//var tA=lerp(scx,scz,cmx)
								//var tB=lerp(scy,scz,cmy)
								//var scA=(clamp((tA+tB),0.15,100)/2)*thicknessBase
								

								// affect depth
								//dpthAdd=clamp(random_range(-100,100)/1000,0,1)
								dpthAdd=preRandDepthAdd[b,v]
								//Color           

								// FADE OUT alpha
								// V1.91 per-set fade (globals are no longer clamped in-loop)
								var _fadeInS=clamp(setFadeInAdj[b],1,40)
								var _fadeOutS=clamp(setFadeOutAdj[b],1,40)
								if (n >    life-((_fadeOutS/40)*(life/2))    ) { a=     clamp (     ( (life-n)     /    ((_fadeOutS/40)* (life/2))   )    ,0,1) } // fadeOut
								if (n<  ((_fadeInS/40)*(life/2))      +1)    { a=clamp(n    /   ((_fadeInS/40)*(life/2))      ,0,1)     } // here we use fadeIn...
								//if (n >    life-fadeOut    ) { a=     clamp (     ( (life-n)     /fadeOut   )    ,0,1) } // fadeOut
								
								
							//	var dxFlow=((sin(degtorad(n*freq)*amp))+1)/2//*(yy/100))) // okay for ...
								deviationFromX=(sin(degtorad(n*freq))) // potentially lerp to this position over life?
	
								nx=   xx+((sin(degtorad(n*freq)*amp))*(yy/100))

								
								// now in 1.43
								var xA= lerp ( 0, path_get_x( editingPath[0],  (n-(_lvS))   /   (4096+((strandSetMixerOffsetAdj1[b])*100))) , strandSetMixerAdj1[b] ) // influence of mixer 1
								var xB= lerp ( 0, path_get_x( editingPath[1],  (n-(_lvS))   /   (4096+((strandSetMixerOffsetAdj2[b])*100))) , strandSetMixerAdj2[b] ) // influence of mixer 2
								var xC= lerp ( 0, path_get_x( editingPath[2],  (n-(_lvS))   /   (4096+((strandSetMixerOffsetAdj3[b])*100))) , strandSetMixerAdj3[b] ) // influence of mixer 3
								
								// New mixer overrides.
								// in version 1.43 - Aug 30th 2020
								
								
								var tempX=  (lerp (   lerp( xA , xB , 0.5 )   ,  xC , 0.5 ) / _lvS)*8 // mix all 3
								
								straggleXX=lerp(xx+tempX,setXpos,(n/3000)*(strandSetTaperAdj[b]*0.01)) // be sure to tapre the Stragglers
								
								// End New Section
							// ***********************
							// orig //straggleXX=lerp(xx+(path_get_x( straggleChoice,  (n-(lifeVariant*v))   /   4096)),setXpos,(n/3000)*(tapering*0.01)) // be sure to tapre the Stragglers
							 //                            ------------WAVINESS-----------| -------------TAPERING----------| ---- path influence -------
							 
							 // a version with out tapering:
							 //var algNoTaper= lerp(lerp(lerp(xx,nx,(wavyness*0.01)*ampFactor),setXpos,xx),straggleXX,0.5+((lifeVariant-50)/100))//strandDecision)  
							
							var algFinalX= lerp( //lerp     
													(lerp(xx,nx,( strandSetWavynessAdj[b]*0.01)*ampFactor)) // WAVYNESS (A) // nx is wavy offset
												//,setXpos // (B) location (so that we can taper to the middle of the set
												//,(n/3000)*(tapering*0.01)) // (CONTROL)
											,straggleXX,
											0.5+((_lvS-50)/100))//strandDecision) //  shifts them around
												
												
									var algTaper = algFinalX//lerp (algFinalX,setXpos	,(n/life)*(clamp(strandSetTaperAdj[b],1,strandSetTaperAdj[b])*0.01))		
												
												
							//var preFinalX= lerp(algFinalX,path_get_x(clumpPath,yy/4096),0.5) //
							
							//var preFinalX= ( lerp (xx,algFinalX,((alogrithmInfluence[b]-25)/25) )  )  // afected by the algorithms (mixers)
							//algTaper = lerp (preFinalX,setXpos	,(n/life)*(strandSetTaperAdj[b]*0.01))	// intervention
							// V1.90 NOISE - must match mainCalc / doMainStep so the
							// selection bounding boxes stay lined up with the strands.
							var _nzOfs=0
							if noiseOn==1
								{
								var _n1=lut_sin[round(noiseP1+(n*noiseS1)) mod 1440]
								var _n2=lut_sin[round(noiseP2+(n*noiseS2)) mod 1440]
								var _n3=lut_sin[round(noiseP3+(n*noiseS3)) mod 1440]
								_nzOfs=((_n1*0.62)+(_n2*0.28)+(_n3*0.10))*noiseAmpS*(n/life)
								}

							finalX=	algTaper+_nzOfs// ( lerp (preFinalX,algTaper,((taperInfluence[b]-25)/25) )  ) // finally taper
								

								//strandColor[b,v]=colrCustom
								// may require separate Variation, Root and Tip stoage for first 60 strands (previewed)
								draw_set_color(colrCustom)
								draw_set_alpha(clamp(a,0.25,1)) // fix issue with alpha for preview?
					
								//preview line if it is within the texture width
						if set_active[setID]==0 and !generating // only show the solo
							{
							if finalX+xOffset[b]<4098 && yy+(yOffset[b])<4070  and firstTime==0 // stop it from drawing too far right
								{
									{
			
												
														
									if topmost ==0 topmost=yy
									if topmost!=0 and yy<topmost topmost=yy
									if yy > bottommost  bottommost=yy
											
									if leftmost ==0 leftmost=finalX
									if leftmost!=0 and finalX<leftmost leftmost=finalX
									if finalX > rightmost  rightmost=finalX
											
									}
								}
							// ^ draw the preview lines 
							}
								draw_set_color(c_white)					
								draw_set_alpha(1)
								yy+=optimalStep						
								}

							}// v loop

							// show IDs of strand sets
							draw_set_halign(fa_middle)
							draw_set_valign(fa_middle)
							if clamp(strandSet,0,maxPreviewStrandsPerSet)>0 and !instance_exists(obj_pathEdit)
								{
							
								var xpos=(xx+xOffset[b])/4
								if xpos< 1024 and firstTime==0
									{
										
									if setHovveredID==b //and //b==setSelectedID
										{
										draw_set_color(c_black)
										draw_rectangle(((xOffset[b]+leftmost)*0.25),((yOffset[b]+((topmost+bottommost)/4))*.25)-12,((xOffset[b]+rightmost)*0.25),((yOffset[b]+((topmost+bottommost)/4))*.25)+12,0)
										draw_set_color(c_white)
										draw_text((xOffset[b]+((leftmost+rightmost)/2))*.25,(yOffset[b]+((topmost+bottommost)/4))*.25,string(b+1))			
										}
										
									//if point_in_rectangle(mouse_x,mouse_y,((xOffset[b]+leftmost)*0.25)-5,30+(yOffset[b]*0.25),((xOffset[b]+rightmost)*0.25)+5,clamp(((lifeVariant+life+yOffset[b]*0.25)+120),0,1023)    ) and numSel==0 // OLD in 1.674 bugged
									
									if point_in_rectangle(mouse_x,mouse_y,(xOffset[b]+leftmost)*.25,(topmost+yOffset[b])*.25,(xOffset[b]+rightmost)*0.25,(bottommost+yOffset[b])*.25   ) and numSel==0 // fix in 1.675 25/11/21
									
										{
										//lightUp=b
										if !mouse_check_button(mb_left)
											{
											draw_set_color(c_black)
											draw_rectangle(((xOffset[b]+leftmost)*0.25),((yOffset[b]+((topmost+bottommost)/4))*.25)-12,((xOffset[b]+rightmost)*0.25),((yOffset[b]+((topmost+bottommost)/4))*.25)+12,0)
											draw_set_color(c_white)
											draw_text((xOffset[b]+((leftmost+rightmost)/2))*.25,(yOffset[b]+((topmost+bottommost)/4))*.25,string(b+1))
											
								
											draw_rectangle((xOffset[b]+leftmost)*.25,(topmost+yOffset[b])*.25,(xOffset[b]+rightmost)*0.25,(bottommost+yOffset[b])*.25,1)								
											}						
										if mouse_check_button_pressed(mb_left) and !mouse_check_button(mb_right)   and firstTime==0
											{
												//if b!=clickedID and clickCount<1 resetSets();
												for (nC=0;nC<12;nC++)
													{
								
														setSelected[nC]=0 //deactivate all
													}			
												setSelectedID=b;setSelected[b]=true// move singular
												b=clickedID
											}
											
											if (mouse_check_button(mb_left)  and mouse_check_button_pressed(mb_right) and clickedID!=-1)
											or (keyboard_check(vk_alt) and keyboard_check_pressed(ord("Q")) and clickedID!=-1)
												 {setSelectedID=clickedID;setSelected[clickedID]=true;setToSolo=clickedID  }
	
										numSel=1
										}
									if setSelectedID==b 
										{
											//lightUp=-1
											if moving==0 draw_set_color(c_orange) else draw_set_color(c_lime)
											draw_rectangle((-2+(xOffset[b]+leftmost)*.25),-2+((topmost+yOffset[b])*.25),2+((xOffset[b]+rightmost)*0.25),2+((bottommost+yOffset[b])*.25),1)
											draw_rectangle((xOffset[b]+leftmost)*.25,(topmost+yOffset[b])*.25,(xOffset[b]+rightmost)*0.25,(bottommost+yOffset[b])*.25,1)
											draw_set_color(c_white)																								
										}
										
									}
									
								}
			}
													
		} //end of skip rendering/calc end of For b loop
		previewCanvasComplete=1
		//renderToSurf=0
	}
	#endregion
}