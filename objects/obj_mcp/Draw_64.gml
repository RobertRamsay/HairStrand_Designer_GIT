/// @description MCP link - status tab
// =============================================================================
// obj_mcp : Draw GUI. A small tab hanging from the top edge of the preview
// canvas (centred on x 512) while the link is switched on: green MCP LINKED
// when Claude is connected, amber while waiting. After switching off it shows
// SWITCHED OFF for a few seconds, then nothing. Nothing at all while off.
// =============================================================================
var _ready = mcp_enabled && mcp_state == "ready";
var _notice = current_time < mcp_status_until ? mcp_status : "";
if (!mcp_enabled && _notice == "") exit;

var _text;
if (_ready) _text = "MCP LINKED";
else if (_notice != "") _text = "MCP " + _notice;
else _text = mcp_state == "off" ? "MCP WAITING" : "MCP CONNECTING";

// Leave the drawing state as it was found: other Draw GUI events rely on it.
var _oldFont = draw_get_font(), _oldH = draw_get_halign(), _oldV = draw_get_valign();
var _oldCol = draw_get_colour(), _oldA = draw_get_alpha();
draw_set_font(smallFont);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _w = string_width(_text) + 20;
var _h = 16;
var _x1 = 512 - (_w / 2), _x2 = 512 + (_w / 2);
draw_set_alpha(0.9);
draw_set_colour(_ready ? make_colour_rgb(25, 105, 65) : make_colour_rgb(120, 80, 25));
draw_rectangle(_x1, 0, _x2, _h, false);
draw_set_alpha(1);
draw_set_colour(_ready ? make_colour_rgb(90, 200, 130) : make_colour_rgb(230, 170, 80));
draw_rectangle(_x1, 0, _x2, _h, true);
draw_set_colour(c_white);
draw_text(512, (_h / 2) + 1, _text);
draw_set_font(_oldFont);
draw_set_halign(_oldH);
draw_set_valign(_oldV);
draw_set_colour(_oldCol);
draw_set_alpha(_oldA);
