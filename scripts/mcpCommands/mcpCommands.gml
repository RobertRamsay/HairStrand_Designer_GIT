// =============================================================================
// V1.97 MCP COMMANDS
//
// What the MCP link (obj_mcp + tools/hsd-mcp/bridge.mjs) can do to the running
// Hair Strand Designer. obj_mcp receives one command per frame from the bridge
// and calls mcp_dispatch(); everything here acts on obj_surfaceDweller (_o).
//
// THE RULE: every command goes through the same variables, flags and events the
// UI uses, so the preview, the overrides, autosave and the project files all
// behave exactly as if the user had moved the slider or pressed the key.
//   - A slider change writes the global, copies it into every set that is not
//     overridden (or writes one set and sets its override flag), sets
//     pleaseGen, exactly like the Draw_0 slider blocks.
//   - The preview notices by itself (previewSetSig) and redraws.
//   - Generate sets the same flags as the G key.
//   - Save / load run the real S / L key events; only the file dialog is
//     skipped (mcpFileOverride).
//   - Map export runs one map per frame (mcp_export_step) so no single frame
//     takes long enough to trip the bridge's 15 s heartbeat.
//
// IF YOU ADD A SLIDER: add a line to mcp_param_table() and it is automatically
// readable, settable, resettable and listed by hsd_describe.
// IF YOU ADD A MAP: add it to mcp_map_table().
//
// Edits are refused (mcp_busy_reason) while the user is doing something that
// would fight with them: the start screen, the mixer editor room, the quit
// dialog, a render, a save / load / export in progress, or a held mouse button.
// Every edit deselects any set in the UI first, so the colour UI and the
// per-set arrays cannot disagree.
// =============================================================================


// -----------------------------------------------------------------------------
// TABLES
// -----------------------------------------------------------------------------

/// Every slider the link can change.
///   n   name used by the MCP tools
///   g   the global variable (what the slider shows with no set selected)
///   a   per-set array, "" = global only
///   o   per-set override flag array (1 = the set keeps its own value)
///   lo, hi  the slider's range (values are rounded to whole numbers)
///   pair / role  the two halves of a Min / Max row ("min" can never exceed "max")
///   d   description, shown by hsd_describe
function mcp_param_table()
{
	static _t = [
		{ n:"strands",          g:"strands",       a:"strandCountOverride",      o:"setCountOverrode",        lo:0,  hi:100,  pair:"", role:"", d:"Strands row: how many strands the set has. The render draws up to 100 per set; the preview shows up to the preview quality limit." },
		{ n:"length",           g:"length",        a:"strandLengthOverride",     o:"setLengthOverrode",       lo:38, hi:3800, pair:"", role:"", d:"Length row: strand length in map pixels (38-3800; the slider moves in steps of 38)." },
		{ n:"spacing",          g:"distancings",   a:"strandSetSpaceAdj",        o:"setSpacingOverrode",      lo:0,  hi:100,  pair:"", role:"", d:"Spacing row: how far apart the strands of a set sit (the width of the set)." },
		{ n:"distance",         g:"setDistance",   a:"",                         o:"",                        lo:0,  hi:100,  pair:"", role:"", d:"Distance row: how far apart the sets sit from each other. Global only." },
		{ n:"waviness",         g:"wavyness",      a:"strandSetWavynessAdj",     o:"setWaveynessOverrode",    lo:0,  hi:100,  pair:"", role:"", d:"Waviness row: amplitude of the wave along each strand." },
		{ n:"wave_freq_min",    g:"minFreq",       a:"strandSetWaveFreqMinAdj",  o:"setWaveFreqMinOverrode",  lo:0,  hi:40,   pair:"wave_freq_max", role:"min", d:"Wave Freq row, Min: lowest wave frequency a strand gets. Never above wave_freq_max." },
		{ n:"wave_freq_max",    g:"maxFreq",       a:"strandSetWaveFreqMaxAdj",  o:"setWaveFreqMaxOverrode",  lo:0,  hi:40,   pair:"wave_freq_min", role:"max", d:"Wave Freq row, Max: highest wave frequency a strand gets." },
		{ n:"tapering",         g:"tapering",      a:"strandSetTaperAdj",        o:"setTaperOverrode",        lo:0,  hi:100,  pair:"", role:"", d:"Tapering row: how strongly the strands converge toward a point below the set (narrows the whole set)." },
		{ n:"variation",        g:"lifeVariant",   a:"strandSetVariAdj",         o:"setVariOverrode",         lo:1,  hi:100,  pair:"", role:"", d:"Variation row: irregularity in strand length across the set." },
		{ n:"root_jitter",      g:"yRanRange",     a:"strandYRanRange",          o:"strandYRanRangeOverrode", lo:1,  hi:100,  pair:"", role:"", d:"Root Jitter row: vertical scatter of the root positions." },
		{ n:"thickness_min",    g:"minScale",      a:"setThickMinAdj",           o:"setThickMinOverrode",     lo:1,  hi:40,   pair:"thickness_max", role:"min", d:"Thick Rng row, Min: thinnest a strand may be. Never above thickness_max." },
		{ n:"thickness_max",    g:"maxScale",      a:"setThickMaxAdj",           o:"setThickMaxOverrode",     lo:1,  hi:40,   pair:"thickness_min", role:"max", d:"Thick Rng row, Max: thickest a strand may be." },
		{ n:"thick_adj_left",   g:"tipThick",      a:"setTipThickAdj",           o:"setTipThickOverrode",     lo:0,  hi:40,   pair:"", role:"", d:"Thick Adj row, LEFT slider (variable tipThick): shifts the thickness profile along the strand." },
		{ n:"thick_adj_right",  g:"rootThick",     a:"setRootThickAdj",          o:"setRootThickOverrode",    lo:0,  hi:40,   pair:"", role:"", d:"Thick Adj row, RIGHT slider (variable rootThick): shifts the thickness profile along the strand." },
		{ n:"thickness_variance", g:"thickVary",   a:"setThickVaryAdj",          o:"setThickVaryOverrode",    lo:0,  hi:100,  pair:"", role:"", d:"Thick Var row: how much thickness varies from strand to strand." },
		{ n:"fade_root",        g:"fadeIn",        a:"setFadeInAdj",             o:"setFadeInOverrode",       lo:1,  hi:40,   pair:"", role:"", d:"Fading row, Root: alpha fade-in length at the root (also fades the Mask map)." },
		{ n:"fade_tip",         g:"fadeOut",       a:"setFadeOutAdj",            o:"setFadeOutOverrode",      lo:1,  hi:40,   pair:"", role:"", d:"Fading row, Tip: alpha fade-out length at the tip." },
		{ n:"noise_amount",     g:"noiseAmt",      a:"setNoiseAmtAdj",           o:"setNoiseAmtOverrode",     lo:0,  hi:40,   pair:"", role:"", d:"Noise row, Amount: gradual left/right wander along each fibre. 0 = off." },
		{ n:"noise_frequency",  g:"noiseFreq",     a:"setNoiseFreqAdj",          o:"setNoiseFreqOverrode",    lo:0,  hi:40,   pair:"", role:"", d:"Noise row, Freq: how often it wanders. 10 is neutral." },
		{ n:"mixer1_amount",    g:"mixer1",        a:"strandSetMixerAdj1",       o:"setMixerAmt1Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 1 row, Amount: how much of mixer curve 1 is blended into the strand path." },
		{ n:"mixer1_offset",    g:"mixer1_offset", a:"strandSetMixerOffsetAdj1", o:"setMixerOfs1Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 1 row, Offset: where along the strand curve 1 is sampled." },
		{ n:"mixer2_amount",    g:"mixer2",        a:"strandSetMixerAdj2",       o:"setMixerAmt2Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 2 row, Amount." },
		{ n:"mixer2_offset",    g:"mixer2_offset", a:"strandSetMixerOffsetAdj2", o:"setMixerOfs2Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 2 row, Offset." },
		{ n:"mixer3_amount",    g:"mixer3",        a:"strandSetMixerAdj3",       o:"setMixerAmt3Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 3 row, Amount." },
		{ n:"mixer3_offset",    g:"mixer3_offset", a:"strandSetMixerOffsetAdj3", o:"setMixerOfs3Overrode",    lo:0,  hi:40,   pair:"", role:"", d:"Mixer 3 row, Offset." },
		{ n:"clump_amount",     g:"clumpAmt",      a:"setClumpAmtAdj",           o:"setClumpAmtOverrode",     lo:0,  hi:40,   pair:"", role:"", d:"Clumping row, Amount: how tightly each tress pulls together. 0 = clumping off." },
		{ n:"clump_count",      g:"clumpCount",    a:"setClumpCountAdj",         o:"setClumpCountOverrode",   lo:0,  hi:40,   pair:"", role:"", d:"Clumping row, Count: how many tresses each set splits into (0 and 1 both mean one)." },
		{ n:"clump_start",      g:"clumpStart",    a:"setClumpStartAdj",         o:"setClumpStartOverrode",   lo:0,  hi:40,   pair:"", role:"", d:"Clump Var row, Start: how far down the strand the gathering begins." },
		{ n:"clump_scatter",    g:"clumpScatter",  a:"setClumpScatterAdj",       o:"setClumpScatterOverrode", lo:0,  hi:40,   pair:"", role:"", d:"Clump Var row, Scatter: loosens the pull and lets a few strays escape." },
		{ n:"root_coverage",    g:"rootPosition",  a:"",                         o:"",                        lo:0,  hi:100,  pair:"", role:"", d:"Root Coverage (colour panel): how far up the strand the Root Tone reaches. Global only." },
		{ n:"tip_coverage",     g:"tipPosition",   a:"",                         o:"",                        lo:0,  hi:100,  pair:"", role:"", d:"Tip Coverage (colour panel): how far up from the end the Tip Tone reaches. Global only." }
	];
	return _t;
}

/// The nine maps. d = tick-box flag, s = GenState (0 off, 1 due, 2 generated),
/// c = the 4096x4096 canvas, x = file name suffix (the same ones S uses).
function mcp_map_table()
{
	static _t = [
		{ n:"rgb_mask", d:"doRGB",   s:"rgbMask_GenState", c:"canvas",       x:"_RGBMask" },
		{ n:"normal",   d:"doNorm",  s:"norm_GenState",    c:"nm_canvas",    x:"_Normal"  },
		{ n:"mask",     d:"doMask",  s:"mask_GenState",    c:"mask_canvas",  x:"_Mask"    },
		{ n:"color",    d:"doColor", s:"color_GenState",   c:"color_canvas", x:"_Color"   },
		{ n:"id",       d:"doID",    s:"id_GenState",      c:"id_canvas",    x:"_ID"      },
		{ n:"depth",    d:"doDepth", s:"depth_GenState",   c:"depth_canvas", x:"_Depth"   },
		{ n:"flow",     d:"doFlow",  s:"flow_GenState",    c:"flow_canvas",  x:"_Flow"    },
		{ n:"ao",       d:"doAO",    s:"ao_GenState",      c:"ao_canvas",    x:"_AO"      },
		{ n:"frizz",    d:"doFrizz", s:"frizz_GenState",   c:"frizz_canvas", x:"_Frizz"   }
	];
	return _t;
}

/// The four colours each set has, plus the global they follow.
function mcp_colour_table()
{
	static _t = [
		{ n:"variation1", g:"globalColVarA", a:"setColVarA", o:"setColVarAOverrode", c:"customColVarA", l:"colourUiLastA"    },
		{ n:"variation2", g:"globalColVarB", a:"setColVarB", o:"setColVarBOverrode", c:"customColVarB", l:"colourUiLastB"    },
		{ n:"root",       g:"globalRootCol", a:"setRootCol", o:"setRootColOverrode", c:"customRootCol", l:"colourUiLastRoot" },
		{ n:"tip",        g:"globalTipCol",  a:"setTipCol",  o:"setTipColOverrode",  c:"customTipCol",  l:"colourUiLastTip"  }
	];
	return _t;
}

function mcp_find(_table, _name)
{
	for (var _i = 0; _i < array_length(_table); _i++) if _table[_i].n == _name return _table[_i];
	return undefined;
}


// -----------------------------------------------------------------------------
// SMALL HELPERS
// -----------------------------------------------------------------------------

function mcp_has(_s, _k) { return is_struct(_s) and variable_struct_exists(_s, _k) }

/// A whole number argument, checked against a range.
function mcp_int(_args, _k, _default, _lo, _hi)
{
	if !mcp_has(_args, _k) return _default;
	var _v = _args[$ _k];
	if !is_real(_v) throw _k + " must be a number.";
	if _v < _lo or _v > _hi throw _k + " must be " + string(_lo) + " to " + string(_hi) + ".";
	return round(_v);
}

function mcp_bool(_args, _k, _default)
{
	if !mcp_has(_args, _k) return _default;
	var _v = _args[$ _k];
	if is_bool(_v) return _v;
	if is_real(_v) return _v != 0;
	throw _k + " must be true or false.";
}

function mcp_str(_args, _k, _default)
{
	if !mcp_has(_args, _k) return _default;
	var _v = _args[$ _k];
	if !is_string(_v) throw _k + " must be text.";
	return _v;
}

/// The set argument: -1 (or missing) = the global value, 0-10 = one set.
function mcp_set_arg(_args)
{
	return mcp_int(_args, "set", -1, -1, 10);
}

/// Colour -> "RRGGBB".
function mcp_hex(_c)
{
	var _h = "0123456789ABCDEF";
	var _out = "";
	var _parts = [colour_get_red(_c), colour_get_green(_c), colour_get_blue(_c)];
	for (var _i = 0; _i < 3; _i++)
		_out += string_char_at(_h, (_parts[_i] div 16) + 1) + string_char_at(_h, (_parts[_i] mod 16) + 1);
	return _out;
}

/// "RRGGBB" or "#RRGGBB" -> colour. Throws on anything else.
function mcp_parse_hex(_k, _text)
{
	if !is_string(_text) throw _k + " must be a hex colour like \"8A5A2B\".";
	var _t = string_upper(string_replace(_text, "#", ""));
	if string_length(_t) != 6 throw _k + " must be six hex digits, like \"8A5A2B\".";
	var _h = "0123456789ABCDEF";
	var _v = [0, 0, 0];
	for (var _i = 0; _i < 3; _i++)
	{
		var _a = string_pos(string_char_at(_t, (_i * 2) + 1), _h) - 1;
		var _b = string_pos(string_char_at(_t, (_i * 2) + 2), _h) - 1;
		if _a < 0 or _b < 0 throw _k + " must be six hex digits, like \"8A5A2B\".";
		_v[_i] = (_a * 16) + _b;
	}
	return make_color_rgb(_v[0], _v[1], _v[2]);
}

/// Write one element of a per-set array on _o. [@ ] writes into the
/// instance's own array (copy-on-write arrays are on in this project).
function mcp_aset(_o, _arrayName, _i, _v)
{
	var _arr = variable_instance_get(_o, _arrayName);
	_arr[@ _i] = _v;
}

function mcp_aget(_o, _arrayName, _i)
{
	var _arr = variable_instance_get(_o, _arrayName);
	return _arr[_i];
}

function mcp_state_name(_s) { return (_s == 2) ? "generated" : ((_s == 1) ? "due" : "off") }


// -----------------------------------------------------------------------------
// STATE CHECKS
// -----------------------------------------------------------------------------

function mcp_rendering(_o) { return _o.doOnce or instance_exists(obj_wait) }

function mcp_preview_ready(_o)
{
	if !variable_instance_exists(_o, "pvState") return false;
	for (var _b = 0; _b <= _o.sets; _b++) if _o.pvState[_b] != 0 return false;
	return true;
}

function mcp_save_pending(_o) { return variable_instance_exists(_o, "v185ManualSavePending") and _o.v185ManualSavePending == 1 }
function mcp_load_pending(_o) { return _o.loading or (variable_instance_exists(_o, "v185LoadRecoveryPending") and _o.v185LoadRecoveryPending == 1) }

/// Why Hair Strand Designer cannot be changed right now, or "" when it can.
function mcp_busy_reason(_o)
{
	if room != Room_HSD return "the mixer curve editor is open (press Esc or EXIT in it)";
	if _o.firstTime return "the start screen is showing: use hsd_start_session first";
	if _o.exiting return "the quit dialog is open";
	if mcp_rendering(_o) return "a render is running (hsd_generate_status)";
	if is_struct(mcp_export_job) and mcp_export_job.active return "a map export is running";
	if mcp_save_pending(_o) or _o.saving return "a project save is finishing";
	if mcp_load_pending(_o) return "a project load is finishing";
	if !variable_instance_exists(_o, "setColourOverridesReady") return "the app is still starting";
	if mouse_check_button(mb_any) return "a mouse button is held in the app";
	return "";
}

function mcp_require_idle(_o)
{
	var _why = mcp_busy_reason(_o);
	if _why != "" throw "Hair Strand Designer is busy: " + _why + ".";
}

/// Before an edit: close typed number boxes, release slider drags and
/// deselect any set, then make the colour UI show the globals so Step_0 does
/// not mistake the next colour write for a user edit.
function mcp_prepare_edit(_o)
{
	with (_o)
	{
		reset_textBoxes();
		nullify_sliderInterracts();
		resetSets();
	}
	mcp_sync_colour_ui(_o);
}

function mcp_sync_colour_ui(_o)
{
	var _ct = mcp_colour_table();
	for (var _i = 0; _i < 4; _i++)
	{
		var _g = variable_instance_get(_o, _ct[_i].g);
		variable_instance_set(_o, _ct[_i].c, _g);
		variable_instance_set(_o, _ct[_i].l, _g);
	}
	_o.colourUiLastSet = -1;
}

/// After an edit that changes how the hair looks: mark the maps stale (the
/// same flag every slider sets) and autosave, as a mouse release would.
function mcp_after_edit(_o, _mapsStale)
{
	if _mapsStale _o.pleaseGen = true;
	// as when the user moves a slider: show the Previewer so the change is visible
	if _mapsStale and _o.img != 9 { _o.currentMapPreview = _o.img; _o.img = 9 }
	with (_o) doAutoSave();
}


// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------

/// Min / Max rows: put the non-overridden sets of a pair back in step with
/// the globals, keeping min <= max inside each set (same rule as the UI).
function mcp_pair_sync(_o, _pMin, _pMax, _onlySet)
{
	var _gMin = variable_instance_get(_o, _pMin.g);
	var _gMax = variable_instance_get(_o, _pMax.g);
	for (var _s = 0; _s < _o.maxSets; _s++)
	{
		if _onlySet != -1 and _s != _onlySet continue;
		var _ovMin = mcp_aget(_o, _pMin.o, _s) == 1;
		var _ovMax = mcp_aget(_o, _pMax.o, _s) == 1;
		if !_ovMin and !_ovMax { mcp_aset(_o, _pMin.a, _s, _gMin); mcp_aset(_o, _pMax.a, _s, _gMax) }
		else if !_ovMin mcp_aset(_o, _pMin.a, _s, min(_gMin, mcp_aget(_o, _pMax.a, _s)));
		else if !_ovMax mcp_aset(_o, _pMax.a, _s, max(_gMax, mcp_aget(_o, _pMin.a, _s)));
	}
}

/// A single (non-pair) global value: write it and copy it into every set that
/// is not overridden, exactly like the slider with no set selected.
function mcp_apply_global(_o, _p, _v)
{
	variable_instance_set(_o, _p.g, _v);
	if _p.a == "" return;
	for (var _s = 0; _s < _o.maxSets; _s++)
		if mcp_aget(_o, _p.o, _s) != 1 mcp_aset(_o, _p.a, _s, _v);
}

/// The value a set currently uses for parameter _p.
function mcp_param_value(_o, _p, _s)
{
	if _s == -1 or _p.a == "" return variable_instance_get(_o, _p.g);
	return mcp_aget(_o, _p.a, _s);
}

/// hsd_set_params: { set, values: {name: number}, clear: [names] }
function mcp_set_params(_o, _args)
{
	mcp_require_idle(_o);
	var _set = mcp_set_arg(_args);
	var _values = mcp_has(_args, "values") ? _args.values : {};
	var _clear = mcp_has(_args, "clear") ? _args.clear : [];
	if !is_struct(_values) throw "values must be an object of name: number.";
	if !is_array(_clear) throw "clear must be a list of names.";
	var _names = variable_struct_get_names(_values);
	if array_length(_names) == 0 and array_length(_clear) == 0 throw "Nothing to change: give values and / or clear.";

	// Check everything first, so a bad name changes nothing.
	var _table = mcp_param_table();
	var _todo = {};
	for (var _i = 0; _i < array_length(_names); _i++)
	{
		var _k = _names[_i];
		var _v = _values[$ _k];
		if !is_real(_v) throw "values." + _k + " must be a number.";
		if _k == "seed" { _todo[$ _k] = clamp(round(_v), 0, 2147483647); continue }
		if _k == "x_offset" or _k == "y_offset"
		{
			if _set == -1 throw _k + " is per set: give set 0-10.";
			_todo[$ _k] = clamp(round(_v), -4096, 4096); continue;
		}
		var _p = mcp_find(_table, _k);
		if is_undefined(_p) throw "Unknown parameter " + _k + " (hsd_describe lists them).";
		if _set != -1 and _p.a == "" throw _k + " is global only: leave set out.";
		_todo[$ _k] = clamp(round(_v), _p.lo, _p.hi);
	}
	for (var _i = 0; _i < array_length(_clear); _i++)
	{
		var _k = _clear[_i];
		if !is_string(_k) throw "clear must be a list of names.";
		if _set == -1 throw "clear needs a set (it drops that set's override).";
		if _k != "seed" and _k != "x_offset" and _k != "y_offset"
		{
			var _p = mcp_find(_table, _k);
			if is_undefined(_p) throw "Unknown parameter " + _k + ".";
			if _p.a == "" throw _k + " is global only, so there is nothing to clear.";
		}
	}
	// Both halves of a Min / Max row given together must make sense.
	if mcp_has(_todo, "wave_freq_min") and mcp_has(_todo, "wave_freq_max") and _todo.wave_freq_min > _todo.wave_freq_max throw "wave_freq_min is above wave_freq_max.";
	if mcp_has(_todo, "thickness_min") and mcp_has(_todo, "thickness_max") and _todo.thickness_min > _todo.thickness_max throw "thickness_min is above thickness_max.";

	mcp_prepare_edit(_o);
	var _notes = [];

	// Clears first, then the new values.
	for (var _i = 0; _i < array_length(_clear); _i++)
	{
		var _k = _clear[_i];
		if _k == "seed" { _o.randomOverride[_set] = 0; continue }
		if _k == "x_offset" { _o.xOffset[_set] = 0; _o.strandXOffset[_set] = 0; continue }
		if _k == "y_offset" { _o.yOffset[_set] = 0; _o.strandYOffset[_set] = 0; continue }
		var _p = mcp_find(_table, _k);
		mcp_aset(_o, _p.o, _set, 0);
		if _p.pair != ""
		{
			var _q = mcp_find(_table, _p.pair);
			if _p.role == "min" mcp_pair_sync(_o, _p, _q, _set); else mcp_pair_sync(_o, _q, _p, _set);
		}
		else mcp_aset(_o, _p.a, _set, variable_instance_get(_o, _p.g));
	}

	var _done = {};
	var _keys = variable_struct_get_names(_todo);
	for (var _i = 0; _i < array_length(_keys); _i++)
	{
		var _k = _keys[_i];
		var _v = _todo[$ _k];
		if _done[$ _k] == true continue;

		if _k == "seed"
		{
			if _set == -1
			{
				// Same as typing a seed with F1 and no set selected.
				_o.seedVal = _v;
				random_set_seed(_v);
				for (var _s = 0; _s < _o.maxSets; _s++) _o.randomSeedVal[_s] = _v;
				_o.seedUpdate = 1;
			}
			else { _o.randomSeedVal[_set] = _v; _o.randomOverride[_set] = 1 }
			_done[$ _k] = true; continue;
		}
		if _k == "x_offset" { _o.xOffset[_set] = _v; _o.strandXOffset[_set] = _v; _done[$ _k] = true; continue }
		if _k == "y_offset" { _o.yOffset[_set] = _v; _o.strandYOffset[_set] = _v; _done[$ _k] = true; continue }

		var _p = mcp_find(_table, _k);
		if _p.pair == ""
		{
			if _set == -1 mcp_apply_global(_o, _p, _v);
			else { mcp_aset(_o, _p.a, _set, _v); mcp_aset(_o, _p.o, _set, 1) }
			_done[$ _k] = true; continue;
		}

		// A Min / Max row. Both halves may have been given.
		var _q = mcp_find(_table, _p.pair);
		var _pMin = (_p.role == "min") ? _p : _q;
		var _pMax = (_p.role == "min") ? _q : _p;
		var _hasMin = mcp_has(_todo, _pMin.n), _hasMax = mcp_has(_todo, _pMax.n);
		if _set == -1
		{
			var _gMin = variable_instance_get(_o, _pMin.g), _gMax = variable_instance_get(_o, _pMax.g);
			if _hasMin and _hasMax { _gMin = _todo[$ _pMin.n]; _gMax = _todo[$ _pMax.n] }
			else if _hasMin _gMin = min(_todo[$ _pMin.n], _gMax);
			else _gMax = max(_todo[$ _pMax.n], _gMin);
			variable_instance_set(_o, _pMin.g, _gMin);
			variable_instance_set(_o, _pMax.g, _gMax);
			mcp_pair_sync(_o, _pMin, _pMax, -1);
		}
		else
		{
			var _sMin = mcp_aget(_o, _pMin.a, _set), _sMax = mcp_aget(_o, _pMax.a, _set);
			if _hasMin and _hasMax { _sMin = _todo[$ _pMin.n]; _sMax = _todo[$ _pMax.n]; mcp_aset(_o, _pMin.o, _set, 1); mcp_aset(_o, _pMax.o, _set, 1) }
			else if _hasMin { _sMin = min(_todo[$ _pMin.n], _sMax); mcp_aset(_o, _pMin.o, _set, 1) }
			else { _sMax = max(_todo[$ _pMax.n], _sMin); mcp_aset(_o, _pMax.o, _set, 1) }
			mcp_aset(_o, _pMin.a, _set, _sMin);
			mcp_aset(_o, _pMax.a, _set, _sMax);
		}
		_done[$ _pMin.n] = true; _done[$ _pMax.n] = true;
	}

	// Report what each named value is now (it may have been clamped).
	var _now = {};
	var _all = array_concat(_keys, _clear);
	for (var _i = 0; _i < array_length(_all); _i++)
	{
		var _k = _all[_i];
		if _k == "seed" _now[$ _k] = (_set == -1) ? _o.seedVal : _o.randomSeedVal[_set];
		else if _k == "x_offset" _now[$ _k] = _o.xOffset[_set];
		else if _k == "y_offset" _now[$ _k] = _o.yOffset[_set];
		else _now[$ _k] = mcp_param_value(_o, mcp_find(_table, _k), _set);
		if _todo[$ _k] != undefined and _now[$ _k] != _todo[$ _k] array_push(_notes, _k + " was limited to " + string(_now[$ _k]) + " by its Min / Max partner.");
	}
	mcp_after_edit(_o, true);
	return { set : _set, now : _now, notes : _notes, maps_stale : true };
}


// -----------------------------------------------------------------------------
// COLOURS
// -----------------------------------------------------------------------------

/// hsd_set_colours: { set, background, variation1, variation2, root, tip, clear }
function mcp_set_colours(_o, _args)
{
	mcp_require_idle(_o);
	var _set = mcp_set_arg(_args);
	var _ct = mcp_colour_table();
	var _clear = mcp_has(_args, "clear") ? _args.clear : [];
	if !is_array(_clear) throw "clear must be a list of colour names.";
	if array_length(_clear) > 0 and _set == -1 throw "clear needs a set.";

	// Parse everything first.
	var _new = {};
	for (var _i = 0; _i < 4; _i++) if mcp_has(_args, _ct[_i].n) _new[$ _ct[_i].n] = mcp_parse_hex(_ct[_i].n, _args[$ _ct[_i].n]);
	var _bg = mcp_has(_args, "background");
	var _bgCol = _bg ? mcp_parse_hex("background", _args.background) : 0;
	if _bg and _set != -1 throw "background is global only: leave set out.";
	for (var _i = 0; _i < array_length(_clear); _i++) if is_undefined(mcp_find(_ct, _clear[_i])) throw "Unknown colour " + string(_clear[_i]) + ".";
	if !_bg and array_length(variable_struct_get_names(_new)) == 0 and array_length(_clear) == 0 throw "Nothing to change.";

	mcp_prepare_edit(_o);
	if _bg _o.colrBack = _bgCol;

	for (var _i = 0; _i < array_length(_clear); _i++)
	{
		var _c = mcp_find(_ct, _clear[_i]);
		mcp_aset(_o, _c.o, _set, 0);
		mcp_aset(_o, _c.a, _set, variable_instance_get(_o, _c.g));
	}
	for (var _i = 0; _i < 4; _i++)
	{
		var _c = _ct[_i];
		if !mcp_has(_new, _c.n) continue;
		var _v = _new[$ _c.n];
		if _set == -1
		{
			variable_instance_set(_o, _c.g, _v);
			for (var _s = 0; _s < _o.maxSets; _s++) if mcp_aget(_o, _c.o, _s) != 1 mcp_aset(_o, _c.a, _s, _v);
		}
		else { mcp_aset(_o, _c.a, _set, _v); mcp_aset(_o, _c.o, _set, 1) }
	}
	mcp_sync_colour_ui(_o);
	mcp_after_edit(_o, true);
	return { set : _set, colours : mcp_colours_of(_o, _set) };
}

function mcp_colours_of(_o, _set)
{
	var _ct = mcp_colour_table();
	var _r = {};
	if _set == -1 _r.background = mcp_hex(_o.colrBack);
	for (var _i = 0; _i < 4; _i++)
		_r[$ _ct[_i].n] = mcp_hex((_set == -1) ? variable_instance_get(_o, _ct[_i].g) : mcp_aget(_o, _ct[_i].a, _set));
	return _r;
}


// -----------------------------------------------------------------------------
// RESET (the F4 / F5 equivalents)
// -----------------------------------------------------------------------------

/// hsd_reset_overrides: { set } - one set, or every set when set is left out.
/// Sliders, clumping and colours go back to the globals, as F4 / F5 do.
/// Per-set seeds and positions are kept (also as F4 / F5 do), unless
/// include_seed_and_position is true.
function mcp_reset_overrides(_o, _args)
{
	mcp_require_idle(_o);
	var _set = mcp_set_arg(_args);
	var _all = mcp_bool(_args, "include_seed_and_position", false);
	mcp_prepare_edit(_o);
	var _table = mcp_param_table();
	var _ct = mcp_colour_table();
	for (var _s = 0; _s < _o.maxSets; _s++)
	{
		if _set != -1 and _s != _set continue;
		for (var _i = 0; _i < array_length(_table); _i++)
		{
			var _p = _table[_i];
			if _p.a == "" continue;
			mcp_aset(_o, _p.o, _s, 0);
			mcp_aset(_o, _p.a, _s, variable_instance_get(_o, _p.g));
		}
		for (var _i = 0; _i < 4; _i++)
		{
			mcp_aset(_o, _ct[_i].o, _s, 0);
			mcp_aset(_o, _ct[_i].a, _s, variable_instance_get(_o, _ct[_i].g));
		}
		if _all
		{
			_o.randomOverride[_s] = 0;
			_o.xOffset[_s] = 0; _o.strandXOffset[_s] = 0;
			_o.yOffset[_s] = 0; _o.strandYOffset[_s] = 0;
		}
	}
	// Pairs: the globals already satisfy min <= max, so copying them is safe.
	mcp_sync_colour_ui(_o);
	mcp_after_edit(_o, true);
	return { reset : (_set == -1) ? "all sets" : "set " + string(_set), seeds_and_positions_reset : _all };
}


// -----------------------------------------------------------------------------
// OPTIONS AND MAPS
// -----------------------------------------------------------------------------

/// hsd_set_options: strand type, AO width, flow / ID modes, preview settings.
function mcp_set_options(_o, _args)
{
	mcp_require_idle(_o);
	var _names = variable_struct_get_names(_args);
	if array_length(_names) == 0 throw "Nothing to change.";
	// Check everything first.
	var _st = mcp_str(_args, "strand_type", "");      if _st != "" and _st != "single" and _st != "multi" throw "strand_type is single or multi.";
	var _aw = mcp_str(_args, "ao_width", "");         var _awi = -1;
	if _aw != "" { _awi = array_get_index(["thin", "default", "wide", "extreme"], _aw); if _awi < 0 throw "ao_width is thin, default, wide or extreme." }
	var _im = mcp_str(_args, "id_mode", "");          if _im != "" and _im != "per_strand" and _im != "per_set" throw "id_mode is per_strand or per_set.";
	var _pq = mcp_str(_args, "preview_quality", "");  if _pq != "" and array_get_index(["fast", "med", "slow", "dyna"], _pq) < 0 throw "preview_quality is fast, med, slow or dyna.";
	var _pu = mcp_str(_args, "preview_update", "");   if _pu != "" and _pu != "live" and _pu != "busy" throw "preview_update is live or busy.";
	var _solo = mcp_int(_args, "solo_set", -2, -1, 10);
	var _curl = mcp_has(_args, "curl") ? _args.curl : -1;
	if mcp_has(_args, "curl") and (!is_real(_curl) or _curl < 0 or _curl > 1) throw "curl is 0 to 1.";

	mcp_prepare_edit(_o);
	var _stale = false;
	if _st != "" { var _m = (_st == "multi") ? 1 : 0; if _o.moreHairs != _m { _o.moreHairs = _m; _stale = true } }
	if _awi >= 0 and _o.aoType != _awi { _o.aoType = _awi; _o.ao_GenState = _o.doAO }       // Draw_64 turns aoType into aoExtra
	if _im != "" { var _v = (_im == "per_set") ? 1 : 0; if _o.idMode != _v { _o.idMode = _v; _o.id_GenState = _o.doID } }
	var _flow = [["flow_flip_x", "dirFlipX"], ["flow_flip_y", "dirFlipY"], ["flow_blue", "dirBlue"], ["flow_hue", "dirHue"]];
	for (var _i = 0; _i < 4; _i++)
		if mcp_has(_args, _flow[_i][0])
		{
			var _v = mcp_bool(_args, _flow[_i][0], false) ? 1 : 0;
			if variable_instance_get(_o, _flow[_i][1]) != _v { variable_instance_set(_o, _flow[_i][1], _v); _o.flow_GenState = _o.doFlow }
		}
	if mcp_has(_args, "curl") and _o.curlRotAmt != _curl { _o.curlRotAmt = _curl; _stale = true }
	// Preview settings: the same values the FAST / MED / SLOW / DYNA buttons set (Step_1).
	if _pq == "fast" { _o.maxPreviewStrandsPerSet = 20;  _o.optimalStep = 80; _o.dynamicRes = 0 }
	if _pq == "med"  { _o.maxPreviewStrandsPerSet = 50;  _o.optimalStep = 40; _o.dynamicRes = 0 }
	if _pq == "slow" { _o.maxPreviewStrandsPerSet = 100; _o.optimalStep = 10; _o.dynamicRes = 0 }
	if _pq == "dyna" { _o.maxPreviewStrandsPerSet = 30;  _o.dynamicRes = 1 }
	if _pu != "" or mcp_has(_args, "preview_smooth")
	{
		if _pu != "" _o.pvMode = (_pu == "busy") ? 1 : 0;
		if mcp_has(_args, "preview_smooth") _o.pvSmooth = mcp_bool(_args, "preview_smooth", true) ? 1 : 0;
		// remembered between sessions, as the bottom-bar buttons do (Draw_0)
		ini_open("HSD_Settings.ini");
		ini_write_real("preview", "updateMode", _o.pvMode);
		ini_write_real("preview", "smooth", _o.pvSmooth);
		ini_close();
	}
	if _solo != -2 _o.setToSolo = _solo;
	mcp_after_edit(_o, _stale);
	return { options : mcp_options_of(_o), maps_stale : _stale or _o.pleaseGen };
}

function mcp_options_of(_o)
{
	var _pq = "custom";
	if _o.dynamicRes == 1 _pq = "dyna";
	else if _o.maxPreviewStrandsPerSet == 20 _pq = "fast";
	else if _o.maxPreviewStrandsPerSet == 50 _pq = "med";
	else if _o.maxPreviewStrandsPerSet == 100 _pq = "slow";
	var _aoNames = ["thin", "default", "wide", "extreme"];
	return {
		strand_type : (_o.moreHairs == 1) ? "multi" : "single",
		curl : _o.curlRotAmt,
		ao_width : _aoNames[clamp(_o.aoType, 0, 3)],
		id_mode : (_o.idMode == 1) ? "per_set" : "per_strand",
		flow_flip_x : _o.dirFlipX == 1, flow_flip_y : _o.dirFlipY == 1, flow_blue : _o.dirBlue == 1, flow_hue : _o.dirHue == 1,
		preview_quality : _pq,
		preview_update : (_o.pvMode == 1) ? "busy" : "live",
		preview_smooth : _o.pvSmooth == 1,
		solo_set : _o.setToSolo
	};
}

/// hsd_set_maps: { rgb_mask: true, color: true, ... } - which maps Generate makes.
/// Same as clicking the tick boxes: on = due (1) unless already generated (2),
/// off = 0.
function mcp_set_maps(_o, _args)
{
	mcp_require_idle(_o);
	var _mt = mcp_map_table();
	var _names = variable_struct_get_names(_args);
	if array_length(_names) == 0 throw "Name at least one map.";
	for (var _i = 0; _i < array_length(_names); _i++)
	{
		if is_undefined(mcp_find(_mt, _names[_i])) throw "Unknown map " + _names[_i] + ".";
		mcp_bool(_args, _names[_i], false);
	}
	for (var _i = 0; _i < array_length(_names); _i++)
	{
		var _m = mcp_find(_mt, _names[_i]);
		var _on = mcp_bool(_args, _m.n, false);
		variable_instance_set(_o, _m.d, _on ? 1 : 0);
		var _s = variable_instance_get(_o, _m.s);
		if !_on variable_instance_set(_o, _m.s, 0);
		else if _s == 0 variable_instance_set(_o, _m.s, 1);
	}
	return { maps : mcp_maps_of(_o) };
}

function mcp_maps_of(_o)
{
	var _mt = mcp_map_table();
	var _r = {};
	for (var _i = 0; _i < array_length(_mt); _i++)
	{
		var _m = _mt[_i];
		// pleaseGen means a setting changed since the last render: Draw_0 is
		// about to drop every generated map back to "due".
		var _s = variable_instance_get(_o, _m.s);
		if _o.pleaseGen and _s == 2 _s = variable_instance_get(_o, _m.d);
		_r[$ _m.n] = { enabled : variable_instance_get(_o, _m.d) == 1, state : mcp_state_name(_s) };
	}
	return _r;
}


// -----------------------------------------------------------------------------
// GENERATE
// -----------------------------------------------------------------------------

/// hsd_generate: { force } - render every enabled map that is due, at 4096.
/// Exactly what the G key does (Draw_0 GENERATE SHORTCUT); the render then
/// runs in doMainStep, one set per frame.
function mcp_generate(_o, _args)
{
	mcp_require_idle(_o);
	var _force = mcp_bool(_args, "force", false);
	mcp_prepare_edit(_o);
	var _mt = mcp_map_table();
	// pleaseGen would make Draw_0 drop generated maps back to due this frame,
	// but the G flags below clear it first, so do that drop here.
	for (var _i = 0; _i < array_length(_mt); _i++)
	{
		var _m = _mt[_i];
		var _d = variable_instance_get(_o, _m.d);
		if _o.pleaseGen or _force variable_instance_set(_o, _m.s, _d);
	}
	var _due = [];
	for (var _i = 0; _i < array_length(_mt); _i++) if variable_instance_get(_o, _mt[_i].s) == 1 array_push(_due, _mt[_i].n);
	if array_length(_due) == 0 throw "Nothing to generate: every enabled map is already up to date (force=true redraws them) or no map is enabled (hsd_set_maps).";
	with (_o)
	{
		firstTime   = false;
		generating  = true;
		changesMade = false;
		doOnce      = true;
		canSave     = false;
		pleaseGen   = false;
		instance_create_depth(0, 0, -1000, obj_wait);
		retrigger   = true;
	}
	return { started : true, maps : _due, sets : _o.sets + 1, note : "The render draws one set per frame; hsd_generate_status reports progress." };
}

function mcp_generate_status(_o)
{
	var _r = mcp_rendering(_o);
	return { rendering : _r, set_being_drawn : _r ? _o.renderF : -1, sets : _o.sets + 1, can_save : _o.canSave, maps : mcp_maps_of(_o) };
}


// -----------------------------------------------------------------------------
// EXPORT (one map per frame)
// -----------------------------------------------------------------------------

/// hsd_export_maps: { folder, name, maps, overwrite } - write generated maps as
/// 4096x4096 PNGs named <name><suffix>.png, the names the S key uses.
function mcp_export_maps(_o, _args)
{
	mcp_require_idle(_o);
	if _o.demoMode == 1 throw "Saving and exporting are disabled in the demo version.";
	var _folder = mcp_str(_args, "folder", "");
	var _name = mcp_str(_args, "name", "");
	if _folder == "" or _name == "" throw "folder and name are required.";
	var _overwrite = mcp_bool(_args, "overwrite", false);
	var _mt = mcp_map_table();
	var _want = mcp_has(_args, "maps") ? _args.maps : [];
	if !is_array(_want) throw "maps must be a list of map names.";
	for (var _i = 0; _i < array_length(_want); _i++) if is_undefined(mcp_find(_mt, _want[_i])) throw "Unknown map " + string(_want[_i]) + ".";
	if array_length(_want) == 0 for (var _i = 0; _i < array_length(_mt); _i++) array_push(_want, _mt[_i].n);

	_folder = string_trim_end(_folder, ["/", "\\"]);
	if !directory_exists(_folder) directory_create(_folder);
	if !directory_exists(_folder) throw "Could not create the folder " + _folder + ".";

	var _sep = (string_pos("\\", _folder) > 0) ? "\\" : "/";     // match the separator the caller used
	var _queue = [];
	var _skipped = [];
	var _stale = _o.pleaseGen;
	for (var _i = 0; _i < array_length(_want); _i++)
	{
		var _m = mcp_find(_mt, _want[_i]);
		var _s = variable_instance_get(_o, _m.s);
		if _s != 2 or _stale { array_push(_skipped, { map : _m.n, reason : (_s == 0) ? "not enabled" : "not generated since the last change (hsd_generate)" }); continue }
		var _file = _folder + _sep + _name + _m.x + ".png";
		if file_exists(_file) and !_overwrite { array_push(_skipped, { map : _m.n, reason : "file exists (overwrite=true replaces it)", file : _file }); continue }
		array_push(_queue, { map : _m.n, file : _file });
	}
	if array_length(_queue) == 0 throw "Nothing to export: " + json_stringify(_skipped);
	mcp_export_job = { active : true, queue : _queue, index : 0, written : [], skipped : _skipped, error : "" };
	return { started : true, files : array_length(_queue), skipped : _skipped };
}

/// Called from obj_mcp Step: write the next map of the export job.
function mcp_export_step(_o)
{
	var _j = mcp_export_job;
	if !is_struct(_j) or !_j.active return;
	if _j.index >= array_length(_j.queue) { _j.active = false; return }
	var _e = _j.queue[_j.index];
	_j.index += 1;
	var _m = mcp_find(mcp_map_table(), _e.map);
	var _canvas = variable_instance_get(_o, _m.c);
	if !surface_exists(_canvas) { array_push(_j.skipped, { map : _e.map, reason : "the map's surface was lost; generate again" }); return }
	if _m.n == "normal" and _o.moreHairs == 1
	{
		// Multi strand: nm_canvas holds a height map; S converts it with
		// shd_normal first (KeyPress_83). Same steps here.
		if !surface_exists(_o.tNormsurf) _o.tNormsurf = surface_create(4096, 4096);
		surface_set_target(_o.tNormsurf);
		shader_set(shd_normal);
		draw_surface(_canvas, 0, 0);
		shader_reset();
		surface_reset_target();
		var _spr = sprite_create_from_surface(_o.tNormsurf, 0, 0, 4096, 4096, 0, 0, 0, 0);
		sprite_save(_spr, 0, _e.file);
		sprite_delete(_spr);
	}
	else surface_save(_canvas, _e.file);
	if file_exists(_e.file) array_push(_j.written, _e.file);
	else array_push(_j.skipped, { map : _e.map, reason : "could not write the file", file : _e.file });
	if _j.index >= array_length(_j.queue) _j.active = false;
}

function mcp_export_status()
{
	var _j = mcp_export_job;
	if !is_struct(_j) return { active : false, written : [], skipped : [] };
	return { active : _j.active, done : _j.index, total : array_length(_j.queue), written : _j.written, skipped : _j.skipped };
}


// -----------------------------------------------------------------------------
// PROJECT FILES (the real S and L events, without the file dialog)
// -----------------------------------------------------------------------------

function mcp_save_project(_o, _args)
{
	mcp_require_idle(_o);
	if _o.demoMode == 1 throw "Saving is disabled in the demo version.";
	if !_o.canSave throw "Saving is not possible right now (a render is running).";
	var _path = mcp_str(_args, "path", "");
	if _path == "" throw "path is required.";
	if string_lower(filename_ext(_path)) != ".txt" _path += ".txt";
	if file_exists(_path) and !mcp_bool(_args, "overwrite", false) throw "The file exists (overwrite=true replaces it).";
	var _dir = filename_dir(_path);
	if _dir != "" and !directory_exists(_dir) directory_create(_dir);
	mcp_prepare_edit(_o);
	with (_o)
	{
		// What object g does when S is pressed: mark the file as current and
		// have Alarm 1 append the colour / clumping / extras blocks afterwards.
		mainS = "Hair Strand Designer - Project File - Version1.97.0 - 20thNov2026 (C) Robert Ramsay";
		v185ManualSavePending = 1;
		v185ManualSavePath = "";
		alarm[1] = 2;
		projectOnly = true;                     // no map dialogs: maps go through hsd_export_maps
		prjName = filename_change_ext(filename_name(_path), "");
		mcpFileOverride = _path;                // KeyPress_83 uses this instead of its dialog
		event_perform(ev_keypress, ord("S"));
		mcpFileOverride = "";
	}
	if !file_exists(_path) throw "The project file was not written.";
	return { path : _path, note : "The colour, clumping and extra-settings blocks are appended over the next two frames." };
}

function mcp_load_project(_o, _args)
{
	mcp_require_idle(_o);
	var _path = mcp_str(_args, "path", "");
	if _path == "" or !file_exists(_path) throw "No project file at that path.";
	if !mcp_bool(_args, "replace_current", false) throw "Loading replaces the hair now in Hair Strand Designer. Ask the user, then pass replace_current=true.";
	if !_o.canLoad throw "Loading is not possible right now.";
	mcp_prepare_edit(_o);
	with (_o)
	{
		mcpFileOverride = _path;                // KeyPress_76 uses this instead of its dialog
		event_perform(ev_keypress, ord("L"));
		mcpFileOverride = "";
	}
	return { path : _path, note : "Per-set colours, clumping and extra settings are restored over the next frames." };
}


// -----------------------------------------------------------------------------
// START SCREEN
// -----------------------------------------------------------------------------

/// hsd_start_session: { load_autosave } - press LOAD AUTOSAVE or GET STARTED.
function mcp_start_session(_o, _args)
{
	if !_o.firstTime throw "The start screen is not showing; a session is already running.";
	var _load = mcp_bool(_args, "load_autosave", false);
	if _load and _o.splashAutosaveFound != 1 throw "There is no autosave to load.";
	with (_o)
	{
		dynamicRes            = 1;
		firstTime             = false;
		readyToCheckAutoloads = 1;
		autoloading           = _load ? 1 : 0;
	}
	return { started : true, loaded_autosave : _load };
}


// -----------------------------------------------------------------------------
// READING
// -----------------------------------------------------------------------------

function mcp_ping(_o)
{
	return {
		app : "Hair Strand Designer", version : _o.versionHSD, mcp : MCP_VERSION,
		busy : mcp_busy_reason(_o),
		start_screen : _o.firstTime == true,
		autosave_found : variable_instance_exists(_o, "splashAutosaveFound") and _o.splashAutosaveFound == 1,
		rendering : mcp_rendering(_o),
		exporting : is_struct(mcp_export_job) and mcp_export_job.active,
		save_pending : mcp_save_pending(_o) or _o.saving,
		load_pending : mcp_load_pending(_o),
		preview_ready : mcp_preview_ready(_o),
		maps_stale : _o.pleaseGen == true,
		demo : _o.demoMode == 1
	};
}

function mcp_describe()
{
	var _t = mcp_param_table();
	var _params = [];
	for (var _i = 0; _i < array_length(_t); _i++)
		array_push(_params, { name : _t[_i].n, min : _t[_i].lo, max : _t[_i].hi, per_set : _t[_i].a != "", about : _t[_i].d });
	array_push(_params, { name : "seed", min : 0, max : 2147483647, per_set : true, about : "Random seed. Global (no set) = what F1 does: every set takes this seed. With a set: that set keeps its own seed." });
	array_push(_params, { name : "x_offset", min : -4096, max : 4096, per_set : true, per_set_only : true, about : "Move a set sideways, in 4096-map pixels (dragging a set in the preview)." });
	array_push(_params, { name : "y_offset", min : -4096, max : 4096, per_set : true, per_set_only : true, about : "Move a set up / down, in map pixels." });
	var _maps = [];
	var _mt = mcp_map_table();
	for (var _i = 0; _i < array_length(_mt); _i++) array_push(_maps, _mt[_i].n + " (file suffix " + _mt[_i].x + ")");
	return {
		sets : "11 sets, numbered 0-10. A value given without a set is global and is copied into every set that has not overridden it; with a set it overrides that set only.",
		params : _params,
		colours : "background (global only), variation1, variation2, root, tip - hex RRGGBB. Variation 1 / 2 are the body tones, root and tip tint the ends.",
		maps : _maps,
		options : {
			strand_type : "single | multi (multi twists each fibre; curl 0-1 sets how much)",
			ao_width : "thin | default | wide | extreme",
			id_mode : "per_strand | per_set",
			flow : "flow_flip_x, flow_flip_y, flow_blue, flow_hue (true / false)",
			preview_quality : "fast (20 strands per set) | med (50) | slow (100) | dyna (30)",
			preview_update : "live | busy", preview_smooth : "true | false",
			solo_set : "-1 shows every set, 0-10 shows one set only in the preview"
		},
		workflow : "hsd_start_session if the start screen is up -> hsd_set_params / hsd_set_colours -> hsd_screenshot view=preview -> hsd_set_maps -> hsd_generate -> hsd_screenshot view=<map> -> hsd_export_maps."
	};
}

/// hsd_get_state: every global value, what each set overrides, colours,
/// options and maps.
function mcp_get_state(_o)
{
	var _t = mcp_param_table();
	var _ct = mcp_colour_table();
	var _globals = {};
	for (var _i = 0; _i < array_length(_t); _i++) _globals[$ _t[_i].n] = variable_instance_get(_o, _t[_i].g);
	_globals.seed = _o.seedVal;
	var _sets = [];
	for (var _s = 0; _s <= _o.sets; _s++)
	{
		var _ov = {};
		for (var _i = 0; _i < array_length(_t); _i++)
			if _t[_i].a != "" and mcp_aget(_o, _t[_i].o, _s) == 1 _ov[$ _t[_i].n] = mcp_aget(_o, _t[_i].a, _s);
		var _col = {};
		for (var _i = 0; _i < 4; _i++)
			if mcp_aget(_o, _ct[_i].o, _s) == 1 _col[$ _ct[_i].n] = mcp_hex(mcp_aget(_o, _ct[_i].a, _s));
		array_push(_sets, {
			set : _s,
			overrides : _ov,
			colour_overrides : _col,
			seed : _o.randomSeedVal[_s], seed_overridden : _o.randomOverride[_s] == 1,
			x_offset : _o.xOffset[_s], y_offset : _o.yOffset[_s]
		});
	}
	return {
		ping : mcp_ping(_o),
		globals : _globals,
		colours : mcp_colours_of(_o, -1),
		sets : _sets,
		options : mcp_options_of(_o),
		maps : mcp_maps_of(_o),
		project_file : _o.lastFileName
	};
}


// -----------------------------------------------------------------------------
// SCREENSHOTS
// -----------------------------------------------------------------------------

/// hsd_screenshot: { view: "preview" | "window" | <map name>, size }
/// Writes <save area>/mcp/shot.png and returns its path; the bridge sends the
/// picture back as an image.
function mcp_screenshot(_o, _args, _dir)
{
	var _view = mcp_str(_args, "view", "preview");
	var _size = mcp_int(_args, "size", 1024, 256, 2048);
	if !directory_exists(_dir) directory_create(_dir);
	var _path = _dir + "/shot.png";
	if file_exists(_path) file_delete(_path);
	var _cw = gpu_get_colorwriteenable();
	var _bm = gpu_get_blendmode();
	var _note = "";
	var _w = _size, _h = _size;

	if _view == "window"
	{
		// The whole window as the user sees it, at most 1920 wide.
		var _tmp = _dir + "/window.png";
		screen_save(_tmp);
		var _spr = sprite_add(_tmp, 1, false, false, 0, 0);
		if !sprite_exists(_spr) throw "Could not capture the window.";
		var _k = min(1, 1920 / sprite_get_width(_spr));
		_w = round(sprite_get_width(_spr) * _k); _h = round(sprite_get_height(_spr) * _k);
		var _surf = surface_create(_w, _h);
		surface_set_target(_surf);
		gpu_set_colorwriteenable(true, true, true, true);
		draw_clear_alpha(c_black, 1);
		gpu_set_blendmode(bm_normal);
		draw_sprite_ext(_spr, 0, 0, 0, _k, _k, 0, c_white, 1);
		surface_reset_target();
		surface_save(_surf, _path);
		surface_free(_surf);
		sprite_delete(_spr);
		file_delete(_tmp);
		_note = "The whole window as the user sees it.";
	}
	else
	{
		var _m = mcp_find(mcp_map_table(), _view);
		if _view != "preview" and is_undefined(_m) throw "view is preview, window or a map name (rgb_mask, normal, mask, color, id, depth, flow, ao, frizz).";
		var _surf = surface_create(_size, _size);
		surface_set_target(_surf);
		gpu_set_colorwriteenable(true, true, true, true);
		gpu_set_blendmode(bm_normal);
		if _view == "preview"
		{
			// The preview canvas: background plus each set's preview surface
			// (as mainCalc composites them, without the smoothing shader and
			// without selection highlights). Alpha writes stay off so the PNG
			// is opaque.
			draw_clear_alpha(_o.colrBack, 1);
			gpu_set_colorwriteenable(true, true, true, false);
			var _k = _size / 1024;
			for (var _b = 0; _b <= _o.sets; _b++)
				if surface_exists(_o.previewSurf[_b]) draw_surface_ext(_o.previewSurf[_b], 0, 0, _k, _k, 0, c_white, 1);
			_note = mcp_preview_ready(_o) ? "Preview, fully drawn." : "Preview, still growing in (screenshot again, or pass wait_for_preview).";
		}
		else
		{
			var _canvas = variable_instance_get(_o, _m.c);
			if !surface_exists(_canvas) { surface_reset_target(); surface_free(_surf); throw "The " + _m.n + " map has no surface (generate it first)." }
			draw_clear_alpha(c_black, 1);
			gpu_set_colorwriteenable(true, true, true, false);
			if _m.n == "normal" and _o.moreHairs == 1 shader_set(shd_normal);   // as the S export and the viewer show it
			draw_surface_ext(_canvas, 0, 0, _size / 4096, _size / 4096, 0, c_white, 1);
			shader_reset();
			var _s = variable_instance_get(_o, _m.s);
			_note = _m.n + " map scaled from 4096, " + mcp_state_name(_s) + ((_s == 2 and !_o.pleaseGen) ? "." : " - this is the last render, not the current settings.");
		}
		surface_reset_target();
		surface_save(_surf, _path);
		surface_free(_surf);
	}
	gpu_set_colorwriteenable(_cw[0], _cw[1], _cw[2], _cw[3]);
	gpu_set_blendmode(_bm);
	if !file_exists(_path) throw "The screenshot could not be written.";
	return { path : _path, view : _view, width : _w, height : _h, note : _note };
}


// -----------------------------------------------------------------------------
// DISPATCH
// -----------------------------------------------------------------------------

/// One command from the bridge. Runs in obj_mcp; returns a struct (the reply)
/// or throws a message (sent back as the error).
function mcp_dispatch(_method, _args)
{
	if !instance_exists(obj_surfaceDweller) throw "Hair Strand Designer is not ready.";
	var _o = obj_surfaceDweller.id;
	switch (_method)
	{
		case "ping":            return mcp_ping(_o);
		case "describe":        return mcp_describe();
		case "get_state":       return mcp_get_state(_o);
		case "start_session":   return mcp_start_session(_o, _args);
		case "set_params":      return mcp_set_params(_o, _args);
		case "set_colours":     return mcp_set_colours(_o, _args);
		case "reset_overrides": return mcp_reset_overrides(_o, _args);
		case "set_options":     return mcp_set_options(_o, _args);
		case "set_maps":        return mcp_set_maps(_o, _args);
		case "generate":        return mcp_generate(_o, _args);
		case "generate_status": return mcp_generate_status(_o);
		case "export_maps":     return mcp_export_maps(_o, _args);
		case "export_status":   return mcp_export_status();
		case "save_project":    return mcp_save_project(_o, _args);
		case "load_project":    return mcp_load_project(_o, _args);
		case "screenshot":      return mcp_screenshot(_o, _args, mcp_dir);
	}
	throw "Unknown command " + _method + ".";
}
