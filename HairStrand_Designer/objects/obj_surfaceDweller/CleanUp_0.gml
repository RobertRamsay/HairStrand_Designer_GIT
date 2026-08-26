/// @description Free all surfaces on cleanup to prevent GPU memory leaks
killSurfaces()

// Also free preview surfaces
for (var _ps = 0; _ps < 11; _ps++) {
	if surface_exists(previewSurf[_ps]) surface_free(previewSurf[_ps])
}
draw_texture_flush()
