// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// doHighlighting - SET BOXES, NUMBER LABELS AND CLICK-TO-SELECT ON THE CANVAS
//
// CALLED BY  mainCalc, every frame in the previewer view (img 9), after the
//            preview surfaces have been composited - so it draws on top.
//
// For each visible set it takes the bounding box that previewDrawStrands
// cached while drawing (setBBl/r/t/b, in 4096 space WITHOUT the set offset),
// adds xOffset/yOffset and multiplies by 0.25 to get screen pixels, then:
//   - hovering a set's box (mouse up): outline + its number (b+1)
//   - left click in the box: that set becomes the selected set
//   - the selected set: double outline, orange, or lime while being dragged
//   - hovering a set's number button on the bottom bar (setHovveredID, set by
//     checkAndOffset): shows that set's number label on the canvas
//
// It no longer calculates any strands. If a box does not match the strands,
// look at where previewDrawStrands grows the box, not here.
//
// READS   setBB*[], xOffset[], yOffset[], setToSolo, setHovveredID, clickedID,
//         moving, firstTime, strands / strandCountOverride, maxPreviewStrandsPerSet
// WRITES  setSelected[], setSelectedID, setToSolo, numSel, hairLength, strandSet,
//         leftmost/rightmost/topmost/bottommost, previewCanvasComplete (=1),
//         seedVal, and the draw colour / alignment (left as set).
//
// SIDE EFFECT ON THE RANDOM STREAM: with dance==0 (the default) this re-seeds
// the global stream from seedVal every frame it runs. Nothing in the preview or
// render depends on the stream position any more, but any NEW code that calls
// random() between frames will be reset by this.
//
// numSel stops more than one set reacting to the mouse in a frame: the first
// box (lowest set number) under the mouse wins.
// =============================================================================
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
				// V1.96 - the bounding box comes from the cache previewDrawStrands fills
				// while it draws this set. This used to re-run doCalc and the whole
				// point loop for every strand of every set on EVERY frame, only to
				// find these four numbers - and with tapering left out, so the box
				// never quite matched the strands on screen.
				if setCountOverrode[b]==1 {strandSet=strandCountOverride[b]} else {strandSet=strands}
				leftmost=setBBl[b]
				rightmost=setBBr[b]
				topmost=setBBt[b]
				bottommost=setBBb[b]
				var _hlXX=setBBxx[b]

							// show IDs of strand sets
							draw_set_halign(fa_middle)
							draw_set_valign(fa_middle)
							if clamp(strandSet,0,maxPreviewStrandsPerSet)>0 and !instance_exists(obj_pathEdit)
								{
							
								var xpos=(_hlXX+xOffset[b])/4   // screen X of the last strand drawn in this set
								if xpos< 1024 and firstTime==0
									{
										
									// Number label when the set's button on the bottom bar is hovered.
									// NOTE: the label Y uses (topmost+bottommost)/4 and then x0.25
									// again, where the box itself uses x0.25 once - so the label
									// sits near the top of the box, not at its centre.
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
												// NOTE: this assigns to b, the FOR-LOOP COUNTER, so
												// the loop carries on from clickedID+1 after a click
												// (from set 0 again if clickedID is -1). numSel is
												// set just below, so no second set can be selected.
												b=clickedID
											}
											
											// Solo: left held + right click, or Alt+Q, isolates set clickedID
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