/// @description obj_curver: a draggable marker dot (not used)
// You can write your code in this editor
// =============================================================================
// OBJECT obj_curver  -  marker dot for a curve-plotting experiment.  NOT USED.
//
// Only obj_plotCurver creates these, and obj_plotCurver itself is in no room
// and is never created (checked), so no obj_curver ever exists.
// Each one would be a red dot dropped at the mouse position, which
// obj_plotCurver could then drag with the right button. The dots are not
// connected to the mixer curves (those are GameMaker paths edited by
// obj_pathEdit) or to anything that is saved.
// =============================================================================
x=mouse_x
y=mouse_y
