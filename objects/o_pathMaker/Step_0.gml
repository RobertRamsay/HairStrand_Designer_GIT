// o_pathMaker Step - the preview drawing for the flyaway-path experiment.
// NOT REACHABLE (see this object's Create), and DISABLED as well: everything
// below is one block comment. Note the comment is opened but never closed, so
// it runs to the end of the file. Anything added below this point is
// commented out too; new code or notes must go ABOVE the opening marker.
//
// What it did when live: cleared pathPreview and drew the first N paths
// (N from mouse x), each 0.4 px to the right of the last, in a random colour
// from a fixed seed. Left state drew them with draw_path; holding the right
// button drew them as line segments whose width and brightness peak in the
// middle of the strand (the dsin(n*180) term), with mouse y setting how many
// segments.
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
