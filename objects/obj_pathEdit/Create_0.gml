/// @description obj_pathEdit: the mixer curve editor
// You can write your code in this editor
// =============================================================================
// OBJECT obj_pathEdit  -  the MIXER CURVE EDITOR.  IN USE.
//
// One instance is placed in Room_PathEditing and exists only there.
// The room is entered from obj_surfaceDweller: clicking a mixer name in the
// slider panel (Step_1, which first sets g.pathToEditID to 0/1/2) or pressing
// F8 (KeyPress_119). It is left with ENTER, ESC or the EXIT button, all of
// which set obj_surfaceDweller.img=9 and go back to Room_HSD.
//
// WHAT IT EDITS
//   obj_surfaceDweller.editingPath[0..2]: three GameMaker paths, one per
//   mixer, 11 points each. The points are changed in place with
//   path_change_point, so there is no "apply" step: the strands use the new
//   curve as soon as the main room is back.
//   The points are saved in the project file (22 lines per path, see
//   doAutoSave) and put back on load from pathLoadA/B/C.
//   Points are only ever moved here, never added or removed. Keep it that
//   way: the save format is fixed at 11 points per path.
//
// obj_surfaceDweller and g are persistent, so they are both still alive and
// running in this room. That is why the main UI is still drawn behind the
// editor and why clicks here can also reach the main UI's handlers.
//
// Events: Create (this), Draw (the editor itself: draws AND handles the
// mouse/keys), Draw GUI (the EXIT button and ESC).
// =============================================================================
editPoint=-1 // index of the point being dragged, -1 = none
mode=0       // 1 = mouse is over a point (also the sprite frame used for it)
pathPointer=g.pathToEditID // which mixer: 0, 1 or 2. Left at its last value when F8 opens the editor
