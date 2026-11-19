/// @description Key Esc - ask to quit, or leave the mixer path editor
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 27 = Escape.
// DOES  : deselects every set (resetSets: setSelected[]=0, setSelectedID=-1), then
//         - in Room_HSD: raises exiting=true. Draw_0 (EXIT CONFIRMATION DIALOG) draws
//           the "Are you sure you want to quit? Y / N" box and handles Y / N / clicks.
//         - in Room_PathEditing: returns to Room_HSD. This object is persistent, so
//           all state survives the room change.
// SEE   : Other_10 (User Event 0) does the same for the on-screen quit button.
// -----------------------------------------------------------------------------
resetSets()
if room==Room_HSD
	{exiting=true}

if room==Room_PathEditing
	{room=Room_HSD;}