// =============================================================================
// V1.96 MANUAL-SAVE EXTRAS
//
// The manual project saver (S key, KeyPress_83) predates these settings and
// never wrote them, so saving a project and loading it back silently lost:
//   - Noise amount / frequency                     (V1.90)
//   - per-set Thick Min / Max overrides            (V1.71)
//   - per-set Tip / Root / Vary / Fade / Noise     (V1.91)
//   - per-set seeds and their override flags       (V1.70)
// The autosave always had them, which is why only manual projects lost them.
//
// Alarm 1 appends this block to manual saves and scans for it on every load.
// Like the clump block it is "name:value;" lines found by marker, not by line
// position. A file without it (an autosave, or an older manual project) leaves
// whatever the main loader already set, so nothing changes for those files.
//
// WHERE IT SITS IN A MANUAL PROJECT FILE (all written by Alarm 1, in this order,
// appended after KeyPress_83 has closed the file):
//   ... legacy positional lines, ending with the V1.55 block (KeyPress_83)
//   "V1.85 - Per Set Colour Overrides"  + 4 global colours + 8 lines x 11 sets
//   "V1.96 - Clumping"   ... "clumpEnd:1;"     (clumpWriteBlock, clumpTools)
//   "V1.96 - Set Extras" ... "extrasEnd:1;"    (extrasWriteBlock, below)
//
// LINES IN THIS BLOCK
//   V1.96 - Set Extras          the marker (EXTRAS_BLOCK_MARKER)
//   noiseAmt:<n>;  noiseFreq:<n>;              the two global noise values
//   O<Name>_<set>:<0|1>;        override flag  } for each set 0-10 and each of
//   V<Name>_<set>:<n>;          the value      } the 9 names in extrasName()
//   SeedO_<set>:<0|1>;          set uses its own seed (randomOverride)
//   SeedV_<set>:<n>;            that seed (randomSeedVal), 6 decimals
//   extrasEnd:1;                stops the reader
// Lines are matched by NAME, so their order inside the block does not matter.
// A line with no ":" ends the read early, the same as extrasEnd.
//
// ADDING ANOTHER PER-SET VALUE HERE
//   1. raise EXTRAS_COUNT
//   2. add a case with the same index to ALL SIX switch functions below
//      (extrasName, extrasGetAdj, extrasSetAdj, extrasGetOver, extrasSetOver,
//      extrasGlobal). In each one the LAST name is the "default:" branch, so
//      turn the current default into a numbered case and make the new one the
//      default, or the new index silently reads/writes NoiseFreq.
//   3. the name must not contain "_" (the reader splits the key at the first
//      "_": name before it, set number after it).
//   Old files simply lack the new lines and keep what the main loader set.
//   The autosave does not use this block: add the value to doAutoSave /
//   doAutoLoad as well, and to obj_copy so COPY / PASTE carries it.
//
// All functions here run in obj_surfaceDweller's scope (called from Alarm 1).
// =============================================================================

#macro EXTRAS_BLOCK_MARKER "V1.96 - Set Extras"

// Per-set values carried by the block, by index.
#macro EXTRAS_COUNT 9
// 0 ThickMin  1 ThickMax  2 TipThick  3 RootThick  4 ThickVary
// 5 FadeIn    6 FadeOut   7 NoiseAmt  8 NoiseFreq

// The six functions below are one lookup table in six views: index _k picks
// the same setting in each. They exist so the writer and reader can loop over
// "setting k of set s" instead of naming 18 arrays.

/// Name used in the file for value _k ("O"/"V" + this + "_" + set number).
function extrasName(_k)
{
	switch (_k)
	{
		case 0: return "ThickMin";  case 1: return "ThickMax";  case 2: return "TipThick"
		case 3: return "RootThick"; case 4: return "ThickVary"; case 5: return "FadeIn"
		case 6: return "FadeOut";   case 7: return "NoiseAmt";  default: return "NoiseFreq"
	}
}

/// Per-set VALUE _k of set _s (the set...Adj arrays).
function extrasGetAdj(_k, _s)
{
	switch (_k)
	{
		case 0: return setThickMinAdj[_s];  case 1: return setThickMaxAdj[_s];  case 2: return setTipThickAdj[_s]
		case 3: return setRootThickAdj[_s]; case 4: return setThickVaryAdj[_s]; case 5: return setFadeInAdj[_s]
		case 6: return setFadeOutAdj[_s];   case 7: return setNoiseAmtAdj[_s];  default: return setNoiseFreqAdj[_s]
	}
}

function extrasSetAdj(_k, _s, _v)
{
	switch (_k)
	{
		case 0: setThickMinAdj[_s] = _v; break;  case 1: setThickMaxAdj[_s] = _v; break;  case 2: setTipThickAdj[_s] = _v; break
		case 3: setRootThickAdj[_s] = _v; break; case 4: setThickVaryAdj[_s] = _v; break; case 5: setFadeInAdj[_s] = _v; break
		case 6: setFadeOutAdj[_s] = _v; break;   case 7: setNoiseAmtAdj[_s] = _v; break;  default: setNoiseFreqAdj[_s] = _v
	}
}

/// Per-set OVERRIDE FLAG _k of set _s (the set...Overrode arrays).
/// 1 = the set has its own value, 0 = it follows the global slider.
function extrasGetOver(_k, _s)
{
	switch (_k)
	{
		case 0: return setThickMinOverrode[_s];  case 1: return setThickMaxOverrode[_s];  case 2: return setTipThickOverrode[_s]
		case 3: return setRootThickOverrode[_s]; case 4: return setThickVaryOverrode[_s]; case 5: return setFadeInOverrode[_s]
		case 6: return setFadeOutOverrode[_s];   case 7: return setNoiseAmtOverrode[_s];  default: return setNoiseFreqOverrode[_s]
	}
}

function extrasSetOver(_k, _s, _v)
{
	switch (_k)
	{
		case 0: setThickMinOverrode[_s] = _v; break;  case 1: setThickMaxOverrode[_s] = _v; break;  case 2: setTipThickOverrode[_s] = _v; break
		case 3: setRootThickOverrode[_s] = _v; break; case 4: setThickVaryOverrode[_s] = _v; break; case 5: setFadeInOverrode[_s] = _v; break
		case 6: setFadeOutOverrode[_s] = _v; break;   case 7: setNoiseAmtOverrode[_s] = _v; break;  default: setNoiseFreqOverrode[_s] = _v
	}
}

/// The global each per-set value falls back to when it is not overridden.
function extrasGlobal(_k)
{
	switch (_k)
	{
		case 0: return minScale;  case 1: return maxScale;  case 2: return tipThick
		case 3: return rootThick; case 4: return thickVary; case 5: return fadeIn
		case 6: return fadeOut;   case 7: return noiseAmt;  default: return noiseFreq
	}
}


/// Append the block to the already-open text file _f.
/// Called only by Alarm 1 during a manual save, after the colour and clump
/// blocks. Not called by doAutoSave.
function extrasWriteBlock(_f)
{
	file_text_write_string(_f, EXTRAS_BLOCK_MARKER); file_text_writeln(_f)
	file_text_write_string(_f, "noiseAmt:"  + string(noiseAmt)  + ";"); file_text_writeln(_f)
	file_text_write_string(_f, "noiseFreq:" + string(noiseFreq) + ";"); file_text_writeln(_f)
	for (var _s = 0; _s < 11; _s++)
	{
		for (var _k = 0; _k < EXTRAS_COUNT; _k++)
		{
			var _nm = extrasName(_k) + "_" + string(_s)
			file_text_write_string(_f, "O" + _nm + ":" + string(extrasGetOver(_k, _s)) + ";"); file_text_writeln(_f)
			file_text_write_string(_f, "V" + _nm + ":" + string(extrasGetAdj(_k, _s))  + ";"); file_text_writeln(_f)
		}
	}
	// Per-set seeds (V1.70). Written with 6 decimals: the dice gives sets
	// fractional seeds and string() alone would round them to 2 places.
	for (var _s = 0; _s < 11; _s++)
	{
		file_text_write_string(_f, "SeedO_" + string(_s) + ":" + string(randomOverride[_s]) + ";"); file_text_writeln(_f)
		file_text_write_string(_f, "SeedV_" + string(_s) + ":" + string_format(randomSeedVal[_s], 1, 6) + ";"); file_text_writeln(_f)
	}
	file_text_write_string(_f, "extrasEnd:1;"); file_text_writeln(_f)
}


/// Restore the block from _path if present. Returns true if it was found.
/// When it is missing nothing is touched.
/// Called by Alarm 1 one frame after every load (manual and autoload), once
/// the main loader has closed the file. It opens the file itself, skips lines
/// until the marker, then reads "name:value;" lines until extrasEnd, a line
/// with no colon, or end of file.
function extrasReadFile(_path)
{
	if _path == "" or !file_exists(_path) return false
	var _f = file_text_open_read(_path)
	if _f == -1 return false

	var _found = false, _line = "", _colon = 0, _key = "", _num = "", _val = 0
	var _us = 0, _nm = "", _ps = 0, _pk = -1, _q = 0

	while !file_text_eof(_f)
	{
		_line = file_text_read_string(_f); file_text_readln(_f)
		if _line == EXTRAS_BLOCK_MARKER { _found = true; break }
	}

	while _found and !file_text_eof(_f)
	{
		_line = file_text_read_string(_f); file_text_readln(_f)
		_colon = string_pos(":", _line)
		if _colon <= 0 break
		_key = string_copy(_line, 1, _colon - 1)
		_num = string_replace(string_copy(_line, _colon + 1, string_length(_line) - _colon), ";", "")
		// real() throws on text with no digits, so an empty value becomes 0.
		_val = (string_digits(_num) == "") ? 0 : real(_num)

		if _key == "extrasEnd" break
		else if _key == "noiseAmt"  noiseAmt  = clamp(_val, 0, 40)
		else if _key == "noiseFreq" noiseFreq = clamp(_val, 0, 40)
		else if string_copy(_key, 1, 6) == "SeedO_" or string_copy(_key, 1, 6) == "SeedV_"
		{
			// Set number starts at character 7; character 5 is the O or V.
			// Flags are forced to exactly 0 or 1.
			_ps = real(string_copy(_key, 7, string_length(_key) - 6))
			if _ps >= 0 and _ps < maxSets
			{
				if string_char_at(_key, 5) == "O" randomOverride[_ps] = (_val != 0) ? 1 : 0
				else randomSeedVal[_ps] = _val
			}
		}
		else
		{
			// "O<Name>_<set>" or "V<Name>_<set>"
			_us = string_pos("_", _key)
			if _us > 2
			{
				_nm = string_copy(_key, 2, _us - 2)
				_ps = real(string_copy(_key, _us + 1, string_length(_key) - _us))
				_pk = -1 // index of the name in extrasName(); stays -1 if not known
				for (_q = 0; _q < EXTRAS_COUNT; _q++) if extrasName(_q) == _nm { _pk = _q; break }
				if _pk >= 0 and _ps >= 0 and _ps < maxSets
				{
					if string_char_at(_key, 1) == "O" extrasSetOver(_pk, _ps, (_val != 0) ? 1 : 0)
					else if string_char_at(_key, 1) == "V" extrasSetAdj(_pk, _ps, _val)
				}
			}
		}
	}
	file_text_close(_f)

	if _found
	{
		// Any set not overriding a value follows the (possibly just-loaded)
		// global, exactly as the KeyPress_76 / doAutoLoad re-seed does.
		for (var _s = 0; _s < maxSets; _s++)
			for (var _k = 0; _k < EXTRAS_COUNT; _k++)
				if extrasGetOver(_k, _s) == 0 extrasSetAdj(_k, _s, extrasGlobal(_k))

		textBox_noiseAmt_value  = string(noiseAmt)
		textBox_noiseFreq_value = string(noiseFreq)
	}
	return _found
}
