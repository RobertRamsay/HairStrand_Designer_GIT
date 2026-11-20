/// @description MCP link - receive
// =============================================================================
// obj_mcp : Async Networking. Only this object's own socket.
// On connect: send "hello" with the pairing key. On data: split the bytes into
// lines (LF), queue each complete line for the Step event. Packets may hold
// part of a line or several lines; both work.
// =============================================================================
if (mcp_socket < 0 || async_load[? "id"] != mcp_socket) exit;
var _type = async_load[? "type"];
if (_type == network_type_non_blocking_connect) {
	if (async_load[? "succeeded"] != 1) { mcp_stop(""); exit; }    // no bridge yet: retry quietly
	mcp_state = "handshake";
	mcp_last_rx = current_time;
	mcp_send(json_stringify({ event : "hello", protocol : 1, token : mcp_token, application : "Hair Strand Designer" }));
	exit;
}
if (_type == network_type_disconnect) { mcp_stop(mcp_state == "ready" ? "LINK LOST" : ""); exit; }
if (_type != network_type_data) exit;
var _buf = async_load[? "buffer"];
var _size = async_load[? "size"];
if (_size < 0 || _size > mcp_max_line) { mcp_stop("PACKET TOO LARGE"); exit; }
for (var _i = 0; _i < _size; _i++) {
	var _byte = buffer_peek(_buf, _i, buffer_u8);
	if (_byte == 0) { mcp_stop("BAD DATA"); exit; }
	if (_byte == 10) {
		if (mcp_rx_len > 0) {
			if (array_length(mcp_queue) >= 64) { mcp_stop("QUEUE FULL"); exit; }
			buffer_poke(mcp_rx, mcp_rx_len, buffer_u8, 0);
			array_push(mcp_queue, buffer_peek(mcp_rx, 0, buffer_string));
			mcp_rx_len = 0;
		}
	} else {
		if (mcp_rx_len >= mcp_max_line) { mcp_stop("LINE TOO LONG"); exit; }
		buffer_poke(mcp_rx, mcp_rx_len, buffer_u8, _byte);
		mcp_rx_len++;
	}
}
