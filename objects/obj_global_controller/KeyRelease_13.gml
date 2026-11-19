// obj_global_controller Key Release Enter (13). NOT USED (see Create).
// Would step through the rooms in project order and wrap to the first. This
// is the only code that could ever reach Room_Pathmaker or Room1, and since
// the object is never created, those two rooms are unreachable.
if room !=room_last then room_goto_next() else room_goto(room_first);

