/// @description Measure the gap to the mouse, then chase it
// You can write your code in this editor
// o_motionDetector Step. Order matters: the distance is measured BEFORE the
// point moves, so it is the lag left over from previous frames plus this
// frame's mouse movement. obj_surfaceDweller Step_1 reads distToMouse (> 20
// counts as "moving fast"). See the Create event for the full description.
distToMouse=point_distance(x,y,mouse_x,mouse_y)
x=lerp(x,mouse_x,spd)
y=lerp(y,mouse_y,spd)