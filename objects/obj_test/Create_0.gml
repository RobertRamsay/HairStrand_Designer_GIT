// =============================================================================
// OBJECT obj_test  -  test harness for the window_command_hook extension.
// NOT USED (leftover). DO NOT PLACE IN A ROOM.
//
// Checked: it is in no room and nothing creates or mentions it.
// It appears to be the sample object for the window_command_hook extension
// (extensions/window_command_hook), which lets a program intercept or disable
// the title bar's minimise / maximise / restore / close commands. Nothing in
// obj_surfaceDweller or the project's scripts calls that extension apart from
// this object and its two helper scripts, trace and window_command_toggle.
//
// Why it must stay out of the rooms: its Step event ends with an
// unconditional game_end(), so the program would close on the first step.
//
// This Create makes global.log, the list trace() writes to (trace() crashes
// without it), and hooks the four window commands so that they are reported
// to the Step event instead of happening by themselves.
// =============================================================================
global.log = ds_list_create();
window_command_hook(window_command_minimize);
window_command_hook(window_command_maximize);
window_command_hook(window_command_restore);
window_command_hook(window_command_close);


