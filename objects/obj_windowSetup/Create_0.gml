// =============================================================================
// OBJECT obj_windowSetup  -  start-up window sizing.  IN USE.
//
// The only instance is in PreRoom, the first room in the room order, so this
// is the first code to run when the program starts (and again after F6 /
// game_restart).
//
// It makes the window the size of the whole display, moves it to the top-left
// corner, waits 30 steps (alarm[0]) and then goes to Room_HSD, where
// obj_surfaceDweller takes over. The wait is presumably there so the window
// has finished resizing before the main room starts; the reason is not
// recorded.
//
// screenScaleX / screenScaleY (display size against the 1920x1080 design size)
// are stored on THIS instance only and it is gone once the room changes.
// obj_surfaceDweller works out its own copies in its Create; these two are
// not read by anything else.
// =============================================================================
window_set_size(display_get_width(),display_get_height())

screenScaleX =display_get_width()/1920	
screenScaleY =display_get_height()/1080
window_set_position(0,0) // slitbar

alarm[0]=30

