/// @description obj_plotCurver: curve-plotting experiment (not used)
// You can write your code in this editor
// =============================================================================
// OBJECT obj_plotCurver  -  place-and-drag-dots experiment.  NOT USED.
//
// Checked: it is in no room and nothing creates or mentions it. With it gone
// unused, obj_curver (the dots it makes) is unused too.
// What it would do: middle click or Space drops an obj_curver dot at the
// mouse; holding the right button grabs the nearest dot and drags it.
// It stores nothing and is not connected to the mixers or to save/load.
// =============================================================================

gotOne=false // true while a dot is being dragged
nearest=-1   // the dot being dragged, -1 = none