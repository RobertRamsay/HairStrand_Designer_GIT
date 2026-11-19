// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// mainCalc - PER-FRAME PREVIEW UPDATE + COMPOSITE
//
// CALLED BY  obj_surfaceDweller Draw_0, once per frame, while drawing to the
//            screen (so everything drawn here lands in the 1024x1024 view).
//
// WHAT IT DOES, in order
//   1. Puts back the colour slot the user actually clicked (see first comment).
//   2. previewUpdate() (previewJob) - redraws whichever of the 11 preview
//      surfaces are out of date. This is the only place the preview is rebuilt.
//   3. Composites previewSurf[0..10] to the screen, set 0 first, set 10 on top,
//      with or without the smoothing shader.
//   4. Draws the BUSY text and the set highlight boxes (doHighlighting).
//
// The strand maths is NOT in here any more - it lives in previewDrawStrands.
//
// SCALE  Strand positions are kept in 4096x4096 map pixels. The preview
//        surfaces are 1024x1024, so anything turned into a preview/screen
//        position is multiplied by 0.25, and mouse positions are multiplied
//        by 4 to go the other way.
//
// READS  previewSurf[], setBBl/r/t/b[] (per-set bounding box in 4096 space,
//        without the set offset), xOffset[], yOffset[], pvDrawnStep[], pvSmooth,
//        pvBusy, img (9 = previewer view), firstPass, colourSelectedSlot.
// WRITES draw colour, blend mode (bm_normal), the *_active colour flags,
//        storeColor, newColor. Uses the instance variable n as a loop counter.
// =============================================================================
function mainCalc(){

// Draw_0's legacy colour-source block runs before mainCalc() and changes the
// active colour merely from hover position. Restore the authoritative click-only
// selection here before the rest of the colour UI is drawn or interacted with.
if variable_instance_exists(id,"colourSelectedSlot")
    {
    bkCol_active=0
    ColA_active=0
    ColB_active=0
    RootCol_active=0
    TipCol_active=0
    if colourSelectedSlot==0 bkCol_active=1
    if colourSelectedSlot==1 ColA_active=1
    if colourSelectedSlot==2 ColB_active=1
    if colourSelectedSlot==3 RootCol_active=1
    if colourSelectedSlot==4 TipCol_active=1

    storeColor=colourSelectedStoreColor
    if colourSelectedSlot==0 newColor=colrBack
    if colourSelectedSlot==1 newColor=customColVarA
    if colourSelectedSlot==2 newColor=customColVarB
    if colourSelectedSlot==3 newColor=customRootCol
    if colourSelectedSlot==4 newColor=customTipCol
    }

draw_set_color(c_white)

// -----------------------------------------------------------------------
// V1.96 PROGRESSIVE PREVIEW (see previewJob)
// This function used to decide WHEN to rebuild from the mouse position and
// button state, clear every set, show BUSY while a slider was held, and then
// redraw all eleven sets in a single frame on release.
// previewUpdate() replaces all of that: it notices which sets actually
// changed, redraws those coarsely while they are changing, and grows the
// full-quality strands in over the following frames within a time budget.
// It runs BEFORE the composite, so a set is never shown blank for a frame.
// -----------------------------------------------------------------------
var _wasFirstPass = firstPass   // previewUpdate clears firstPass, so remember it for the fade test below
previewUpdate()

gpu_set_blendmode(bm_normal)
// While the left button is held over the canvas (dragging a set about) the
// strands are shown at one-third opacity. Not on the very first frame.
var alp=1.0
if img==9 and mouse_x<1024 and mouse_check_button(mb_left) and !_wasFirstPass  alp=0.33

if pvSmooth==1 and img==9
    {
    // V1.96 - realtime smoothing (shd_previewSmooth). Only the part of each
    // surface that holds strands is drawn, using the bounding box the preview
    // already keeps, so eleven full-screen filtered layers cost about one.
    // The blend distance follows the dash length the set was drawn with, so
    // the coarse live pass is smoothed as well as the finished strands.
    shader_set(shd_previewSmooth)
    shader_set_uniform_f(pvSmoothTexel,1/1024,1/1024)
    for(n=0;n<11;n++)
        {
        if setBBr[n]==0 and setBBb[n]==0 continue      // nothing drawn in this set
        // _dash = length of one preview dash in SCREEN pixels: the point step
        //         the set was last drawn with (10 full quality, 20 or 40 live)
        //         x 0.25.
        // _rad  = shader blend distance, a little over one dash, kept
        //         between 2.5 and 14 px.
        // _mg   = margin added round the box so the blur is not cut off.
        // The box is the set's bounding box moved by its offset and scaled
        // x 0.25 to screen pixels. The surface part is drawn at the same
        // position it was cut from, so it lines up with an unfiltered draw.
        var _dash=pvDrawnStep[n]*0.25
        var _rad=clamp(_dash*1.15,2.5,14)
        var _mg=ceil(_rad)+8
        var _x1=clamp(floor((setBBl[n]+xOffset[n])*0.25)-_mg,0,1024)
        var _x2=clamp(ceil((setBBr[n]+xOffset[n])*0.25)+_mg,0,1024)
        var _y1=clamp(floor((setBBt[n]+yOffset[n])*0.25)-_mg,0,1024)
        var _y2=clamp(ceil((setBBb[n]+yOffset[n])*0.25+_dash)+_mg,0,1024)
        if _x2<=_x1 or _y2<=_y1 continue
        shader_set_uniform_f(pvSmoothRadius,_rad)
        draw_surface_part_ext(previewSurf[n],_x1,_y1,_x2-_x1,_y2-_y1,_x1,_y1,1,1,c_white,alp)
        }
    shader_reset()
    }
else
    {
    // Smoothing off (or not in the previewer view): draw all 11 surfaces whole.
    for(n=0;n<11;n++)
        draw_surface_ext(previewSurf[n],0,0,1,1,0,c_white,alp)
    }

// BUSY update mode only (the toggle beside SINGLE/MULTI STRAND)
if pvBusy==1 draw_text(512,512,"BUSY")

// Set outlines, number labels and click-to-select on the canvas.
// NOTE: setSelected is an ARRAY (one flag per set), so "setSelected!=-1" does
// not test whether a set is selected. The selected set is setSelectedID.
if img==9 and setSelected!=-1 doHighlighting()

} // end function
