// =============================================================================
// checkAndOffset - SELECTING SETS AND MOVING THEM AROUND THE CANVAS
//
// CALLED BY  obj_surfaceDweller Draw_0, once per frame, near the end of the
//            event (it draws the set-button outlines on the bottom bar).
//
// WHAT IT DOES
//   - Right click: clear the selection and any solo.
//   - With a set selected (setSelectedID != -1), outside the path editor room:
//       arrow keys nudge it: 20 px, 1 with Ctrl, 100 with Shift (4096-space px)
//       left-drag on the canvas moves it; right click during a drag solos it
//   - The 11 set buttons on the bottom bar (centres x = 1082 + n*80, y = 1046,
//     half-size 10): hover outlines the button, click selects the set, click
//     on the already-selected set solos it. While hovering a button the arrow
//     keys nudge THAT set and Enter resets its offset to 0,0.
//
// SCALE  xOffset[] / yOffset[] are in 4096x4096 map pixels. The canvas on
//        screen is 1024x1024, so mouse positions are multiplied by 4.
//
// HOW A MOVE REACHES THE SCREEN  xOffset/yOffset are part of each set's preview
// signature (previewSetSig), so changing them makes previewUpdate redraw that
// set. The final render adds them in doMainStep. pleaseGen=true is the general
// "a setting changed since the last Generate" flag.
//
// WRITES  xOffset[], yOffset[], strandXOffset[], strandYOffset[], setSelected[],
//         setSelectedID, setToSolo, setHovveredID, hoveringNumber, held, moving,
//         xDiff, yDiff, mbx, mby, ghostSprite, flashAlpha, pleaseGen,
//         notPressingSets, draw colour and font.
//
// !! The last thing it does is keyboard_clear(vk_anykey). Any key test that
// !! runs AFTER this call in the same frame will not see a held key.
//
// obj_pathEdit's button must stay off the canvas: any left click on the canvas
// here is treated as the start of a set drag (see obj_pathEdit Draw_64).
// =============================================================================
function checkAndOffset() {
	/*if keyboard_check_pressed(argument0) 
		{
		window_mouse_set(960,50)
		}
	*/
	//move sets by holding on number area
	//var xbp=1082
	var xbs=80    // spacing between set buttons on the bottom bar, screen px
	var xbwh=10   // half the width/height of a set button's hit box


	hoveringNumber=0
	//if keyboard_check(argument0) 
		draw_set_color(c_dkgray)
	//	var drawOne=0
		
		if mouse_check_button_pressed(mb_right)	//and !mouse_check_button(mb_left)
			{
				
			if ghostSprite!=-1 {sprite_flush(ghostSprite);sprite_delete(ghostSprite)}
			
			for (nC=0;nC<12;nC++)
				{							
					setSelected[nC]=0 //deactivate all
					setSelectedID=-1 // reset
					clickCount=0
				}
				setToSolo=-1
			}

		if setSelectedID!=-1 and room!=Room_PathEditing
			{
			var stdDist = 20
			if keyboard_check(vk_control) stdDist = 1 
			//if keyboard_check(vk_alt) stdDist = 5 
			if keyboard_check(vk_shift) stdDist = 100 
			if keyboard_check_pressed(vk_left) {xOffset[setSelectedID]-=stdDist;strandXOffset[setSelectedID]=xOffset[setSelectedID];pleaseGen=true;}
			if keyboard_check_pressed(vk_right) {xOffset[setSelectedID]+=stdDist;strandXOffset[setSelectedID]=xOffset[setSelectedID];pleaseGen=true;}
			if keyboard_check_pressed(vk_up) {yOffset[setSelectedID]-=stdDist;strandYOffset[setSelectedID]=yOffset[setSelectedID];pleaseGen=true;}
			if keyboard_check_pressed(vk_down) {yOffset[setSelectedID]+=stdDist;strandYOffset[setSelectedID]=yOffset[setSelectedID];pleaseGen=true;}
			
			// On the click that starts a drag, remember how far the set's offset
			// is from the mouse (in 4096 space) so the set does not jump to the
			// cursor, and where the click was (mbx, mby) for the movement test.
			if mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x,mouse_y,0,0,1023,1023) 
				{
					xDiff= ((xOffset[setSelectedID]) - (mouse_x*4))
					yDiff= ((yOffset[setSelectedID]) - (mouse_y*4))
				}
			
			if mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x,mouse_y,0,0,1023,1023) 
				{
				mbx=mouse_x
				mby=mouse_y
				}
			
			//mouse placement
			if mouse_check_button(mb_left) && point_in_rectangle(mouse_x,mouse_y,0,0,1023,1023)
				{		
					
					// The drag only starts after the button has been held for about
					// 0.15 s (held counts frames) or the mouse has moved more than
					// 10 screen px. No pleaseGen here: the offset change itself is
					// picked up by the preview signature.
					held++
					if held>fps*0.15 or point_distance(mbx,mby,mouse_x,mouse_y)>10 // prevent accidental movement
					{ 
						moving=1
						//var yDiff=yOffset[setSelectedID]-(mouse_x/4)
						xOffset[setSelectedID]=  ( (mouse_x*4) ) + xDiff; //img=9;pleaseGen=true;
						yOffset[setSelectedID]=  ( (mouse_y*4) ) + yDiff; //img=9;pleaseGen=true;
						
						//quick isolate
						if mouse_check_button_pressed(mb_right)
							{
							//capture the screen
							ghostSprite=sprite_create_from_surface(application_surface,0,0,room_width,room_height,0,0,0,0)
							
							setToSolo=setSelectedID
							}
					 }
				
						
				}
			}
			
			if mouse_check_button_released(mb_left) {held=0;moving=0}
			setHovveredID=-1
			
			
			
		for (xnum=0;xnum<11;xnum++) // set selection
			{
			
			  if point_in_rectangle(mouse_x,mouse_y,1082-xbwh+(xnum*xbs),1046-xbwh,1082+xbwh+(xnum*xbs),1046+xbwh) 
			
				{
					setHovveredID=xnum
				
					
					draw_set_color(c_white)
					
					if mouse_check_button_pressed(mb_left) 
						{
						
						 // the ID of the selected 1.43
						if setSelected[xnum]==1 {setToSolo=xnum} else {setSelectedID=xnum} // make it solo
						if setToSolo!=xnum setToSolo=-1 // reset if changed
						
						for (nC=0;nC<12;nC++)
							{
								
								setSelected[nC]=0 //deactivate all
							}
							
						
							if setSelectedID!=-1 setSelected[setSelectedID]=1 // no sets are sected for overrides. 1.43
						
						}
					
					/*
					if mouse_check_button_pressed(mb_right)
						{
						
						//reset overrides (maybe later)
						
						for (nC=0;nC<12;nC++)
							{
								
								setCountOverrode[xnum]=0
								setLengthOverrode[xnum]=0
							}
							
						
							if setSelectedID!=-1 setSelected[setSelectedID]=1 // no sets are sected for overrides. 1.43
						
						}
					*/	
					
					draw_rectangle(1082-xbwh+(xnum*xbs),1046-xbwh,1082+xbwh+(xnum*xbs),1046+xbwh,1) 
					draw_rectangle(1081-xbwh+(xnum*xbs),1045-xbwh,1083+xbwh+(xnum*xbs),1045+xbwh,1) 
					draw_set_color(c_dkgray)
					draw_set_font(smallFont)
					
					/*
					if drawOne==0
						{
						draw_text(900,120,"Offset controller")
						draw_text(900,140,"X_offset: "+string(xOffset[xnum]))
						draw_text(900,160,"Y_offset: "+string(yOffset[xnum]))
						drawOne=1
						}
						*/
			var stdDist = 20
			
			
			
			if keyboard_check(vk_control) stdDist = 1 
			//if keyboard_check(vk_alt) stdDist = 5 
			if keyboard_check(vk_shift) stdDist = 100 
			if keyboard_check_pressed(vk_left) {xOffset[xnum]-=stdDist;strandXOffset[xnum]=xOffset[xnum];pleaseGen=true;}
			if keyboard_check_pressed(vk_right) {xOffset[xnum]+=stdDist;strandXOffset[xnum]=xOffset[xnum];pleaseGen=true;}
			if keyboard_check_pressed(vk_up) {yOffset[xnum]-=stdDist;strandYOffset[xnum]=yOffset[xnum];pleaseGen=true;}
			if keyboard_check_pressed(vk_down) {yOffset[xnum]+=stdDist;strandYOffset[xnum]=yOffset[xnum];pleaseGen=true;}
	
			if keyboard_check_pressed(vk_enter) // reset
				{
				pleaseGen=true
				xOffset[xnum] = 0 ; strandXOffset[xnum]=xOffset[xnum]
				yOffset[xnum] = 0 ; strandYOffset[xnum]=yOffset[xnum]
				}

				notPressingSets=false
				//img=9
			
				hoveringNumber=true
			
				}
				
				
					if setSelected[xnum]==1 // no sets are sected for overrides. 1.43
						{
						draw_set_color(c_orange)
						draw_rectangle(1082-xbwh+(xnum*xbs),1046-xbwh,1082+xbwh+(xnum*xbs),1046+xbwh,1) 
						draw_rectangle(1081-xbwh+(xnum*xbs),1045-xbwh,1083+xbwh+(xnum*xbs),1045+xbwh,1) 
						}
						
					if setToSolo==xnum
						{
						draw_sprite_ext(s_SoloSet,0,1065+(xnum*xbs),1046,1,1,0,c_white,flashAlpha)
						}
				
				
		}
	
		// Clears every key state for the rest of this frame - see the header.
		keyboard_clear(vk_anykey)
		flashAlpha=abs(sin(degtorad(gameTick360*10)))   // pulse for the solo marker



}
