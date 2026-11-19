// -----------------------------------------------------------------------------
// window_command_toggle(label, command)  -  window_command_hook demo helper
//
// Switches one title-bar command (minimise, maximise, move, close) between
// enabled and disabled, using the window_command_hook extension, and reports
// "<label> is now enabled." / "disabled." through trace().
//
//   label    text for the message only
//   command  one of the extension's window_command_* constants
//
// NOT PART OF HAIR STRAND DESIGNER PROPER. It appears to be sample code for
// the extension. Only obj_test calls it, and obj_test is not placed in any room,
// so this never runs. It also depends on trace(), which needs obj_test to have
// created global.log.
// -----------------------------------------------------------------------------
function window_command_toggle(argument0, argument1) {
	var cmd = argument1;
	var val = !window_command_get_active(cmd);
	window_command_set_active(cmd, val);
	var txt; if (val) txt = "en"; else txt = "dis";
	trace(argument0 + " is now " + txt + "abled.");



}
