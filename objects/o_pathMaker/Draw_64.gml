
	//draw_surface_ext(pathPreview,0,0,1,1,0,c_white,1)
	draw_set_color(c_white)
	draw_text(0,0,"FPS: "+string(fps)+ " Paths: "+string(clamp(mouse_x*2,1,paths))
	+" Last Point removed: "+string(lpd)
	)
	if !mouse_check_button(mb_right) draw_text(0,20,"Previewing Simple Paths")
	if mouse_check_button(mb_right) draw_text(0,20,"Previewing Better Paths")
	