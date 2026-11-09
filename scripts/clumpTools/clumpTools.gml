// =============================================================================
// V1.96 CLUMPING + SHARED STRAND HELPERS
//
// Clumping groups the strands of a set into tresses. The set's root span is cut
// into COUNT equal bins by each strand's root position (preRandSpacing). The
// lowest-numbered strand in a bin is that tress's LEADER and is drawn untouched.
// Every other strand in the bin is pulled sideways toward the leader's path,
// starting at START along its length and reaching AMOUNT at the tip, so the
// tress gathers to a point the way real hair clumps.
// SCATTER loosens the pull per strand and lets a few strays escape entirely.
//
// Nothing here draws from the random stream. Membership and per-strand
// looseness come from the pre-random tables and a seed hash, so existing
// projects, the preview and the final render all stay in step.
// AMOUNT 0 turns the whole thing off at zero cost.
// =============================================================================


/// Work out clump membership for one set before its strands are drawn.
/// _count is the number of strands about to be drawn for this set.
/// _leadSize is how many points a leader path can hold (3900 / step, + a few).
/// Every array is created fresh here, never reused: the preview keeps one set
/// of them per strand set so that all sets can grow in side by side, and the
/// renderer must not scribble on those.
function clumpPrepareSet(_b, _count, _leadSize)
{
	clumpOnS = 0
	var _amt = setClumpAmtAdj[_b]
	if _amt <= 0 or _count < 2 return

	var _k = clamp(round(setClumpCountAdj[_b]), 1, 40)
	var _span = strandSetSpaceAdj[_b] * 10   // preRandSpacing runs 0.._span

	clumpLeadX    = array_create(_k, 0)
	clumpLeadV    = array_create(_k, -1)
	clumpLeadLen  = array_create(_k, 0)
	clumpLeadLife = array_create(_k, 1)
	clumpLeadStep = array_create(_k, 1)
	for (var _q = 0; _q < _k; _q++) clumpLeadX[_q] = array_create(_leadSize, 0)
	clumpBin    = array_create(_count, 0)
	clumpIsLead = array_create(_count, 0)
	clumpStick  = array_create(_count, 1)

	var _sc = setClumpScatterAdj[_b] / 40
	for (var _v = 0; _v < _count; _v++)
	{
		var _bin = 0
		if _span > 0 _bin = clamp(floor((preRandSpacing[_b, _v] / _span) * _k), 0, _k - 1)
		clumpBin[_v] = _bin

		// First strand into a bin leads it. Lower indices are always drawn first,
		// and the preview's strand cap only ever trims high indices, so the
		// preview and the render agree on every leader.
		if clumpLeadV[_bin] == -1 { clumpLeadV[_bin] = _v; clumpIsLead[_v] = 1 }
		else clumpIsLead[_v] = 0

		// Seed hash - the same family as the V1.90 noise phases, offset so the
		// two never line up.
		var _hA = (_v * 12.9898) + (_b * 78.233) + (randomSeedVal[_b] * 37.719) + 91.17
		var _h1 = frac(abs(sin(_hA)         * 43758.5453))
		var _h2 = frac(abs(sin(_hA + 29.41) * 43758.5453))
		var _stick = 1 - (_sc * 0.6 * _h1)
		if _h2 < _sc * 0.3 _stick *= 0.15   // a stray
		clumpStick[_v] = _stick
	}

	clumpOnS    = 1
	clumpAmtS   = _amt / 40
	clumpStartS = (setClumpStartAdj[_b] / 40) * 0.9   // never starts AT the tip
	clumpRampS  = 1 / max(1 - clumpStartS, 0.0001)
}


/// The three mixer paths only depend on the set and on n, never on the strand,
/// yet they were sampled with three path_get_x() calls at every point of every
/// strand. Sample them once per set into mixCacheX[n div _step] instead.
/// Same expressions as before, so the result is identical.
function mixerCacheBuild(_b, _step, _lvS)
{
	var _d1 = 4096 + (strandSetMixerOffsetAdj1[_b] * 100)
	var _d2 = 4096 + (strandSetMixerOffsetAdj2[_b] * 100)
	var _d3 = 4096 + (strandSetMixerOffsetAdj3[_b] * 100)
	var _m1 = strandSetMixerAdj1[_b]
	var _m2 = strandSetMixerAdj2[_b]
	var _m3 = strandSetMixerAdj3[_b]
	var _p0 = editingPath[0], _p1 = editingPath[1], _p2 = editingPath[2]

	// Strand life is clamped to 3900 by updatePreRands, so n < 3900.
	var _cnt = floor(3900 / _step) + 1
	mixCacheX = array_create(_cnt, 0)   // fresh, see clumpPrepareSet
	for (var _i = 0; _i < _cnt; _i++)
	{
		var _t = (_i * _step) - _lvS
		var xA = lerp(0, path_get_x(_p0, _t / _d1), _m1)
		var xB = lerp(0, path_get_x(_p1, _t / _d2), _m2)
		var xC = lerp(0, path_get_x(_p2, _t / _d3), _m3)
		mixCacheX[_i] = (lerp(lerp(xA, xB, 0.5), xC, 0.5) / _lvS) * 8
	}
}


// (The preview strand loop that uses the two helpers above lives in previewJob.)


// -----------------------------------------------------------------------------
// Clump parameter access by index, so one slider widget can drive all four.
// 0 Amount, 1 Count, 2 Start, 3 Scatter
// -----------------------------------------------------------------------------
function clumpGetGlobal(_k)
{
	switch (_k) { case 0: return clumpAmt; case 1: return clumpCount; case 2: return clumpStart; default: return clumpScatter }
}
function clumpSetGlobal(_k, _val)
{
	switch (_k) { case 0: clumpAmt = _val; break; case 1: clumpCount = _val; break; case 2: clumpStart = _val; break; default: clumpScatter = _val }
}
function clumpGetSet(_k, _s)
{
	switch (_k) { case 0: return setClumpAmtAdj[_s]; case 1: return setClumpCountAdj[_s]; case 2: return setClumpStartAdj[_s]; default: return setClumpScatterAdj[_s] }
}
function clumpSetSet(_k, _s, _val)
{
	switch (_k) { case 0: setClumpAmtAdj[_s] = _val; break; case 1: setClumpCountAdj[_s] = _val; break; case 2: setClumpStartAdj[_s] = _val; break; default: setClumpScatterAdj[_s] = _val }
}
function clumpGetOver(_k, _s)
{
	switch (_k) { case 0: return setClumpAmtOverrode[_s]; case 1: return setClumpCountOverrode[_s]; case 2: return setClumpStartOverrode[_s]; default: return setClumpScatterOverrode[_s] }
}
function clumpSetOver(_k, _s, _val)
{
	switch (_k) { case 0: setClumpAmtOverrode[_s] = _val; break; case 1: setClumpCountOverrode[_s] = _val; break; case 2: setClumpStartOverrode[_s] = _val; break; default: setClumpScatterOverrode[_s] = _val }
}

/// Clear one set's clump overrides and re-seed it from the globals.
function clumpResetSet(_s)
{
	for (var _k = 0; _k < 4; _k++) { clumpSetOver(_k, _s, 0); clumpSetSet(_k, _s, clumpGetGlobal(_k)) }
}

/// Re-seed every non-overridden set from the globals.
function clumpSyncSets()
{
	for (var _s = 0; _s < maxSets; _s++)
		for (var _k = 0; _k < 4; _k++)
			if clumpGetOver(_k, _s) == 0 clumpSetSet(_k, _s, clumpGetGlobal(_k))
}


/// One notched 0-40 slider + numeric box, behaving exactly like the Noise /
/// Fading rows (drag, click-to-type, per-set override, write-through).
/// _k: clump parameter index. _ex: track left. _ey: row centre. _tx: readout x.
function uiClumpSlider(_k, _ex, _ey, _tx)
{
	var _sel = setSelectedID
	var _val = (_sel != -1) ? clumpGetSet(_k, _sel) : clumpGetGlobal(_k)
	var over = 0
	var slx  = _ex + _val

	if mouse_x >= _ex and mouse_x <= _ex + 40 and mouse_y > _ey - 10 and mouse_y < _ey + 10
	{
		smallTip = clumpTip[_k]
		if mouse_check_button_pressed(mb_left) { nullify_sliderInterracts(); slider_interract_clump[_k] = true }
	}

	if mouse_check_button(mb_left) && slider_interract_clump[_k]
	{
		over = 1
		slx  = clamp(mouse_x, _ex, _ex + 40); pleaseGen = true
		reset_textBoxes()   // an open box would re-apply its stale text over this drag
		_val = clamp(slx - _ex, 0, 40)
		clumpApply(_k, _val)
	}

	var _overrode = (_sel != -1 and clumpGetOver(_k, _sel) != 0)
	draw_set_color(_overrode ? tbColOver : tbCol)
	draw_set_valign(fa_bottom); draw_set_halign(fa_left)
	draw_sprite(spr_smallNotch, over, clamp(slx, _ex, _ex + _val), _ey)
	if textBox_clump[_k] != 1 draw_text(_tx, _ey + 11, string(_val))
	draw_set_color(c_white)

	// click-to-type box
	if mouse_x > _tx - 6 and mouse_y > _ey - 10 and mouse_x < _tx + 23 and mouse_y < _ey + 10
	{
		smallTip = clumpTip[_k]
		if mouse_check_button_pressed(mb_left)
		{
			reset_textBoxes(); pleaseGen = true
			textBox_clump[_k] = 1
			str = string(_val)
		}
	}
	else { if mouse_check_button_pressed(mb_left) textBox_clump[_k] = 0 }

	if textBox_clump[_k] == 1
	{
		draw_set_color(_overrode ? tbColOver : tbCol)
		draw_set_valign(fa_bottom); draw_set_halign(fa_left)
		draw_text(_tx, _ey + 11, str)
		if tickytime > 0.5 and tickytime < 0.9
			draw_line_width(_tx + 2 + string_width(str), _ey - 9, _tx + 2 + string_width(str), _ey + 7, 2)
		draw_set_color(c_white)

		if string_length(str) < 2
		{
			switch (keyboard_key)
			{
				case vk_numpad0: str+="0"; keyboard_lastkey=-1; break
				case vk_numpad1: str+="1"; keyboard_lastkey=-1; break
				case vk_numpad2: str+="2"; keyboard_lastkey=-1; break
				case vk_numpad3: str+="3"; keyboard_lastkey=-1; break
				case vk_numpad4: str+="4"; keyboard_lastkey=-1; break
				case vk_numpad5: str+="5"; keyboard_lastkey=-1; break
				case vk_numpad6: str+="6"; keyboard_lastkey=-1; break
				case vk_numpad7: str+="7"; keyboard_lastkey=-1; break
				case vk_numpad8: str+="8"; keyboard_lastkey=-1; break
				case vk_numpad9: str+="9"; keyboard_lastkey=-1; break
			}
		}
		if keyboard_lastkey == 8
		{
			str = string_copy(str, 1, string_length(str) - 1)
			if str == "" str = "0"
			keyboard_lastkey = -1
		}
		else if keyboard_lastkey != -1 and string_length(str) < 2
		{
			if keyboard_lastkey >= 48 and keyboard_lastkey <= 57 str += keyboard_lastchar
			keyboard_lastkey = -1
		}
		if real(str) > 40 str = "40"
		clumpApply(_k, clamp(real(str), 0, 40))
		if keyboard_check_pressed(vk_enter) forceUpdate = 1
	}
}

/// Write a clump value to the selected set (as an override) or to the global
/// and every set that is not overriding it.
function clumpApply(_k, _val)
{
	if setSelectedID != -1
	{
		clumpSetSet(_k, setSelectedID, _val)
		clumpSetOver(_k, setSelectedID, 1)
		localUpdateSet = setSelectedID
	}
	else
	{
		clumpSetGlobal(_k, _val)
		for (var _s = 0; _s < maxSets; _s++)
			if clumpGetOver(_k, _s) != 1 clumpSetSet(_k, _s, _val)
	}
}


// -----------------------------------------------------------------------------
// SAVE / LOAD
// A self-describing "name:value;" block appended to the end of a project file.
// It is found by scanning for its marker rather than by line position, so it
// works for autosaves, manual saves, and any file written by an older build
// (which simply has no block, and so loads with clumping off).
// -----------------------------------------------------------------------------
#macro CLUMP_BLOCK_MARKER "V1.96 - Clumping"

function clumpWriteBlock(_f)
{
	file_text_write_string(_f, CLUMP_BLOCK_MARKER); file_text_writeln(_f)
	file_text_write_string(_f, "clumpAmt:"     + string(clumpAmt)     + ";"); file_text_writeln(_f)
	file_text_write_string(_f, "clumpCount:"   + string(clumpCount)   + ";"); file_text_writeln(_f)
	file_text_write_string(_f, "clumpStart:"   + string(clumpStart)   + ";"); file_text_writeln(_f)
	file_text_write_string(_f, "clumpScatter:" + string(clumpScatter) + ";"); file_text_writeln(_f)
	for (var _s = 0; _s < 11; _s++)
	{
		for (var _k = 0; _k < 4; _k++)
		{
			file_text_write_string(_f, "clumpO" + string(_k) + "_" + string(_s) + ":" + string(clumpGetOver(_k, _s)) + ";"); file_text_writeln(_f)
			file_text_write_string(_f, "clumpV" + string(_k) + "_" + string(_s) + ":" + string(clumpGetSet(_k, _s))  + ";"); file_text_writeln(_f)
		}
	}
	file_text_write_string(_f, "clumpEnd:1;"); file_text_writeln(_f)
}

/// Reset clumping to defaults, then restore it from _path if the file has a
/// clump block. Returns true if a block was found.
function clumpReadFile(_path)
{
	clumpAmt = 0; clumpCount = 6; clumpStart = 8; clumpScatter = 10
	for (var _rs = 0; _rs < maxSets; _rs++) clumpResetSet(_rs)

	var _found = false, _line = "", _colon = 0, _key = "", _num = "", _val = 0, _us = 0, _pk = 0, _ps = 0
	if _path == "" or !file_exists(_path) return false
	var _f = file_text_open_read(_path)
	if _f == -1 return false

	while !file_text_eof(_f)
	{
		_line = file_text_read_string(_f); file_text_readln(_f)
		if _line == CLUMP_BLOCK_MARKER { _found = true; break }
	}

	while _found and !file_text_eof(_f)
	{
		_line = file_text_read_string(_f); file_text_readln(_f)
		_colon = string_pos(":", _line)
		if _colon <= 0 break
		_key = string_copy(_line, 1, _colon - 1)
		_num = string_replace(string_copy(_line, _colon + 1, string_length(_line) - _colon), ";", "")
		_val = (string_digits(_num) == "") ? 0 : real(_num)

		if _key == "clumpEnd" break
		else if _key == "clumpAmt"     clumpAmt = clamp(_val, 0, 40)
		else if _key == "clumpCount"   clumpCount = clamp(_val, 0, 40)
		else if _key == "clumpStart"   clumpStart = clamp(_val, 0, 40)
		else if _key == "clumpScatter" clumpScatter = clamp(_val, 0, 40)
		else if string_length(_key) > 7 and (string_copy(_key, 1, 6) == "clumpO" or string_copy(_key, 1, 6) == "clumpV")
		{
			_us = string_pos("_", _key)
			_pk = real(string_copy(_key, 7, _us - 7))
			_ps = real(string_copy(_key, _us + 1, string_length(_key) - _us))
			if _pk >= 0 and _pk < 4 and _ps >= 0 and _ps < maxSets
			{
				if string_char_at(_key, 6) == "O" clumpSetOver(_pk, _ps, (_val != 0) ? 1 : 0)
				else clumpSetSet(_pk, _ps, clamp(_val, 0, 40))
			}
		}
	}
	file_text_close(_f)

	// The globals were read after the per-set values; fill in any set that is
	// not overriding a value with the loaded global.
	clumpSyncSets()
	return _found
}
