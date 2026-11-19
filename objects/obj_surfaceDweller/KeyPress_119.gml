/// @description Key F8 - open the mixer path editor
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 119 = F8. Also tapped by the Mixers button in Draw_64.
// DOES  : goes to Room_PathEditing, where the three mixer curves (editingPath[0..2])
//         are edited. Esc comes back (KeyPress_27).
// NOTE  : this entry does not set g.pathToEditID - clicking a mixer name in Step_1
//         does (0/1/2) - so the editor opens on whichever mixer was chosen last.
//         img is set to 1 first so the previewer (img==9) stops rebuilding strands
//         while the editor is open. It is NOT restored on return: press P to get
//         the previewer back.
// -----------------------------------------------------------------------------
img=1 // just move to this image to save performance
room_goto(Room_PathEditing)
