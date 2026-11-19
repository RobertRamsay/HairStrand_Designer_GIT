// obj_controller_gaussian_blur Step. NOT USED (see Create).
// Raises / lowers the demo's blur amount by 0.01 a step while a key is held.
// The keys are tested as ord("<") and ord(">"), which are character codes
// rather than GameMaker key codes, so they may not match the keys printed on
// those symbols. The amount is not clamped and can go negative.
if keyboard_check(ord("<")) var_blur_amount += 0.01;
if keyboard_check(ord(">")) var_blur_amount -= 0.01;

