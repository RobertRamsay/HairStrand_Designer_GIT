// =============================================================================
// OBJECT obj_global_controller  -  room-cycling controller from a shader demo.
// NOT USED (leftover).
//
// Checked: it is in no room and nothing creates or mentions it.
// It belongs to a shader showcase project, not to Hair Strand Designer: it
// checks that 19 demo shaders compiled, shows the FPS and room name, and
// moves to the next room on Enter.
//
// Most of the shaders named below are NOT in this project. Only
// shd_gaussian_horizontal and shd_gaussian_vertical exist here (the project's
// shaders are those two, shd_normal and shd_previewSmooth). So this event
// would fail if the object were ever created.
// Do not place it in a room.
// =============================================================================

if !shader_is_compiled(shd_bright_contrast) show_message("Your hardware doesn\'t support shader - shd_bright_contrast");
if !shader_is_compiled(shd_emboss) show_message("Your hardware doesn\'t support shader - shd_emboss");
if !shader_is_compiled(shd_gaussian_horizontal) show_message("Your hardware doesn\'t support shader - shd_gaussian_horizontal");
if !shader_is_compiled(shd_gaussian_vertical) show_message("Your hardware doesn\'t support shader - shd_gaussian_vertical");
if !shader_is_compiled(shd_greyscale) show_message("Your hardware doesn\'t support shaders - shd_greyscale");
if !shader_is_compiled(shd_invert) show_message("Your hardware doesn\'t support shader - shd_invert");
if !shader_is_compiled(shd_LED) show_message("Your hardware doesn\'t support shader - shd_LED");
if !shader_is_compiled(shd_magnify) show_message("Your hardware doesn\'t support shader - shd_magnify");
if !shader_is_compiled(shd_mosaic) show_message("Your hardware doesn\'t support shader - shd_mosaic");
if !shader_is_compiled(shd_posterization) show_message("Your hardware doesn\'t support shader - shd_posterization");
if !shader_is_compiled(shd_ripple) show_message("Your hardware doesn\'t support shader - shd_ripple");
if !shader_is_compiled(shd_scanlines) show_message("Your hardware doesn\'t support shader - shd_scanlines");
if !shader_is_compiled(shd_sepia) show_message("Your hardware doesn\'t support shader - shd_sepia");
if !shader_is_compiled(shd_shockwave) show_message("Your hardware doesn\'t support shader - shd_shockwave");
if !shader_is_compiled(shd_sketch) show_message("Your hardware doesn\'t support shader - shd_sketch");
if !shader_is_compiled(shd_thermal) show_message("Your hardware doesn\'t support shader - shd_thermal");
if !shader_is_compiled(shd_wave) show_message("Your hardware doesn\'t support shader - shd_wave");
if !shader_is_compiled(shd_radial_blur) show_message("Your hardware doesn\'t support shader - shd_radial_blur");
if !shader_is_compiled(shd_refraction) show_message("Your hardware doesn\'t support shader - shd_refraction");

draw_set_font(font0);

