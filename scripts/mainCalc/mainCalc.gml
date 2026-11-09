// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
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
var _wasFirstPass = firstPass
previewUpdate()

gpu_set_blendmode(bm_normal)
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
    for(n=0;n<11;n++)
        draw_surface_ext(previewSurf[n],0,0,1,1,0,c_white,alp)
    }

// BUSY update mode only (the toggle beside SINGLE/MULTI STRAND)
if pvBusy==1 draw_text(512,512,"BUSY")

if img==9 and setSelected!=-1 doHighlighting()

} // end function
