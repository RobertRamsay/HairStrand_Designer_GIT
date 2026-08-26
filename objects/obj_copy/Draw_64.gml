/// @description Copy / paste the complete selected strand-set state.
/// Workflow: select set -> COPY -> select another set -> PASTE.
/// Global values, current selection and solo state are deliberately not copied.

var _o = instance_find(obj_surfaceDweller, 0)
if _o == noone
    {
    exit
    }

// Hide the panel while the startup splash is active.
if _o.firstTime or _o.canDrawUI != 1
    {
    exit
    }

// obj_copy has no Create event, so initialise its small clipboard lazily.
if !variable_instance_exists(id, "copyBufferReady")
    {
    copyBufferReady = 0
    copySourceSet = -1
    copyMsg = ""
    copyMsgTimer = 0
    }

var _mx = device_mouse_x_to_gui(0)
var _my = device_mouse_y_to_gui(0)
var _selected = _o.setSelectedID

// Compact panel around the original obj_copy room position.
var _copyL = x - 68
var _copyR = x - 6
var _pasteL = x + 6
var _pasteR = x + 76
var _top = y - 20
var _bottom = y + 5

var _copyHover = point_in_rectangle(_mx, _my, _copyL, _top, _copyR, _bottom)
var _pasteHover = point_in_rectangle(_mx, _my, _pasteL, _top, _pasteR, _bottom)

// -----------------------------------------------------------------------------
// DRAW
// -----------------------------------------------------------------------------
draw_set_font(smallFont)
draw_set_halign(fa_left)
draw_set_valign(fa_bottom)

// Source/selection hint above the buttons.
draw_set_color(c_gray)
var _hint = "Select a set"
if _selected != -1 _hint = "Selected Set " + string(_selected + 1)
if copyBufferReady
    {
    _hint += "   Copied Set " + string(copySourceSet + 1)
    }
draw_text(_copyL, _top - 5, _hint)

// Button backgrounds.
draw_set_color(make_color_rgb(32,32,32))
draw_rectangle(_copyL, _top, _copyR, _bottom, false)
draw_rectangle(_pasteL, _top, _pasteR, _bottom, false)

// Button outlines / hover state.
draw_set_color((_selected != -1) ? c_gray : make_color_rgb(55,55,55))
if _copyHover and _selected != -1 draw_set_color(c_white)
draw_rectangle(_copyL, _top, _copyR, _bottom, true)

draw_set_color((copyBufferReady and _selected != -1) ? c_gray : make_color_rgb(55,55,55))
if _pasteHover and copyBufferReady and _selected != -1 draw_set_color(c_white)
draw_rectangle(_pasteL, _top, _pasteR, _bottom, true)

// Labels.
draw_set_color((_selected != -1) ? c_white : c_gray)
draw_text(_copyL + 10, y, "COPY")

draw_set_color((copyBufferReady and _selected != -1) ? c_white : c_gray)
draw_text(_pasteL + 10, y, "PASTE")

// -----------------------------------------------------------------------------
// COPY
// Snapshot all user-facing per-set values plus their override flags.
// ----------------------------------------------------------------------------
if _copyHover and mouse_check_button_pressed(mb_left) and _selected != -1
    {
    var _src = _selected

    copyBuffer = {
        // Core strand values.
        strandCountOverride : _o.strandCountOverride[_src],
        strandLengthOverride : _o.strandLengthOverride[_src],
        setCountOverrode : _o.setCountOverrode[_src],
        setLengthOverrode : _o.setLengthOverrode[_src],

        // Shape / distribution overrides.
        strandSetTaperAdj : _o.strandSetTaperAdj[_src],
        setTaperOverrode : _o.setTaperOverrode[_src],
        strandSetWavynessAdj : _o.strandSetWavynessAdj[_src],
        setWaveynessOverrode : _o.setWaveynessOverrode[_src],
        strandSetWaveFreqMinAdj : _o.strandSetWaveFreqMinAdj[_src],
        setWaveFreqMinOverrode : _o.setWaveFreqMinOverrode[_src],
        strandSetWaveFreqMaxAdj : _o.strandSetWaveFreqMaxAdj[_src],
        setWaveFreqMaxOverrode : _o.setWaveFreqMaxOverrode[_src],
        strandSetVariAdj : _o.strandSetVariAdj[_src],
        setVariOverrode : _o.setVariOverrode[_src],
        strandSetSpaceAdj : _o.strandSetSpaceAdj[_src],
        setSpacingOverrode : _o.setSpacingOverrode[_src],
        strandYRanRange : _o.strandYRanRange[_src],
        strandYRanRangeOverrode : _o.strandYRanRangeOverrode[_src],

        // Mixer values and override flags.
        strandSetMixerAdj1 : _o.strandSetMixerAdj1[_src],
        strandSetMixerOffsetAdj1 : _o.strandSetMixerOffsetAdj1[_src],
        setMixerAmt1Overrode : _o.setMixerAmt1Overrode[_src],
        setMixerOfs1Overrode : _o.setMixerOfs1Overrode[_src],
        strandSetMixerAdj2 : _o.strandSetMixerAdj2[_src],
        strandSetMixerOffsetAdj2 : _o.strandSetMixerOffsetAdj2[_src],
        setMixerAmt2Overrode : _o.setMixerAmt2Overrode[_src],
        setMixerOfs2Overrode : _o.setMixerOfs2Overrode[_src],
        strandSetMixerAdj3 : _o.strandSetMixerAdj3[_src],
        strandSetMixerOffsetAdj3 : _o.strandSetMixerOffsetAdj3[_src],
        setMixerAmt3Overrode : _o.setMixerAmt3Overrode[_src],
        setMixerOfs3Overrode : _o.setMixerOfs3Overrode[_src],

        // Algorithm influence.
        // NOTE: xOffset / yOffset are deliberately NOT captured. A paste must
        // only move settings, never move the destination set on the canvas.
        alogrithmInfluence : _o.alogrithmInfluence[_src],
        taperInfluence : _o.taperInfluence[_src],

        // Per-set random / thickness additions.
        randomSeedVal : _o.randomSeedVal[_src],
        randomOverride : _o.randomOverride[_src],
        setThickMinAdj : _o.setThickMinAdj[_src],
        setThickMaxAdj : _o.setThickMaxAdj[_src],
        setThickMinOverrode : _o.setThickMinOverrode[_src],
        setThickMaxOverrode : _o.setThickMaxOverrode[_src],

        // V1.85 per-set colour values and per-channel override flags.
        setColVarA : _o.setColVarA[_src],
        setColVarB : _o.setColVarB[_src],
        setRootCol : _o.setRootCol[_src],
        setTipCol : _o.setTipCol[_src],
        setColVarAOverrode : _o.setColVarAOverrode[_src],
        setColVarBOverrode : _o.setColVarBOverrode[_src],
        setRootColOverrode : _o.setRootColOverrode[_src],
        setTipColOverrode : _o.setTipColOverrode[_src]
    }

    copyBufferReady = 1
    copySourceSet = _src
    copyMsg = "Copied Set " + string(_src + 1)
    copyMsgTimer = 120
    }

// -----------------------------------------------------------------------------
// PASTE
// Replace the currently selected set with the saved set state.
// Override flags are copied too, preserving global-following behaviour.
// ----------------------------------------------------------------------------
if _pasteHover and mouse_check_button_pressed(mb_left)
and copyBufferReady and _selected != -1
    {
    var _dst = _selected

    _o.strandCountOverride[_dst] = copyBuffer.strandCountOverride
    _o.strandLengthOverride[_dst] = copyBuffer.strandLengthOverride
    _o.setCountOverrode[_dst] = copyBuffer.setCountOverrode
    _o.setLengthOverrode[_dst] = copyBuffer.setLengthOverrode

    _o.strandSetTaperAdj[_dst] = copyBuffer.strandSetTaperAdj
    _o.setTaperOverrode[_dst] = copyBuffer.setTaperOverrode
    _o.strandSetWavynessAdj[_dst] = copyBuffer.strandSetWavynessAdj
    _o.setWaveynessOverrode[_dst] = copyBuffer.setWaveynessOverrode
    _o.strandSetWaveFreqMinAdj[_dst] = copyBuffer.strandSetWaveFreqMinAdj
    _o.setWaveFreqMinOverrode[_dst] = copyBuffer.setWaveFreqMinOverrode
    _o.strandSetWaveFreqMaxAdj[_dst] = copyBuffer.strandSetWaveFreqMaxAdj
    _o.setWaveFreqMaxOverrode[_dst] = copyBuffer.setWaveFreqMaxOverrode
    _o.strandSetVariAdj[_dst] = copyBuffer.strandSetVariAdj
    _o.setVariOverrode[_dst] = copyBuffer.setVariOverrode
    _o.strandSetSpaceAdj[_dst] = copyBuffer.strandSetSpaceAdj
    _o.setSpacingOverrode[_dst] = copyBuffer.setSpacingOverrode
    _o.strandYRanRange[_dst] = copyBuffer.strandYRanRange
    _o.strandYRanRangeOverrode[_dst] = copyBuffer.strandYRanRangeOverrode

    _o.strandSetMixerAdj1[_dst] = copyBuffer.strandSetMixerAdj1
    _o.strandSetMixerOffsetAdj1[_dst] = copyBuffer.strandSetMixerOffsetAdj1
    _o.setMixerAmt1Overrode[_dst] = copyBuffer.setMixerAmt1Overrode
    _o.setMixerOfs1Overrode[_dst] = copyBuffer.setMixerOfs1Overrode
    _o.strandSetMixerAdj2[_dst] = copyBuffer.strandSetMixerAdj2
    _o.strandSetMixerOffsetAdj2[_dst] = copyBuffer.strandSetMixerOffsetAdj2
    _o.setMixerAmt2Overrode[_dst] = copyBuffer.setMixerAmt2Overrode
    _o.setMixerOfs2Overrode[_dst] = copyBuffer.setMixerOfs2Overrode
    _o.strandSetMixerAdj3[_dst] = copyBuffer.strandSetMixerAdj3
    _o.strandSetMixerOffsetAdj3[_dst] = copyBuffer.strandSetMixerOffsetAdj3
    _o.setMixerAmt3Overrode[_dst] = copyBuffer.setMixerAmt3Overrode
    _o.setMixerOfs3Overrode[_dst] = copyBuffer.setMixerOfs3Overrode

    // xOffset / yOffset intentionally untouched - the destination set keeps the
    // X / Y position it already had.
    _o.alogrithmInfluence[_dst] = copyBuffer.alogrithmInfluence
    _o.taperInfluence[_dst] = copyBuffer.taperInfluence

    _o.randomSeedVal[_dst] = copyBuffer.randomSeedVal
    _o.randomOverride[_dst] = copyBuffer.randomOverride
    _o.setThickMinAdj[_dst] = copyBuffer.setThickMinAdj
    _o.setThickMaxAdj[_dst] = copyBuffer.setThickMaxAdj
    _o.setThickMinOverrode[_dst] = copyBuffer.setThickMinOverrode
    _o.setThickMaxOverrode[_dst] = copyBuffer.setThickMaxOverrode

    _o.setColVarA[_dst] = copyBuffer.setColVarA
    _o.setColVarB[_dst] = copyBuffer.setColVarB
    _o.setRootCol[_dst] = copyBuffer.setRootCol
    _o.setTipCol[_dst] = copyBuffer.setTipCol
    _o.setColVarAOverrode[_dst] = copyBuffer.setColVarAOverrode
    _o.setColVarBOverrode[_dst] = copyBuffer.setColVarBOverrode
    _o.setRootColOverrode[_dst] = copyBuffer.setRootColOverrode
    _o.setTipColOverrode[_dst] = copyBuffer.setTipColOverrode

    // The colour picker exposes the selected set via custom*. Keep it in sync,
    // but also update the last-value trackers so Step_0 does not mistake Paste
    // for a new user colour edit and alter the override flags again.
    _o.customColVarA = _o.setColVarA[_dst]
    _o.customColVarB = _o.setColVarB[_dst]
    _o.customRootCol = _o.setRootCol[_dst]
    _o.customTipCol = _o.setTipCol[_dst]
    _o.colourUiLastA = _o.customColVarA
    _o.colourUiLastB = _o.customColVarB
    _o.colourUiLastRoot = _o.customRootCol
    _o.colourUiLastTip = _o.customTipCol
    _o.colourUiLastSet = _dst

    if variable_instance_exists(_o, "colourSelectedSlot")
        {
        if _o.colourSelectedSlot == 0 _o.newColor = _o.colrBack
        if _o.colourSelectedSlot == 1 _o.newColor = _o.customColVarA
        if _o.colourSelectedSlot == 2 _o.newColor = _o.customColVarB
        if _o.colourSelectedSlot == 3 _o.newColor = _o.customRootCol
        if _o.colourSelectedSlot == 4 _o.newColor = _o.customTipCol
        _o.storeColor = _o.newColor
        _o.colourSelectedStoreColor = _o.newColor
        }

    // Close any active numeric edit so the old textbox cannot overwrite the
    // freshly pasted value on the next Draw frame.
    with (_o)
        {
        reset_textBoxes()
        }

    // A full set paste can affect every generated map, not only colour.
    if _o.rgbMask_GenState == 2 _o.rgbMask_GenState = 1
    if _o.norm_GenState == 2 _o.norm_GenState = 1
    if _o.mask_GenState == 2 _o.mask_GenState = 1
    if _o.color_GenState == 2 _o.color_GenState = 1
    if _o.id_GenState == 2 _o.id_GenState = 1
    if _o.depth_GenState == 2 _o.depth_GenState = 1
    if _o.flow_GenState == 2 _o.flow_GenState = 1
    if _o.ao_GenState == 2 _o.ao_GenState = 1
    if _o.frizz_GenState == 2 _o.frizz_GenState = 1

    _o.previewCanvasComplete = 0
    _o.colorOnlyUpdate = 0
    _o.forceUpdate = 1
    _o.seedUpdate = 1
    _o.firstCalc = 1
    _o.pleaseGen = true
    _o.retrigger = true
    _o.changesMade = true

    copyMsg = "Pasted Set " + string(copySourceSet + 1)
        + " -> Set " + string(_dst + 1)
    copyMsgTimer = 120
    }

// Short confirmation line; expires automatically.
if copyMsgTimer > 0
    {
    copyMsgTimer--
    draw_set_color(c_ltgray)
    draw_text(_copyL, _top - 22, copyMsg)
    }

draw_set_color(c_white)
draw_set_halign(fa_left)
draw_set_valign(fa_bottom)
