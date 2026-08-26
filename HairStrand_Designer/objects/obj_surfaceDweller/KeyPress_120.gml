//load palette image
if sprite_exists(newPalImg)
	{
		sprite_flush(newPalImg)
		sprite_delete(newPalImg)
	}

var theImg=get_open_filename("","")
newPalImg=sprite_add(theImg,0,0,0,0,0)