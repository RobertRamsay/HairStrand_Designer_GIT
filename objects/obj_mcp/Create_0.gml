/// @description MCP link - set up
// =============================================================================
// obj_mcp : Hair Strand Designer's end of the MCP link (V1.97)
//
// Lets Claude Code (or any MCP client) drive the running app through
// tools/hsd-mcp/bridge.mjs. Adapted from the Amiga Dev Machine's obj_mcp.
//
//   Claude --stdio--> bridge.mjs --TCP--> broker (127.0.0.1:5180) <--TCP-- this object
//
// - The bridge keeps a random 64-hex pairing key in
//   %LOCALAPPDATA%\HairStrand_Designer\mcp\token (the app's save area). This
//   object reads the same file, so there is no pairing step. Every message in
//   both directions carries the key; anything else drops the link.
// - One JSON object per line. One command is handled per frame, on the main
//   thread, by mcp_dispatch() in scripts/mcpCommands.
// - OFF by default. Switched on by Ctrl+Shift+F10 (remembered in
//   HSD_Settings.ini [mcp] enabled) or for one session by launching with -mcp.
//   While on, a small tab at the top of the preview says MCP LINKED / WAITING.
// - Without a running bridge it only checks every few seconds.
//
// Created once by obj_surfaceDweller's Create event; persistent.
// Events: Step (connect, commands, export job), Async Networking (receive),
// Draw GUI (the tab), Clean Up (close the socket).
// =============================================================================

#macro MCP_VERSION "1.0.0"
#macro MCP_PORT 5180

mcp_socket = -1;
mcp_state = "off";             // off | connecting | handshake | ready
mcp_token = "";
mcp_rx = -1;                   // receive buffer for the line being assembled
mcp_rx_len = 0;
mcp_queue = [];                // complete lines waiting for the Step event
mcp_last_rx = 0;               // current_time of the last message (heartbeat check)
mcp_prev_step = current_time;  // when the last Step ran (long frames are not counted as silence)
mcp_last_id = 0;               // ids must increase per connection
mcp_last_wire = "";            // last command and its reply, for a resent request
mcp_last_reply = "";
mcp_retry_at = 0;
mcp_status = "";               // short notice shown on the tab for a few seconds
mcp_status_until = 0;
mcp_max_line = 32768;
mcp_dir = game_save_id + "mcp";
mcp_token_path = mcp_dir + "/token";
mcp_export_job = undefined;    // map export in progress (mcp_export_maps / mcp_export_step)

ini_open("HSD_Settings.ini");
mcp_enabled = ini_read_real("mcp", "enabled", 0) == 1;
ini_close();
for (var _i = 0; _i < parameter_count(); _i++)
	if string_lower(parameter_string(_i)) == "-mcp" mcp_enabled = true;

/// Ctrl+Shift+F10: switch the link on / off and remember it.
mcp_toggle = function() {
	mcp_enabled = !mcp_enabled;
	ini_open("HSD_Settings.ini");
	ini_write_real("mcp", "enabled", mcp_enabled ? 1 : 0);
	ini_close();
	if (!mcp_enabled) mcp_stop("SWITCHED OFF");
	else { mcp_stop("ON - WAITING"); mcp_retry_at = 0; }
};

/// Drop the connection (and say why on the tab, unless _reason is "").
mcp_stop = function(_reason) {
	if (mcp_socket >= 0) network_destroy(mcp_socket);
	mcp_socket = -1;
	if (mcp_rx >= 0 && buffer_exists(mcp_rx)) buffer_delete(mcp_rx);
	mcp_rx = -1;
	mcp_rx_len = 0;
	mcp_queue = [];
	mcp_token = "";
	mcp_state = "off";
	mcp_last_wire = "";
	mcp_last_reply = "";
	if (_reason != "") {
		mcp_status = _reason;
		mcp_status_until = current_time + 8000;
	}
	mcp_retry_at = current_time + 3000;
};

/// Send one line. Replies over 64 KB are refused (the bridge would drop them).
mcp_send = function(_text) {
	if (mcp_socket < 0) return false;
	var _buf = buffer_create(1024, buffer_grow, 1);
	buffer_write(_buf, buffer_text, _text + "\n");
	var _size = buffer_tell(_buf);
	if (_size > 65536) {
		buffer_delete(_buf);
		mcp_stop("REPLY TOO LARGE");
		return false;
	}
	var _sent = network_send_raw(mcp_socket, _buf, _size);
	buffer_delete(_buf);
	if (_sent != _size) {
		mcp_stop("SEND FAILED");
		return false;
	}
	return true;
};

/// The bridge's pairing key (64 hex digits), or "" when no bridge has run yet.
mcp_read_token = function() {
	if (!file_exists(mcp_token_path)) return "";
	var _f = file_text_open_read(mcp_token_path);
	if (_f < 0) return "";
	var _t = string_lower(string_trim(file_text_read_string(_f)));
	file_text_close(_f);
	if (string_length(_t) != 64) return "";
	for (var _i = 1; _i <= 64; _i++)
		if (string_pos(string_char_at(_t, _i), "0123456789abcdef") == 0) return "";
	return _t;
};

/// Try to connect to the broker. The answer arrives in Async Networking.
mcp_start = function() {
	var _token = mcp_read_token();
	if (_token == "") {
		mcp_retry_at = current_time + 5000;
		return;
	}
	mcp_token = _token;
	mcp_rx = buffer_create(mcp_max_line + 1, buffer_fixed, 1);
	mcp_rx_len = 0;
	mcp_queue = [];
	mcp_last_id = 0;
	mcp_last_wire = "";
	mcp_last_reply = "";
	mcp_last_rx = current_time;
	mcp_state = "connecting";
	mcp_socket = network_create_socket(network_socket_tcp);
	if (mcp_socket < 0 || network_connect_raw_async(mcp_socket, "127.0.0.1", MCP_PORT) < 0) {
		mcp_stop("");
	}
};
