/// @description MCP link - connect, run one command, export job
// =============================================================================
// obj_mcp : Step
// 1. Ctrl+Shift+F10 switches the link on / off.
// 2. One step of a map export, if one is running (mcp_export_step writes one
//    4096 PNG per frame, so no frame is long enough to trip the heartbeat).
// 3. While off or disconnected: retry every few seconds.
// 4. Otherwise take ONE queued line: check the pairing key, answer events
//    (ready / heartbeat) or run the command through mcp_dispatch() and send
//    the reply. A resent request (same id and text) gets the same reply.
// =============================================================================

if (keyboard_check(vk_control) && keyboard_check(vk_shift) && keyboard_check_pressed(vk_f10)) mcp_toggle();

if (instance_exists(obj_surfaceDweller)) mcp_export_step(obj_surfaceDweller.id);

if (!mcp_enabled) exit;

if (mcp_state == "off") {
	if (current_time >= mcp_retry_at) mcp_start();
	exit;
}

// Raw TCP may not report a disconnect: the bridge sends a heartbeat every 2 s.
if (current_time - mcp_last_rx > 15000) {
	mcp_stop(mcp_state == "ready" ? "TIMED OUT" : "");
	exit;
}
if (array_length(mcp_queue) == 0) exit;

var _wire = mcp_queue[0];
array_delete(mcp_queue, 0, 1);
var _msg;
try { _msg = json_parse(_wire); }
catch (_parse_error) { mcp_stop("BAD JSON"); exit; }
if (!is_struct(_msg) || !variable_struct_exists(_msg, "token") || !is_string(_msg.token) || _msg.token != mcp_token) {
	mcp_stop("KEY MISMATCH"); exit;
}
mcp_last_rx = current_time;

if (variable_struct_exists(_msg, "event")) {
	if (_msg.event == "ready" && mcp_state == "handshake" && variable_struct_exists(_msg, "protocol") && _msg.protocol == 1) {
		mcp_state = "ready";
		mcp_status = "LINKED";
		mcp_status_until = current_time + 6000;
	} else if (_msg.event == "heartbeat" && mcp_state == "ready") {
		mcp_send(json_stringify({ event : "heartbeat" }));
	} else {
		mcp_stop("BAD EVENT");
	}
	exit;
}
if (mcp_state != "ready") { mcp_stop("NOT PAIRED"); exit; }
if (!variable_struct_exists(_msg, "id") || !is_real(_msg.id) || _msg.id < 1 || _msg.id > 1000000000 || _msg.id != floor(_msg.id)
	|| !variable_struct_exists(_msg, "method") || !is_string(_msg.method)
	|| !variable_struct_exists(_msg, "args") || !is_struct(_msg.args)) {
	mcp_stop("BAD COMMAND"); exit;
}
if (_msg.id <= mcp_last_id) {
	if (_msg.id == mcp_last_id && _wire == mcp_last_wire) mcp_send(mcp_last_reply);
	else mcp_stop("STALE REQUEST");
	exit;
}
var _reply;
try {
	var _result = mcp_dispatch(_msg.method, _msg.args);
	_reply = { id : _msg.id, ok : true, result : _result };
} catch (_error) {
	var _message = is_struct(_error) && variable_struct_exists(_error, "message") ? string(_error.message) : string(_error);
	_reply = { id : _msg.id, ok : false, error : string_copy(_message, 1, 600) };
}
mcp_last_id = _msg.id;
mcp_last_wire = _wire;
mcp_last_reply = json_stringify(_reply);
if (string_byte_length(mcp_last_reply) > 65000) {
	mcp_last_reply = json_stringify({ id : _msg.id, ok : false, error : "The reply is too large." });
}
mcp_send(mcp_last_reply);
