/// @description Key V - disabled (old obj_save launcher)
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 86 = "V".
// DOES  : nothing. The body is commented out. It used to create obj_save, an older
//         stand-alone project saver. Saving is now the S key (KeyPress_83) plus the
//         blocks appended by Alarm 1.
// -----------------------------------------------------------------------------
/*
if instance_exists(obj_save) instance_destroy(obj_save)
instance_create_depth(0,0,0,obj_save)
*/
