// =============================================================================
// OBJECT g  -  small persistent helper for obj_surfaceDweller.  IN USE.
//
// One instance is placed in Room_HSD and the object is marked persistent, so
// it is still there in Room_PathEditing (the mixer curve editor).
// It has no sprite and draws nothing. It does three jobs:
//
//   1. Create (this event): holds pathToEditID, a value passed between rooms.
//      obj_surfaceDweller Step_1 sets g.pathToEditID to 0, 1 or 2 (which mixer
//      name was clicked) just before room_goto(Room_PathEditing);
//      obj_pathEdit's Create reads it to open that mixer's curve.
//
//   2. Begin Step (Step_1): watches the S key to arm the "append the extra
//      blocks to the manual save" step, and watches the per-set colours to
//      schedule an autosave when one changes.
//
//   3. Key Press S (KeyPress_83): a second, backup copy of the S-key arming.
//
// Jobs 2 and 3 do not save anything themselves. They run inside
// "with (obj_surfaceDweller)", set flags on it and start its alarm[1]; the
// file work is in obj_surfaceDweller Alarm_1.
// The S test is done in Begin Step because Begin Step runs before the Key
// Press events of the same frame, so the flags are set before
// obj_surfaceDweller's S-key saver starts.
// =============================================================================
pathToEditID=0 // 0, 1 or 2 = mixer 1, 2 or 3
