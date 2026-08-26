/*
surface_set_target(pathPreview)
draw_clear(c_dkgray)
	{
	var xx=100
	var yy=50

	var placeInPath=0//dsin(n*180)
	var definition=clamp(mouse_y/4,20,200)
	var pathsToShow= clamp(mouse_x*2,1,paths)
	random_set_seed(0)
	for (pa=0;pa<  pathsToShow   ;pa++) // many paths
		{
		var tone =irandom(255)
		var sat =irandom(255)
		draw_set_color(c_blue)
		draw_set_color(make_color_hsv(tone,sat,255*(pa/pathsToShow)))
		if !mouse_check_button(mb_right) draw_path(path[pa],xx+(pa*0.4),yy,0)
	
		
		if mouse_check_button(mb_right)  // lines
			{
			for (pathPos=0;pathPos<definition-1;pathPos+=1)
				{
				
				n=pathPos/definition	
				placeInPath=clamp(dsin(n*180),0,1)
				draw_set_color(make_color_hsv(tone,sat,(placeInPath*255)*pa/pathsToShow))
				draw_line_width(
					xx+(pa*0.4)+path_get_x(path[pa],n),yy+path_get_y(path[pa],n),
					xx+(pa*0.4)+path_get_x(path[pa],n+(1/definition)),yy+path_get_y(path[pa],n+(1/definition)),
					clamp(5*placeInPath,1,2)
				)
				//draw_circle(xx+(pa*0.4)+path_get_x(path[pa],n),yy+path_get_y(path[pa],n),clamp(5*placeInPath,2,5),0)
				draw_set_color(c_white)
				}
			}

		}
	}
surface_reset_target()
