/// @description Key F9 - load an image as the colour palette
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 120 = F9. Also tapped by the Palette button in Draw_64
//         and by the small import button in Draw_0 (UI BASE + PALETTE IMAGE).
// DOES  : frees the previous palette sprite, asks for an image file and loads it
//         into newPalImg. Draw_0 stretches it over the palette area (1645,542,
//         254x180) and the colour pickers in Step_2 read pixels straight off the
//         screen there, so any image works as a palette.
// WRITES: newPalImg (-1 = none; sprite_add returns -1 if the dialog is cancelled,
//         which simply removes the custom palette).
// NOTE  : not saved in the project or the autosave - reload it each session.
// -----------------------------------------------------------------------------
//load palette image
if sprite_exists(newPalImg)
	{
		sprite_flush(newPalImg)
		sprite_delete(newPalImg)
	}

var theImg=get_open_filename("","")
newPalImg=sprite_add(theImg,0,0,0,0,0)