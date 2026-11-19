// =============================================================================
// OBJECT o_pathMaker  -  flyaway-path experiment.  NOT REACHABLE in the program.
//
// Its only instance is in Room_Pathmaker, and nothing ever goes to that room:
// the only room_goto calls in the project are to Room_HSD and
// Room_PathEditing (checked across all objects and scripts). It is not created
// from code either. So none of these events run in the shipped build.
// Do not confuse it with obj_pathEdit / Room_PathEditing, the mixer curve
// editor, which IS used.
//
// What the experiment does: builds 2000 random wiggly open paths ("flyaway"
// hairs), each a start point plus 30 random points running down a 3800-long
// strand at quarter scale, and (in a Step event that is now entirely commented
// out) drew them to a preview surface.
//   Space  re-randomise one point on every path
//   Tab    add a point near the mouse height to every path
//   Esc    quit the whole program (game_end)
//
// It is self-contained: it reads and writes nothing on obj_surfaceDweller and
// has no part in save/load. Its "length" and "path" variables are its own.
// =============================================================================
//we will make paths that will act as flyaways
// these will need to be predefined but we can pick from them
// they should also have the ability to be resized
screenScale=0.25 // paths are built at a quarter of map size (4096 -> 1024 on screen)
n=0
points=30
pd=points // point deletion
length=3800
lpd=-1 // last point deleted
split =length/points // height of the band each point is placed in
paths=2000 // one path_add per path; they are never freed (no Clean Up event)
yStag=15 // ystagger
for (pa=0;pa<paths;pa++) // many paths
	{
	path[pa]=path_add()
	
	
		path_add_point(path[pa],0,0,100) // first point
		path_set_closed(path[pa],0) // open path: a strand, not a loop
		path_set_kind(path[pa],1)   // 1 = smooth curve through the points
		// now some random points

		// Point p: x within +/-25 (100 map pixels at quarter scale), y inside its
		// own band p*split..(p+1)*split so the points run downward in order,
		// plus up to yStag of extra jitter. p is an instance variable and is
		// left at 30 (points) afterwards; the Space event relies on that.
		for (p=0;p<points;p++) // quite a few
			{
				path_add_point(path[pa],irandom_range(-100*screenScale,100*screenScale),irandom_range((p*split)*screenScale,(p+1)*split*screenScale)+random_range(-yStag,yStag),100)
				
			}
	}
	
	

// draw paths to surfaces..

//
// 1024x1024 scratch surface. Only the commented-out Step code drew to it.
res=0.25
pathPreview=surface_create(4096*res,4096*res)
