// o_pathMaker Draw GUI - on-screen readout for the flyaway-path experiment.
// NOT REACHABLE: nothing goes to Room_Pathmaker (see this object's Create).
// Shows FPS, how many paths the (disabled) preview would draw, which scales
// with mouse x (mouse_x*2, limited to 1..paths), the lpd counter, and which
// drawing style the right mouse button selects. The drawing itself is in the
// commented-out Step event, so only this text appears.

	//draw_surface_ext(pathPreview,0,0,1,1,0,c_white,1)
	draw_set_color(c_white)
	draw_text(0,0,"FPS: "+string(fps)+ " Paths: "+string(clamp(mouse_x*2,1,paths))
	+" Last Point removed: "+string(lpd)
	)
	if !mouse_check_button(mb_right) draw_text(0,20,"Previewing Simple Paths")
	if mouse_check_button(mb_right) draw_text(0,20,"Previewing Better Paths")
	