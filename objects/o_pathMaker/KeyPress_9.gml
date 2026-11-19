// o_pathMaker Key Press Tab (9). NOT REACHABLE (see this object's Create).
// Appends one extra point to the END of every path: random x within +/-25,
// y about 50 above the mouse with up to yStag (15) of jitter. Points are only
// ever added, so repeated presses keep lengthening the paths.
// lpd is just the counter shown in the Draw GUI text.
for (pa=0;pa<paths;pa++) // many paths
	{

		{
		

		path_add_point(path[pa],irandom_range(-100*screenScale,100*screenScale),mouse_y-50+irandom_range(-yStag,yStag),100)
		
		}

		
	}
lpd-=1