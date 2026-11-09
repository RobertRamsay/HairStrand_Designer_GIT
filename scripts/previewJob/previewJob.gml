// =============================================================================
// V1.96 PROGRESSIVE PREVIEW
//
// The preview used to rebuild every set in one frame, and only on mouse release:
// while a slider was dragged the canvas just said BUSY, and the release frame
// stalled for the whole rebuild.
//
// Now each set carries a SIGNATURE - every value its preview depends on. Each
// frame the signatures are compared with the last ones drawn:
//
//   changed this frame  -> the set is redrawn straight away at COARSE quality,
//                          so dragging any slider gives live feedback
//   unchanged for a few
//   frames (settled)    -> the set is redrawn at full quality, GROWING IN a
//                          couple of strands at a time alongside every other
//                          settled set, under a per-frame time budget, so
//                          the UI never stalls and the preview fills evenly
//
// That is LIVE mode. BUSY mode (pvMode 1, the toggle on the bottom bar) keeps
// the change detection but behaves like the old preview: it waits while the
// mouse is held, then redraws what changed in a single frame.
//
// Because a set is only ever redrawn when its own signature changes, an edit
// to one set leaves the other ten alone, and nothing depends on where the
// mouse is or which button was released.
//
// Drawing can stop after any strand and resume next frame with an identical
// result: doCalc and the clump code draw nothing from the random stream.
// =============================================================================


/// One number that changes whenever a mixer path is edited.
function previewPathHash()
{
	var _h = 0
	for (var _p = 0; _p < 3; _p++)
	{
		var _path = editingPath[_p]
		var _n = min(path_get_number(_path), 24)
		for (var _i = 0; _i < _n; _i++)
			_h += (path_get_point_x(_path, _i) * (_i + 1) * (1.37 + _p)) + (path_get_point_y(_path, _i) * (_i + 1) * (2.11 + _p))
	}
	return _h
}


/// Everything set _b's preview depends on. Element 0 is "is this set drawn".
/// A few samples of the pre-random tables are included, so anything that
/// rebuilds those tables (seeds, spacing, variation ...) is caught even if its
/// source value is not listed here.
function previewSetSig(_b, _pathHash)
{
	var _vis = ((setToSolo == _b or setToSolo == -1) and set_active[_b] == 0) ? 1 : 0
	return [
		_vis, _pathHash,
		maxPreviewStrandsPerSet, strands, length, padding, ampFactor, setDistance, tipPosition,
		previewAlphaK, previewWidthK,
		xOffset[_b], yOffset[_b],
		setCountOverrode[_b], strandCountOverride[_b], strandLengthOverride[_b],
		strandSetVariAdj[_b], preRandLifeVariant[_b],
		strandSetSpaceAdj[_b], strandSetTaperAdj[_b], strandSetWavynessAdj[_b],
		setThickMinAdj[_b], setThickMaxAdj[_b], setRootThickAdj[_b], setTipThickAdj[_b],
		setFadeInAdj[_b], setFadeOutAdj[_b], setNoiseAmtAdj[_b], setNoiseFreqAdj[_b],
		strandSetMixerAdj1[_b], strandSetMixerAdj2[_b], strandSetMixerAdj3[_b],
		strandSetMixerOffsetAdj1[_b], strandSetMixerOffsetAdj2[_b], strandSetMixerOffsetAdj3[_b],
		setClumpAmtAdj[_b], setClumpCountAdj[_b], setClumpStartAdj[_b], setClumpScatterAdj[_b],
		randomSeedVal[_b],
		setColVarA[_b], setColVarB[_b], setRootCol[_b], setTipCol[_b],
		preRandSpacing[_b, 0], preRandSpacing[_b, 57],
		preRandLife[_b, 0], preRandLife[_b, 57],
		preRandThickBase[_b, 0], preRandThickBase[_b, 57],
		preRandFreq[_b, 0], preRandFreq[_b, 57],
		preRandYY[_b, 0], preRandYY[_b, 57],
		preRandAmp[_b, 0], preRandRoot[_b, 0], preRandDepth[_b, 0], preRandDepthAdd[_b, 0]
	]
}


/// How many strands the preview draws for set _b.
function previewSetCount(_b)
{
	if setCountOverrode[_b] == 1 { strandSet = strandCountOverride[_b] } else { strandSet = strands }
	return clamp(strandSet, 0, maxPreviewStrandsPerSet)
}


function previewClearSet(_b)
{
	surface_set_target(previewSurf[_b])
	gpu_set_colorwriteenable(1, 1, 1, 0)
	draw_clear_alpha(0, 0)
	gpu_set_colorwriteenable(1, 1, 1, 1)
	surface_reset_target()
	setBBl[_b] = 0; setBBr[_b] = 0; setBBt[_b] = 0; setBBb[_b] = 0
}


/// Build set _b's working state (mixer cache, clump membership) for drawing
/// _count strands at _step, and keep it in pvW[_b]. Each set owns its state,
/// so sets can be drawn a few strands at a time in any order.
function previewSetBegin(_b, _step, _count)
{
	mixerCacheBuild(_b, _step, strandSetVariAdj[_b])
	clumpPrepareSet(_b, _count, floor(3900 / _step) + 3)
	pvDrawnStep[_b] = _step
	pvW[_b] = {
		step : _step, mix : mixCacheX,
		on : clumpOnS, amt : clumpAmtS, start : clumpStartS, ramp : clumpRampS,
		bin : clumpBin, isLead : clumpIsLead, stick : clumpStick,
		leadX : clumpLeadX, leadLen : clumpLeadLen, leadLife : clumpLeadLife, leadStep : clumpLeadStep
	}
}


/// Draw strands _vFrom.. of set _b into previewSurf[_b], stopping after the
/// strand during which _deadline (get_timer microseconds, 0 = none) passes.
/// Returns the next strand index; == _count when the set is finished.
/// previewSetBegin(_b, _step, ...) must have been called for this set. _count
/// may be lower than the count it was prepared for, to draw just a few strands.
function previewDrawStrands(_b, _step, _count, _vFrom, _deadline)
{
	// Bind this set's working state. The project has copy-on-write arrays
	// enabled, so anything written through these shared references below uses
	// the [@ accessor - a plain write would silently go to a private copy.
	var _w = pvW[_b]
	mixCacheX = _w.mix
	clumpOnS = _w.on; clumpAmtS = _w.amt; clumpStartS = _w.start; clumpRampS = _w.ramp
	clumpBin = _w.bin; clumpIsLead = _w.isLead; clumpStick = _w.stick
	clumpLeadX = _w.leadX; clumpLeadLen = _w.leadLen; clumpLeadLife = _w.leadLife; clumpLeadStep = _w.leadStep

	b = _b            // doCalc reads the instance variables b and v
	setID = _b
	sx = xx

	// lifeVariant is ALSO the global 'Variation' setting, so the per-set value
	// lives in a local (see the V1.95 notes in doMainStep).
	var _lvS = strandSetVariAdj[_b]
	var _hlB = strandLengthOverride[_b]
	if _hlB <= 0 _hlB = length
	hairLength = _hlB + preRandLifeVariant[_b]

	// ---- per-set constants, hoisted out of the strand and point loops ----
	var _padFactor = 0.05 + (padding / 1000)
	var _tMin  = setThickMinAdj[_b] * _padFactor
	var _tMax  = setThickMaxAdj[_b] * _padFactor
	var _tMax2 = _tMax * 2
	var cmx = setRootThickAdj[_b] / 30   // V1.91 per-set
	var cmy = setTipThickAdj[_b] / 30    // V1.91 per-set
	var _fadeInL  = (clamp(setFadeInAdj[_b],  1, 40) / 40) * 0.5   // x life
	var _fadeOutL = (clamp(setFadeOutAdj[_b], 1, 40) / 40) * 0.5   // x life
	var _wavyK   = (strandSetWavynessAdj[_b] * 0.01) * ampFactor
	var _taperK  = strandSetTaperAdj[_b] * 0.01
	var _taperK2 = clamp(strandSetTaperAdj[_b], 1, strandSetTaperAdj[_b]) * 0.01
	var _strK    = 0.5 + ((_lvS - 50) / 100)
	var _alphaK  = previewAlphaK
	var _widthK  = previewWidthK
	var _xo = xOffset[_b], _yo = yOffset[_b]

	var _cRvA = color_get_red(setColVarA[_b]);   var _cGvA = color_get_green(setColVarA[_b]);  var _cBvA = color_get_blue(setColVarA[_b])
	var _cRvB = color_get_red(setColVarB[_b]);   var _cGvB = color_get_green(setColVarB[_b]);  var _cBvB = color_get_blue(setColVarB[_b])
	var _cRrt = color_get_red(setRootCol[_b]);   var _cGrt = color_get_green(setRootCol[_b]);  var _cBrt = color_get_blue(setRootCol[_b])
	var _cRtp = color_get_red(setTipCol[_b]);    var _cGtp = color_get_green(setTipCol[_b]);   var _cBtp = color_get_blue(setTipCol[_b])

	// Everything the point loop touches is a local: in the VM, instance
	// variables and built-in calls (lerp, clamp ...) cost several times more
	// than local arithmetic, and this loop runs ~300 times per strand.
	var _ls = lut_sin, _lc = lut_cos, _mix = mixCacheX
	var _bl = setBBl[_b], _br = setBBr[_b], _bt = setBBt[_b], _bb = setBBb[_b]
	var _tSpan2 = _tMax2 - _tMin, _tSpan = _tMax - _tMin
	var _cStart = clumpStartS, _cRamp = clumpRampS
	var _lastCol = -1, _lastAlpha = -1
	var _segLen = _step * 0.25

	surface_set_target(previewSurf[_b])
	// doMainStep leaves alpha writes OFF at the end of every step. The old
	// rebuild always cleared first, which switched them back on; a resumed set
	// does not clear, and without this its strands were drawn with no alpha -
	// i.e. invisibly.
	gpu_set_colorwriteenable(1, 1, 1, 1)
	var _tDraw = get_timer(), _ptsDrawn = 0
	v = _vFrom
	while (v < _count)
	{
		doCalc()
		dpthAdd = preRandDepthAdd[_b, v]

		var _life = life, _root = root, _xx = xx, _yy = yy, _freq = freq, _amp = amp
		var _thick = thicknessBase, _setX = setXpos
		var _lifeRcp = 1 / _life
		var _k3800   = 3800 / _life
		var _lt      = _life - tip                 // tip colour starts ramping before this
		var _tDen    = tip * (_life / 3800)
		var _fiEnd   = _life * _fadeInL
		var _foLen   = _life * _fadeOutL
		var _foStart = _life - _foLen
		var _nzOn = noiseOn, _nzP1 = noiseP1, _nzP2 = noiseP2, _nzP3 = noiseP3
		var _nzS1 = noiseS1, _nzS2 = noiseS2, _nzS3 = noiseS3, _nzAmp = noiseAmpS

		// depth blend is constant along the strand
		var _blend = clamp(dpth + dpthAdd, 0, 1)
		var _sR = lerp(_cRvA, _cRvB, _blend), _sG = lerp(_cGvA, _cGvB, _blend), _sB = lerp(_cBvA, _cBvB, _blend)

		// ---- V1.96 clumping, per strand ----
		var _cMode = 0, _cBin = 0, _cIdx = 0, _cW = 0, _cLen = 0, _cK = 0, _cArr = 0
		if clumpOnS == 1
		{
			_cBin = clumpBin[v]
			if clumpIsLead[v] == 1 { _cMode = 1; _cArr = clumpLeadX[_cBin] }
			else if clumpLeadLen[_cBin] > 1
			{
				_cMode = 2
				_cW    = clumpAmtS * clumpStick[v]
				_cLen  = clumpLeadLen[_cBin]
				_cK    = clumpLeadLife[_cBin] / clumpLeadStep[_cBin]
				_cArr  = clumpLeadX[_cBin]
			}
		}

		var _ni = 0, _fx = 0, _lastRt = -1, _lastTp = -1
		for (var _n = 0; _n < _life; _n += _step)
		{
			var _t = _n * _lifeRcp

			// Thickness - LUT (matches dsin/dcos exactly)
			var _li90 = round(_t * 360) mod 1440
			var _scz  = _tMin + (_tSpan * _ls[round(_t * 720) mod 1440])
			var _scx  = _tMin + (_tSpan2 * _ls[_li90])
			var _scy  = _tMin + (_tSpan2 * _lc[_li90])
			var scA   = ((_scx + ((_scz - _scx) * cmx)) + (_scy + ((_scz - _scy) * cmy))) * _thick
			if scA < 0.15 scA = 0.15 else if scA > 100 scA = 100
			scA *= 0.5

			// Wave - LUT with amp inside the angle
			var _nx = _xx + (_ls[round(_n * _freq * _amp * 4) mod 1440] * (_yy / 100))

			var _sg = _xx + _mix[_ni]
			_sg += (_setX - _sg) * ((_n / 3000) * _taperK)
			var _alg = _xx + ((_nx - _xx) * _wavyK)
			_alg += (_sg - _alg) * _strK
			_fx = _alg + ((_setX - _alg) * (_t * _taperK2))

			// V1.90 NOISE - gradual left/right deviation, root anchored
			if _nzOn == 1
				_fx += ((_ls[round(_nzP1 + (_n * _nzS1)) mod 1440] * 0.62)
				      + (_ls[round(_nzP2 + (_n * _nzS2)) mod 1440] * 0.28)
				      + (_ls[round(_nzP3 + (_n * _nzS3)) mod 1440] * 0.10)) * _nzAmp * _t

			// V1.96 CLUMPING
			if _cMode == 1 { _cArr[@ _cIdx] = _fx; _cIdx++ }
			else if _cMode == 2
			{
				var _u = (_t - _cStart) * _cRamp
				if _u > 0
				{
					if _u > 1 _u = 1
					var _fi = _t * _cK
					if _fi > _cLen - 1 _fi = _cLen - 1
					var _i0 = floor(_fi)
					var _l0 = _cArr[_i0]
					var _lx = _l0 + ((_cArr[min(_i0 + 1, _cLen - 1)] - _l0) * (_fi - _i0))
					_fx += (_lx - _fx) * (_cW * _u * _u * (3 - (2 * _u)))
				}
			}

			if _fx + _xo < 4098 and _yy + _yo < 4070
			{
				// Root / tip tint. Both are constant along most of the strand, so
				// the colour is only rebuilt when one of them actually moves.
				var _rt = 0.01, _tp = 1
				if _root > _n { _rt = (_n * _k3800) / _root; _rt = (_rt > 1) ? 0 : 1 - _rt }
				if _lt > _n   { _tp = (_lt - _n) / _tDen;    _tp = (_tp > 1) ? 0 : 1 - _tp }
				if _rt != _lastRt or _tp != _lastTp
				{
					_lastRt = _rt; _lastTp = _tp
					var _r = _sR + ((_cRrt - _sR) * _rt), _g = _sG + ((_cGrt - _sG) * _rt), _bq = _sB + ((_cBrt - _sB) * _rt)
					var _col = make_color_rgb(_r + ((_cRtp - _r) * _tp), _g + ((_cGtp - _g) * _tp), _bq + ((_cBtp - _bq) * _tp))
					if _col != _lastCol { _lastCol = _col; draw_set_color(_col) }
				}

				// Alpha fade (V1.91 per-set). The body of the strand is fully
				// opaque, so the V1.93 opacity curve only runs inside the fades.
				var _al = 1
				if _n > _foStart or _n < _fiEnd + 1
				{
					var _a = 1
					if _n > _foStart   _a = clamp((_life - _n) / _foLen, 0, 1)
					if _n < _fiEnd + 1 _a = clamp(_n / _fiEnd, 0, 1)
					if _a < 1 _al = clamp(1 - power(1 - _a, max(1, _alphaK * scA)), 0, 1)
				}
				if _al != _lastAlpha { _lastAlpha = _al; draw_set_alpha(_al) }

				var _px = (_fx + _xo) * 0.25, _py = (_yy + _yo) * 0.25
				var _w = scA * _widthK
				draw_line_width(_px, _py, _px, _py + _segLen, (_w < 0.5) ? 0.5 : _w)   // V1.92

				if _bt == 0  _bt = _yy
				if _yy < _bt _bt = _yy
				if _yy > _bb _bb = _yy
				if _bl == 0  _bl = _fx
				if _fx < _bl _bl = _fx
				if _fx > _br _br = _fx
			}

			_yy += _step
			_ni++
		} // end point loop
		yy = _yy; finalX = _fx
		_ptsDrawn += _ni

		if _cMode == 1
		{
			clumpLeadLen[@ _cBin]  = _cIdx
			clumpLeadLife[@ _cBin] = _life
			clumpLeadStep[@ _cBin] = _step
		}

		v++
		pvStatStrands++
		if _deadline > 0 and get_timer() >= _deadline break
	} // end strand loop
	surface_reset_target()
	draw_set_color(c_white)
	draw_set_alpha(1)

	leftmost = _bl; rightmost = _br; topmost = _bt; bottommost = _bb

	// running cost per point, used to size the live coarse pass
	if _ptsDrawn > 200 pvUsPerPoint = lerp(pvUsPerPoint, (get_timer() - _tDraw) / _ptsDrawn, 0.25)
	setBBl[_b] = leftmost
	setBBr[_b] = rightmost
	setBBt[_b] = topmost
	setBBb[_b] = bottommost
	setBBxx[_b] = xx
	return v
}


/// Live coarse pass: redraw every set in _live now, sized to fit pvLiveBudget.
function previewLivePass(_live)
{
	var _nLive = array_length(_live)

	// Size the pass from the measured cost per point: first choice is every
	// strand at step 20, then every strand at step 40, then a share of each
	// set's strands at step 40. The share is always the FIRST strands of the
	// set, which keeps every clump leader in place.
	var _pts20 = 0
	for (var _i = 0; _i < _nLive; _i++)
	{
		var _pb = _live[_i]
		if pvSig[_pb][0] == 0 continue
		var _pl = strandLengthOverride[_pb]
		if _pl <= 0 _pl = length
		_pts20 += previewSetCount(_pb) * (_pl / 20)
	}
	var _cStep = 20, _frac = 1
	if _pts20 * pvUsPerPoint > pvLiveBudget
	{
		_cStep = 40
		_frac  = clamp(pvLiveBudget / max((_pts20 * 0.5) * pvUsPerPoint, 1), 0.08, 1)
	}

	for (var _j = 0; _j < _nLive; _j++)
	{
		var _lb = _live[_j]
		previewClearSet(_lb)
		if pvSig[_lb][0] == 0 { pvState[_lb] = 0; continue }   // hidden: cleared is all it needs
		var _cnt = previewSetCount(_lb)
		if _cnt <= 0 continue
		var _cc = clamp(ceil(_cnt * _frac), min(3, _cnt), _cnt)
		previewSetBegin(_lb, _cStep, _cc)
		previewDrawStrands(_lb, _cStep, _cc, 0, 0)
		pvStatCoarse++
	}
}


/// Clear set _b and get it ready to be drawn at full quality.
/// Returns false if there is nothing to draw (hidden, or no strands).
function previewStartFull(_b)
{
	previewClearSet(_b)
	pvV[_b]   = 0
	pvCnt[_b] = (pvSig[_b][0] == 0) ? 0 : previewSetCount(_b)
	if pvCnt[_b] <= 0 { pvState[_b] = 0; return false }
	previewSetBegin(_b, pvFullStep, pvCnt[_b])
	pvState[_b] = 3
	return true
}


/// Run once per frame, before the preview surfaces are composited.
function previewUpdate()
{
	pvBusy = 0

	// Nothing can be drawn behind the splash or during a render, and the
	// preview is only on screen in previewer mode. Signatures are not consumed
	// here, so whatever changed meanwhile is picked up on return.
	if firstTime or generating or img != 9 return

	var _t0 = get_timer()

	// Legacy "redraw everything" requests. Colour edits also raise forceUpdate
	// on every frame of a drag, but colours are part of each set's signature,
	// so a colour-only request needs nothing more than the comparison below.
	var _colourEdit = (colorOnlyUpdate == 1)
	var _force = (firstPass or seedUpdate == 1 or (forceUpdate == 1 and !_colourEdit))
	seedUpdate = 0
	forceUpdate = 0
	colorOnlyUpdate = 0
	firstPass = false

	// ---- 1. what changed? ----
	var _pathHash = previewPathHash()
	var _live = []
	var _dirty = false
	for (var _b = 0; _b <= sets; _b++)
	{
		var _sig = previewSetSig(_b, _pathHash)
		if !array_equals(_sig, pvSig[_b])
		{
			var _first = (array_length(pvSig[_b]) == 0)
			pvSig[_b]   = _sig
			pvQuiet[_b] = 0
			if _first pvState[_b] = 1                      // nothing drawn yet: grow in
			else { pvState[_b] = 2; array_push(_live, _b) } // changing: live coarse
		}
		else if pvState[_b] == 2
		{
			pvQuiet[_b]++
			if pvQuiet[_b] >= pvSettle pvState[_b] = 1
		}
		else if _force and (pvState[_b] == 0 or pvState[_b] == 3) pvState[_b] = 1   // e.g. surfaces lost
		if pvState[_b] != 0 _dirty = true
	}
	var _nLive = array_length(_live)

	if pvMode == 1
	{
		// ---- BUSY mode: the pre-1.96 feel ----
		// While the mouse is held on the panel nothing is redrawn and BUSY is
		// shown; on release every out-of-date set is redrawn in one go.
		// Dragging a set around the canvas and colour picking stayed live in
		// the old version too, so they still are.
		var _liveOK = (mouse_x < 1024 or _colourEdit)
		if _nLive > 0 and _liveOK previewLivePass(_live)
		else if _dirty
		{
			if mouse_check_button(mb_left) { if !_liveOK pvBusy = 1 }
			else
			{
				for (var _q = 0; _q <= sets; _q++)
				{
					if pvState[_q] == 0 continue
					if previewStartFull(_q) previewDrawStrands(_q, pvFullStep, pvCnt[_q], 0, 0)
					pvState[_q] = 0
				}
			}
		}
	}
	else if _nLive > 0
	{
		// ---- LIVE mode, values changing: coarse redraw of what changed ----
		previewLivePass(_live)
	}
	else if _dirty
	{
		// ---- LIVE mode, settled: grow the strands in ----
		// Every settled set is cleared and started together, then they are
		// drawn a couple of strands each in turn, so the whole preview fills
		// evenly instead of one set finishing before the next begins.
		for (var _r = 0; _r <= sets; _r++) if pvState[_r] == 1 previewStartFull(_r)

		var _deadline = _t0 + pvBudget
		var _n = sets + 1
		do
		{
			var _jb = -1
			for (var _k = 0; _k < _n; _k++)
			{
				var _c = (pvRR + _k) mod _n
				if pvState[_c] == 3 { _jb = _c; break }
			}
			if _jb == -1 break
			pvRR = (_jb + 1) mod _n

			pvV[_jb] = previewDrawStrands(_jb, pvFullStep, min(pvCnt[_jb], pvV[_jb] + pvChunk), pvV[_jb], _deadline)
			if pvV[_jb] >= pvCnt[_jb] pvState[_jb] = 0
		}
		until (get_timer() >= _deadline)
	}

	pvStatUs = get_timer() - _t0

	// kept for the code that still reads it
	previewCanvasComplete = 1
	for (var _c2 = 0; _c2 <= sets; _c2++) if pvState[_c2] != 0 { previewCanvasComplete = 0; break }
}


// -----------------------------------------------------------------------------
// PRE-RANDOM TABLES
// doMainStep used to call updatePreRands(-1) on EVERY step while pleaseGen was
// set - which is from the first edit until the next Generate, i.e. nearly
// always. That is ~16,000 random draws a frame (measured 4.5 ms) to produce
// exactly the numbers already in the tables: the tables are seeded per set, so
// they only ever change when one of the inputs below does.
// Now each set's inputs are compared each step and only a set whose inputs
// moved is rebuilt, through updatePreRands' existing single-set branch.
// -----------------------------------------------------------------------------
function preRandInputSig(_e)
{
	return [
		randomSeedVal[_e], strandSetVariAdj[_e], strandSetSpaceAdj[_e],
		strandSetWaveFreqMinAdj[_e], strandSetWaveFreqMaxAdj[_e], strandYRanRange[_e],
		rootPosition, moreHairs, curlRotAmt,
		strandLengthOverride[_e], length,
		setThickVaryAdj[_e], maxScale,
		setThickMinOverrode[_e], setThickMaxOverrode[_e], setThickMinAdj[_e], setThickMaxAdj[_e]
	]
}

function preRandsRefresh()
{
	for (var _e = 0; _e < 11; _e++)
	{
		var _sig = preRandInputSig(_e)
		if !array_equals(_sig, prSig[_e])
		{
			prSig[_e] = _sig
			updatePreRands(_e)
		}
	}
}
