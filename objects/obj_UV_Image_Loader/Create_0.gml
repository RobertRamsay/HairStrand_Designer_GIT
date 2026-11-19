/// @description obj_UV_Image_Loader: pick and load the UV trace image
// You can write your code in this editor
// =============================================================================
// OBJECT obj_UV_Image_Loader  -  the UV reference image overlay.  IN USE.
//
// Not placed in a room. doMainStep creates one (destroying any earlier one)
// when the UV loader button on the bottom bar is clicked (x 985-1017,
// y 1029-1059). Creating it IS the action: this Create event opens the file
// dialog straight away and loads the chosen PNG as a sprite.
//
// The object does not draw the image itself. obj_surfaceDweller Draw_0 does,
// over the canvas, reading three variables from here:
//   loadedSprite  the image (the project's placeholder sprite, sprite_null,
//                 if the dialog was cancelled)
//   sc            scale that makes the image 1024 wide, to fit the canvas.
//                 Height uses the same scale and Draw_0 shows a square region,
//                 so a non-square image will not fit exactly.
//   a             opacity 0-1, starts at 0.2, set with the small slider that
//                 this object's Draw event handles
//
// Nothing here is saved in the project file: the image has to be loaded again
// each session. The object is not persistent, so the overlay is also dropped
// when the mixer editor room is opened.
// Note: the sprite made by sprite_add is not deleted when the object is
// destroyed or replaced (there is no Clean Up event), so each new image
// loaded stays in memory until the program closes.
//
// Fullscreen mode keeps the window topmost, which would hide the file dialog,
// so topmost is dropped around the dialog and restored afterwards.
// =============================================================================
if obj_surfaceDweller.fullscreenMode==1 window_set_topmost(0)

locateImage=get_open_filename(".png", ""); // find the ong file to load ("" = cancelled)

if  locateImage!=""
	{
	loadedSprite=sprite_add(locateImage,0,0,0,0,0)
	//sc=0.25 // scale
	a=0.2 // alpha
	sc=1024/sprite_get_width(loadedSprite)
	}
	else
	{
		loadedSprite=sprite_null
			a=0.2 // alpha
			sc=1
	}
	
if obj_surfaceDweller.fullscreenMode==1 window_set_topmost(1) // and back

