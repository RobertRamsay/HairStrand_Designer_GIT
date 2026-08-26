/// @description Insert description here
// You can write your code in this editor
if obj_surfaceDweller.fullscreenMode==1 window_set_topmost(0)

locateImage=get_open_filename(".png", ""); // find the ong file to load

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

