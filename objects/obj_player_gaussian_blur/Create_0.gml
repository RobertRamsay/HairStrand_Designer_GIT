// =============================================================================
// OBJECT obj_player_gaussian_blur  -  walking figure from the blur demo.
// NOT USED (leftover).
//
// Checked: it is in no room and nothing creates or mentions it. It was just
// something on screen for the gaussian blur demo to blur. It uses a sprite
// called spr_walk, which is not in this project, so it could not work if it
// were created. var_sprite_width / var_sprite_height are not read anywhere.
// =============================================================================
image_speed = 0.15;
x = view_get_wport(0)/2;
y = 544;

var_sprite_width = sprite_get_width(spr_walk);
var_sprite_height = sprite_get_height(spr_walk);

