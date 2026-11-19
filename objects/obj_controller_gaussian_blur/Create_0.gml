// =============================================================================
// OBJECT obj_controller_gaussian_blur  -  the original gaussian blur DEMO
// controller.  NOT USED (leftover).
//
// Checked: it is in no room and nothing creates or mentions it.
// It is where the program's blur came from: obj_surfaceDweller has its own
// copies of these variables (uni_resolution_*, uni_blur_amount_*,
// var_blur_amount) and uses the same two shaders, shd_gaussian_horizontal and
// shd_gaussian_vertical. For the blur the program actually applies, read
// obj_surfaceDweller, not this object. Editing anything here changes nothing.
//
// What the demo does: redirects view 0 into a surface (surf), then in Draw GUI
// blurs it in two passes, horizontal into final_surface and vertical onto the
// screen. A two-pass blur costs far less than a single 2D one.
//
// Oddity: the two blur_amount handles are crossed. uni_blur_amount_hoz is
// looked up on the VERTICAL shader and uni_blur_amount_vert on the HORIZONTAL
// one. Each is then used with the wrong shader in Draw GUI. It only works if
// both shaders happen to give "blur_amount" the same handle.
// The two surfaces are never freed (no Clean Up event).
// =============================================================================
draw_set_color(c_white);

uni_resolution_hoz = shader_get_uniform(shd_gaussian_horizontal,"resolution");
uni_resolution_vert = shader_get_uniform(shd_gaussian_vertical,"resolution");
var_resolution_x = camera_get_view_width(0);
var_resolution_y = camera_get_view_height(0);

uni_blur_amount_hoz = shader_get_uniform(shd_gaussian_vertical,"blur_amount");
uni_blur_amount_vert = shader_get_uniform(shd_gaussian_horizontal,"blur_amount");
var_blur_amount = 1.0;

shader_enabled = true;
final_surface = surface_create(camera_get_view_width(0), camera_get_view_height(0));

surf = surface_create(camera_get_view_width(0), camera_get_view_height(0));
view_set_surface_id(0, surf);