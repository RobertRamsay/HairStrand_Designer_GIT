/// @description Free all surfaces on cleanup to prevent GPU memory leaks
// -----------------------------------------------------------------------------
// EVENT : Clean Up. Runs when the instance is destroyed, including game end and
//         game_restart() (F6, or the surface-loss restart in Step_1).
// DOES  : killSurfaces() frees the eleven 4096x4096 canvases, then the eleven
//         1024x1024 previewSurf[] are freed here and texture memory is flushed.
// WHY   : surfaces are not garbage collected, so they must be freed by hand.
// CHECK : killSurfaces() does not only free - it RE-CREATES and clears all eleven
//         canvases afterwards (it was written for the surface-loss recovery in
//         Step_1). Called from here, that leaves eleven fresh 4K surfaces
//         allocated as the instance dies. If memory climbs after each F6
//         restart, this is the first place to look.
// -----------------------------------------------------------------------------
killSurfaces()

// Also free preview surfaces
for (var _ps = 0; _ps < 11; _ps++) {
	if surface_exists(previewSurf[_ps]) surface_free(previewSurf[_ps])
}
draw_texture_flush()
