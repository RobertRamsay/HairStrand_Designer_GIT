/// @description User Event 0 - quit button pressed
// -----------------------------------------------------------------------------
// EVENT : User Event 0. Called with event_user(0) from Draw_0 (QUIT / ROOM SWITCH
//         BUTTON, top-left 1032..1077 x 9..51) when clicked in Room_HSD.
// DOES  : deselects every set and raises exiting=true, which makes Draw_0 show the
//         quit confirmation. Same effect as pressing Esc in Room_HSD (KeyPress_27).
// -----------------------------------------------------------------------------
resetSets()
exiting=true