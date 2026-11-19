/// @description Space: re-randomise the last point of every path
// You can write your code in this editor
// o_pathMaker Key Press Space (32). NOT REACHABLE (see this object's Create).
// Moves ONE point on each of the 2000 paths to a new random position.
// Which point: index p. p is not set here; it is the instance variable left
// over from the Create loop, where it finished at 30 (= points), the last
// point Create added. So every press re-rolls that same end point.
// randomize() reseeds GameMaker's global random generator.
// lpd is only a counter shown in the Draw GUI text (+1 here, -1 on Tab).
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