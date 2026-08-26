function killSurfaces() {
// killSurfaces: safely free all render canvases then recreate them clean.
// Always free BEFORE recreating - never create without freeing first.

	// Free every surface if it currently exists
	if surface_exists(canvas)       surface_free(canvas)
	if surface_exists(flow_canvas)  surface_free(flow_canvas)
	if surface_exists(mask_canvas)  surface_free(mask_canvas)
	if surface_exists(nm_canvas)    surface_free(nm_canvas)
	if surface_exists(id_canvas)    surface_free(id_canvas)
	if surface_exists(color_canvas) surface_free(color_canvas)
	if surface_exists(depth_canvas) surface_free(depth_canvas)
	if surface_exists(ao_canvas)    surface_free(ao_canvas)
	if surface_exists(frizz_canvas) surface_free(frizz_canvas)
	if surface_exists(blurSurface)  surface_free(blurSurface)
	if surface_exists(tNormsurf)    surface_free(tNormsurf)

	// Flush GPU texture memory before reallocating
	draw_texture_flush()

	// Recreate all surfaces fresh
	canvas       = surface_create(surfSize, surfSize)
	flow_canvas  = surface_create(surfSize, surfSize)
	mask_canvas  = surface_create(surfSize, surfSize)
	nm_canvas    = surface_create(surfSize, surfSize)
	id_canvas    = surface_create(surfSize, surfSize)
	color_canvas = surface_create(surfSize, surfSize)
	depth_canvas = surface_create(surfSize, surfSize)
	ao_canvas    = surface_create(surfSize, surfSize)
	frizz_canvas = surface_create(surfSize, surfSize)
	blurSurface  = surface_create(surfSize, surfSize)
	tNormsurf    = surface_create(surfSize, surfSize)

	// Clear each canvas to its correct background colour
	surface_set_target(canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

	surface_set_target(flow_canvas)
		draw_set_color(make_color_rgb(0,0,0))
		draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
		draw_set_color(c_white)
	surface_reset_target()

	surface_set_target(nm_canvas)
		draw_set_color(make_color_rgb(0,0,0))
		draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
		draw_set_color(c_white)
	surface_reset_target()

	surface_set_target(tNormsurf)
		draw_set_color(make_color_rgb(0,0,0))
		draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
		draw_set_color(c_white)
	surface_reset_target()

	surface_set_target(blurSurface)
		draw_clear_alpha(c_white, 1)
	surface_reset_target()

	surface_set_target(ao_canvas)
		draw_set_color(make_color_rgb(200,200,200))
		draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
		draw_set_color(c_white)
		if file_exists("ao.png") {
			if sprite_exists(aoSprite) sprite_delete(aoSprite) // free old before reloading
			aoSprite = sprite_add("ao.png", 0, 0, 0, 0, 0)
			}
		if sprite_exists(aoSprite) draw_sprite(aoSprite, 0, 0, 0)
	surface_reset_target()

	surface_set_target(color_canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

	surface_set_target(mask_canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

	surface_set_target(id_canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

	surface_set_target(depth_canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

	surface_set_target(frizz_canvas)
		draw_clear_alpha(c_black, 0)
	surface_reset_target()

/* end killSurfaces */
}
