/// @description Insert description here
// You can write your code in this editor
//if keyboard_check_pressed(vk_f5)
randomize()

//length=mouse_y*4
split =length/points
lpd+=1
for (pa=0;pa<paths;pa++) // many paths
	{
	//	path_delete_point(path[pa],30-lpd) // delete end point 1 by 1...
	
	
	//R and D
	// path_delete_point()
	// remove points that are excessive ... 
	
	path_change_point(path[pa],p,irandom_range(-100*screenScale,100*screenScale),irandom_range((p*split)*screenScale,(p+1)*split*screenScale),100)
//if path_get_y(path[pa],p)>(mouse_y*4) path_delete_point(path[pa],p+1)
	}