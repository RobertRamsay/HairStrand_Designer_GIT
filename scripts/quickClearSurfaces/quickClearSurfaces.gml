// =============================================================================
// quickClearSurfaces - EMPTY. THIS FUNCTION DOES NOTHING, AND NOTHING CALLS IT.
//
// The whole body is inside the comment block below. It freed the canvas of
// every map that was about to be regenerated (GenState 1, while 'generating').
// Today each map's background is repainted at render start instead, in
// doMainStep (MAP INITIALIZATION), without freeing the surface.
// Kept for reference only.
// =============================================================================
function quickClearSurfaces() {
/*
	if rgbMask_GenState==1 and generating==true {surface_free(canvas)}//;canvas=surface_create(4096,4096)} // out texture surface
	if color_GenState==1 and generating==true{surface_free(color_canvas)}//;color_canvas=surface_create(4096,4096)} // will fill out with ID strands in RGBCMY
	if ao_GenState==1 and generating==true{surface_free(ao_canvas)}//;ao_canvas=surface_create(4096,4096)} // will fill out with a depth pass
	if depth_GenState==1 and generating==true{surface_free(depth_canvas)}//;depth_canvas=surface_create(4096,4096)} // will fill out with a depth pass
	if flow_GenState==1 and generating==true{surface_free(flow_canvas)}//;flow_canvas=surface_create(4096,4096) }// out texture surface
	if id_GenState==1 and generating==true{surface_free(id_canvas)}//;id_canvas=surface_create(4096,4096)} // will fill out with ID strands in RGBCMY
	if mask_GenState==1 and generating==true{surface_free(mask_canvas)}//;mask_canvas=surface_create(4096,4096)} // out texture surface
	if norm_GenState==1 and generating==true{surface_free(nm_canvas)}//;nm_canvas=surface_create(4096,4096)} // out texture surface
	if frizz_GenState==1 and generating==true{surface_free(frizz_canvas)}//;frizz_canvas=surface_create(4096,4096)} // will fill out with a frizz pass
		
		*/		


}
