// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// -----------------------------------------------------------------------------
// resetSets()  -  deselect every strand set
//
// Runs in obj_surfaceDweller's scope. Called when the view changes (clicking a
// map row or the Previewer row in Draw_0), on Esc (KeyPress_27) and from User
// Event 0 (Other_10).
//
// setSelected[n] = 1 marks set n as the one being edited; setSelectedID is its
// index, or -1 for "no set selected, the sliders edit the globals". After this
// call the sliders are back on the globals. No values or override flags are
// changed, only the selection.
//
// "sets" is the highest set index in use (10, set in Create), so sets+1 = 11
// covers them all.
// Uses the instance variable ssr as its loop counter.
// -----------------------------------------------------------------------------
function resetSets(){
	for (ssr=0;ssr<sets+1;ssr++)
		{
		setSelected[ssr]=0
		}
		setSelectedID=-1
}