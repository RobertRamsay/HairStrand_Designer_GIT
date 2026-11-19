// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// canvasCheck - RECREATE ANY SURFACE THAT HAS GONE MISSING
// (The list of surfaces and who manages them is in setupCanvases.)
//
// CALLED BY  Step_2 (End Step) at its very top, and doMainStep - at its top
//            every step and again at the start of a render. So it runs at
//            least twice a step; when nothing is missing it costs 22
//            surface_exists() tests.
//
// WHAT IT DOES  For each of the eleven 4096 surfaces and the eleven 1024
//   preview surfaces: if it no longer exists, create it again and (4096 ones
//   only) fill it with its idle background. If anything was recreated it sets
//   forceUpdate=1, which previewUpdate reads as "redraw every set".
//
// WHAT IT CANNOT DO  It cannot bring back what was ON a lost surface. A lost
//   output map comes back blank, and nothing here changes its GenState, so a
//   map can still read as "generated" (state 2) while its canvas is empty -
//   press Generate again.
//
// ORDER OF EVENTS  Begin Step (Step_1) runs before this and has its own test:
//   if ANY of the eleven 4096 surfaces is missing it calls killSurfaces(),
//   which wipes and recreates ALL of them. So for the 4096 surfaces the blocks
//   below normally find nothing left to do; they matter for a surface lost
//   later in the same step, and for previewSurf[], which Step_1 does not test.
//
// ALPHA  These clears use draw_clear_alpha, but doMainStep leaves alpha writes
//   switched off (gpu_set_colorwriteenable) from the first End Step onward and
//   this script does not switch them back on.
//
// A recreated preview surface is not cleared here; previewClearSet clears it
// before it is redrawn.
// =============================================================================
function canvasCheck(){
// canvasCheck: called every Step_2.
// GML surfaces can be silently purged by the OS (alt-tab, window resize, VRAM pressure).
// This detects any lost surface and recreates only what's missing, then forces a redraw.
// NOTE: content is lost when a surface disappears - a full redraw (forceUpdate) is needed.

	var _surfaceLost = false

	// The legacy S-key event has finished by End Step, but a mouse release from
	// the file dialog can trigger doAutoSave() later in Step_2 and replace
	// fileCustom with Autosave.txt. Preserve the chosen project path first.
	if variable_instance_exists(id,"v185ManualSavePending") and v185ManualSavePending==1
		{
		if fileCustom!="" and fileCustom!="Autosave.txt" and file_exists(fileCustom)
			v185ManualSavePath=fileCustom
		}

	// Check and individually recreate each lost surface
	// Idle backgrounds, the same as killSurfaces: draw_clear_alpha black/0
	// (RGB mask, mask, ID, colour, depth, frizz), black rectangle (flow,
	// normal, tNormsurf), 200 grey + aoSprite (AO), white (blurSurface).
	if !surface_exists(canvas) {
		canvas = surface_create(surfSize, surfSize)
		surface_set_target(canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(flow_canvas) {
		flow_canvas = surface_create(surfSize, surfSize)
		surface_set_target(flow_canvas)
			draw_set_color(make_color_rgb(0,0,0))
			draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
			draw_set_color(c_white)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(mask_canvas) {
		mask_canvas = surface_create(surfSize, surfSize)
		surface_set_target(mask_canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(nm_canvas) {
		nm_canvas = surface_create(surfSize, surfSize)
		surface_set_target(nm_canvas)
			draw_set_color(make_color_rgb(0,0,0))
			draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
			draw_set_color(c_white)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(id_canvas) {
		id_canvas = surface_create(surfSize, surfSize)
		surface_set_target(id_canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(color_canvas) {
		color_canvas = surface_create(surfSize, surfSize)
		surface_set_target(color_canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(depth_canvas) {
		depth_canvas = surface_create(surfSize, surfSize)
		surface_set_target(depth_canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(ao_canvas) {
		ao_canvas = surface_create(surfSize, surfSize)
		surface_set_target(ao_canvas)
			draw_set_color(make_color_rgb(200,200,200))
			draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
			draw_set_color(c_white)
			if sprite_exists(aoSprite) draw_sprite(aoSprite, 0, 0, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(frizz_canvas) {
		frizz_canvas = surface_create(surfSize, surfSize)
		surface_set_target(frizz_canvas)
			draw_clear_alpha(c_black, 0)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(blurSurface) {
		blurSurface = surface_create(surfSize, surfSize)
		surface_set_target(blurSurface)
			draw_clear_alpha(c_white, 1)
		surface_reset_target()
		_surfaceLost = true
	}
	if !surface_exists(tNormsurf) {
		tNormsurf = surface_create(surfSize, surfSize)
		surface_set_target(tNormsurf)
			draw_set_color(make_color_rgb(0,0,0))
			draw_rectangle(0, 0, surfSize-1, surfSize-1, 0)
			draw_set_color(c_white)
		surface_reset_target()
		_surfaceLost = true
	}

	// Also check the preview surfaces
	for (var _ps = 0; _ps < 11; _ps++) {
		if !surface_exists(previewSurf[_ps]) {
			previewSurf[_ps] = surface_create(1024, 1024)
			_surfaceLost = true
		}
	}

	// If anything was lost, force a full preview redraw so content is regenerated
	// (previewUpdate turns forceUpdate into "restart every idle or half-drawn
	// set". This regenerates the PREVIEW only, not the 4096 output maps.)
	if _surfaceLost {
		forceUpdate  = 1
		//previewCanvasComplete = 0
	}

}
