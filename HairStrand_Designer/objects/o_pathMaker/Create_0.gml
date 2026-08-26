//we will make paths that will act as flyaways
// these will need to be predefined but we can pick from them
// they should also have the ability to be resized
screenScale=0.25
n=0
points=30
pd=points // point deletion
length=3800
lpd=-1 // last point deleted
split =length/points
paths=2000
yStag=15 // ystagger
for (pa=0;pa<paths;pa++) // many paths
	{
	path[pa]=path_add()
	
	
		path_add_point(path[pa],0,0,100) // first point
		path_set_closed(path[pa],0)
		path_set_kind(path[pa],1)
		// now some random points

		for (p=0;p<points;p++) // quite a few
			{
				path_add_point(path[pa],irandom_range(-100*screenScale,100*screenScale),irandom_range((p*split)*screenScale,(p+1)*split*screenScale)+random_range(-yStag,yStag),100)
				
			}
	}
	
	

// draw paths to surfaces..

// 
res=0.25
pathPreview=surface_create(4096*res,4096*res)
