/// @description  trace(...)
/// @param ...
// -----------------------------------------------------------------------------
// trace(a, b, ...)  -  debug print, part of the window_command_hook demo
//
// Joins its arguments with spaces, sends the line to the debug console and
// keeps the latest 8 lines in the list global.log (newest first).
//
// NOT PART OF HAIR STRAND DESIGNER PROPER. It appears to be sample code for
// the window_command_hook extension. The only callers are obj_test and
// window_command_toggle, and obj_test is not placed in any room, so in the
// shipped program this never runs.
//
// WARNING: global.log is created only in obj_test's Create event. Calling
// trace() from anywhere else will crash on the ds_list_insert line because the
// list does not exist. For a quick debug print use show_debug_message().
// -----------------------------------------------------------------------------
function trace() {
	var r = string(argument[0]);
	for (var i = 1; i < argument_count; i++) {
	    r += " " + string(argument[i]);
	}
	show_debug_message(r);
	ds_list_insert(global.log, 0, r);
	if (ds_list_size(global.log) > 8) {
	    ds_list_delete(global.log, 8);
	}



}
