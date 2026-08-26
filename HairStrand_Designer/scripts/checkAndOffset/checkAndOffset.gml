function checkAndOffset() {
	/*if keyboard_check_pressed(argument0) 
		{
		window_mouse_set(960,50)
		}
	*/
	//move sets by holding on number area
	//var xbp=1082
	var xbs=80
	var xbwh=10


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
	
		keyboard_clear(vk_anykey)
		flashAlpha=abs(sin(degtorad(gameTick360*10)))



}
