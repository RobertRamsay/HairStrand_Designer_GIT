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
// V1.91 LOCAL PREVIEW REBUILD
// Every preview surface is per-set (previewSurf[0..10]). When the only thing
// that changed is one set's own override, there is no reason to clear and
// redraw the other ten - so the rebuild is limited to that single set.
// Draw_0 clears localUpdateSet immediately after calling mainCalc(), so it
// only ever describes the edit made on the previous frame.
// Because that rebuild is roughly a tenth of the work, it is also cheap
// enough to run WHILE the slider is being dragged, every liveLocalEvery
// frames, instead of waiting for the mouse release.
// -----------------------------------------------------------------------
var _localOnly = 0
var _localSet  = -1
var _localLive = 0

if localUpdateSet >= 0 and localUpdateSet <= sets
and colorOnlyUpdate == 0 and forceUpdate == 0 and seedUpdate == 0
    {
    _localOnly = 1
    _localSet  = localUpdateSet
    }

if _localOnly == 1 and img == 9 and !firstTime
    {
    liveLocalTick++
    if liveLocalTick >= liveLocalEvery or mouse_check_button_released(mb_left)
        {
        liveLocalTick = 0
        _localLive    = 1
        }
    }
else
    {
    liveLocalTick = liveLocalEvery
    }

// Surfaces are composited to the screen BEFORE the rebuild further down, so a
// surface cleared up here would be shown empty for one frame. At 20 rebuilds a
// second that reads as a strobe, so the local path never clears here - it
// clears inside the rebuild instead, after the composite.
if _localLive == 1 previewCanvasComplete = 0

// MAIN CALCULATION
var clearOfBits=-1
if !point_in_rectangle(mouse_x,mouse_y,0,0,1920,11) and !point_in_rectangle(mouse_x,mouse_y,1567,540,1632,674)
    clearOfBits=1

// Skip surface clear for colour-only updates
if _localOnly==0 and colorOnlyUpdate==0 and
(((( img==9 and (mouse_x>1024 and mouse_y>412) or (mouse_x<1024)) and (img==9
and (mouse_check_button_released(mb_left)) or mouse_check_button_released(mb_right)) or firstPass)
and !firstTime and clearOfBits) or (img==9 and seedUpdate==1) or (img==9 and forceUpdate==1))
    {
    for (n=0;n<11;n++)
        {
        random_set_seed(randomSeedVal[n])
        surface_set_target(previewSurf[n])
        gpu_set_colorwriteenable(1,1,1,0)
        draw_clear_alpha(0,0)
        gpu_set_colorwriteenable(1,1,1,1)
        surface_reset_target()
        }
    previewCanvasComplete=0
    }

gpu_set_blendmode(bm_normal)
var alp=1.0
if img==9 and mouse_x<1024 and mouse_check_button(mb_left) and !firstPass  alp=0.33

for(n=0;n<11;n++)
    draw_surface_ext(previewSurf[n],0,0,1,1,0,c_white,alp)

// V1.91 - a local edit repaints live, so it is not "busy" in the old sense.
if ((img==9 and ((mouse_x>1024 and mouse_y>412) or (mouse_x<1024)) and mouse_check_button(mb_left)
and clearOfBits) or (img==9 and seedUpdate==1)) and _localOnly==0
    draw_text(512,512,"BUSY")

// ---- UPDATE MODE ----
if (img==9 and previewCanvasComplete==0) or (colorOnlyUpdate==1 and previewCanvasComplete==0) or firstPass
and ((colorOnlyUpdate==1 and previewCanvasComplete==0)
or (((img==9 and !mouse_check_button(mb_left)) and previewCanvasComplete==0 or firstPass)
    and !firstTime and clearOfBits)
or (img==9 and seedUpdate==1))
or (_localLive==1 and previewCanvasComplete==0)
#region
    {
    if colorOnlyUpdate==1 {
        for (var _cn=0;_cn<11;_cn++) {
            random_set_seed(randomSeedVal[_cn])
            surface_set_target(previewSurf[_cn])
            gpu_set_colorwriteenable(1,1,1,0)
            draw_clear_alpha(0,0)
            gpu_set_colorwriteenable(1,1,1,1)
            surface_reset_target()
        }
    }
    seedUpdate=0
    forceUpdate=0
    optimalStep=(colorOnlyUpdate==1) ? 30 : 10
    // A live drag redraws many times a second, so trade a little fidelity for
    // responsiveness; the release-frame rebuild goes back to the full step.
    if _localLive==1 and mouse_check_button(mb_left) optimalStep=20
    if dance==0 random_set_seed(seedVal)
    if setSelectedID=-1 seedVal=random_get_seed()
    numSel=0

    var _bFrom = 0
    var _bTo   = sets
    if _localOnly==1
        {
        _bFrom = _localSet
        _bTo   = _localSet

        // Cleared here, after the composite above, so the set is never shown blank.
        surface_set_target(previewSurf[_localSet])
        gpu_set_colorwriteenable(1,1,1,0)
        draw_clear_alpha(0,0)
        gpu_set_colorwriteenable(1,1,1,1)
        surface_reset_target()
        }

    for (b=_bFrom;b<_bTo+1;b++)
        {
        random_set_seed(randomSeedVal[b])
        leftmost=0;rightmost=0;topmost=0;bottommost=0

        if (setToSolo==b or setToSolo==-1)
            {
            setID=b
            sx=xx
            lifeVariant=strandSetVariAdj[b]
            // V1.95 - was conditional, so a set whose Length override is 0 (the slider
            // reaches 0) silently inherited the PREVIOUS set's hairLength. Set 0 inherits
            // from set 10 of the PREVIOUS FRAME, which is why the first set is the one seen
            // to move after a reload.
            var _hlB = strandLengthOverride[b]
            if _hlB<=0 _hlB = length
            hairLength = _hlB + preRandLifeVariant[b]
            if setCountOverrode[b]==1 {strandSet=strandCountOverride[b]} else {strandSet=strands}

            for (v=0;v<clamp(strandSet,0,maxPreviewStrandsPerSet);v++)
                {
                doCalc()

                var t_minScale=setThickMinAdj[b]
                var t_maxScale=setThickMaxAdj[b]
                var cmx=setRootThickAdj[b]/30 // V1.91 per-set
                var cmy=setTipThickAdj[b]/30 // V1.91 per-set
                var _fadeInS=clamp(setFadeInAdj[b],1,40)   // V1.91 per-set
                var _fadeOutS=clamp(setFadeOutAdj[b],1,40) // V1.91 per-set
                var _padFactor=0.05+(padding/1000)
                var _tMin=t_minScale*_padFactor
                var _tMax=t_maxScale*_padFactor
                var _tMax2=_tMax*2

                // Pre-extract this set's colour channels once per strand
                var _cRvA=color_get_red(setColVarA[b]);   var _cGvA=color_get_green(setColVarA[b]);  var _cBvA=color_get_blue(setColVarA[b])
                var _cRvB=color_get_red(setColVarB[b]);   var _cGvB=color_get_green(setColVarB[b]);  var _cBvB=color_get_blue(setColVarB[b])
                var _cRroot=color_get_red(setRootCol[b]); var _cGroot=color_get_green(setRootCol[b]);var _cBroot=color_get_blue(setRootCol[b])
                var _cRtip=color_get_red(setTipCol[b]);   var _cGtip=color_get_green(setTipCol[b]);  var _cBtip=color_get_blue(setTipCol[b])

                // Pre-compute per-strand LUT index strides
                // thickness: dsin(n/life*90)  -> lut_sin[round(n/life*360) mod 1440]
                // thickness: dcos(n/life*90)  -> lut_cos[round(n/life*360) mod 1440]
                // thickness: dsin(n/life*180) -> lut_sin[round(n/life*720) mod 1440]
                // wave:      sin(degtorad(n*freq)*amp) -> lut_sin[round(n*freq*amp*4) mod 1440]
                // deviation: sin(degtorad(n*freq))     -> lut_sin[round(n*freq*4) mod 1440]
                var _lifeRcp=1/life // avoid repeated division in loop

                surface_set_target(previewSurf[b])
                for(n=0;n<life;n+=optimalStep)
                    {
                    if root>n {rt=1-(clamp((n*(3800/life))/root,0,1))} else rt=0.01
                    if life-tip>n {tp=1-(clamp(abs((life-tip-n))/(tip*(life/3800)),0,1))} else tp=1
                    a=1 // V1.94 - was never reset, so the body of every strand kept the
                        // last fade-in sample's alpha instead of being fully opaque

                    // Thickness — LUT (matches dsin/dcos exactly)
                    var _li90  = round(n*_lifeRcp*360) mod 1440
                    var _li180 = round(n*_lifeRcp*720) mod 1440
                    var scx=lerp(_tMin,_tMax2,lut_sin[_li90])
                    var scy=lerp(_tMin,_tMax2,lut_cos[_li90])
                    var scz=lerp(_tMin,_tMax, lut_sin[_li180])
                    var tA=lerp(scx,scz,cmx)
                    var tB=lerp(scy,scz,cmy)
                    var scA=(clamp((tA+tB)*thicknessBase,0.15,100)/2) // V1.92 - same order as doMainStep
                    dpthAdd=preRandDepthAdd[b,v]

                    // Alpha fade - V1.91 per-set. The old code clamped the
                    // GLOBAL fadeIn/fadeOut from inside the point loop; the
                    // per-set values are clamped once, before the loop.
                    if (n>life-((_fadeOutS/40)*(life/2))) {a=clamp((life-n)/((_fadeOutS/40)*(life/2)),0,1)}
                    if (n<((_fadeInS/40)*(life/2))+1)     {a=clamp(n/((_fadeInS/40)*(life/2)),0,1)}

                    // Wave — LUT with amp inside angle (matches original sin(degtorad(n*freq)*amp))
                    var _liDev  = round(n*freq*4)       mod 1440  // deviation: sin(degtorad(n*freq))
                    var _liWave = round(n*freq*amp*4)   mod 1440  // wave:      sin(degtorad(n*freq)*amp)
                    deviationFromX = lut_sin[_liDev]
                    nx = xx + (lut_sin[_liWave] * (yy/100))

                    var xA=lerp(0,path_get_x(editingPath[0],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj1[b]*100))),strandSetMixerAdj1[b])
                    var xB=lerp(0,path_get_x(editingPath[1],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj2[b]*100))),strandSetMixerAdj2[b])
                    var xC=lerp(0,path_get_x(editingPath[2],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj3[b]*100))),strandSetMixerAdj3[b])
                    var tempX=(lerp(lerp(xA,xB,0.5),xC,0.5)/lifeVariant)*8
                    straggleXX=lerp(xx+tempX,setXpos,(n/3000)*(strandSetTaperAdj[b]*0.01))
                    var algFinalX=lerp((lerp(xx,nx,(strandSetWavynessAdj[b]*0.01)*ampFactor)),straggleXX,0.5+((lifeVariant-50)/100))
                    var algTaper=lerp(algFinalX,setXpos,(n/life)*(clamp(strandSetTaperAdj[b],1,strandSetTaperAdj[b])*0.01))

                    // V1.90 NOISE - gradual left/right deviation, root anchored.
                    var _nzOfs=0
                    if noiseOn==1
                        {
                        var _n1=lut_sin[round(noiseP1+(n*noiseS1)) mod 1440]
                        var _n2=lut_sin[round(noiseP2+(n*noiseS2)) mod 1440]
                        var _n3=lut_sin[round(noiseP3+(n*noiseS3)) mod 1440]
                        _nzOfs=((_n1*0.62)+(_n2*0.28)+(_n3*0.10))*noiseAmpS*(n/life)
                        }

                    finalX=algTaper+_nzOfs

                    // Colour — pre-extracted channels
                    var _blend=clamp(dpth+dpthAdd,0,1)
                    var _cr=lerp(_cRvA,_cRvB,_blend); var _cg=lerp(_cGvA,_cGvB,_blend); var _cb=lerp(_cBvA,_cBvB,_blend)
                    _cr=lerp(_cr,_cRroot,rt); _cg=lerp(_cg,_cGroot,rt); _cb=lerp(_cb,_cBroot,rt)
                    _cr=lerp(_cr,_cRtip,tp);  _cg=lerp(_cg,_cGtip,tp);  _cb=lerp(_cb,_cBtip,tp)
                    colrCustom=make_color_rgb(_cr,_cg,_cb)

                    draw_set_color(colrCustom)
                    draw_set_alpha(clamp(1-power(1-clamp(a,0,1),max(1,previewAlphaK*scA)),0,1)) // V1.93 - see previewAlphaK

                    if set_active[setID]==0 and !generating
                        {
                        if finalX+xOffset[b]<4098 && yy+yOffset[b]<4070 and firstTime==0
                            {
                            if setHovveredID==b {} // hovered highlight handled elsewhere
                            draw_line_width((finalX+xOffset[b])*0.25,(yy+yOffset[b])*0.25,(finalX+xOffset[b])*0.25,(yy+yOffset[b])*0.25+(optimalStep*0.25),max(scA*previewWidthK,0.5))   // V1.92 - matches the final sprite footprint
                            if topmost==0           topmost=yy
                            if yy<topmost           topmost=yy
                            if yy>bottommost        bottommost=yy
                            if leftmost==0          leftmost=finalX
                            if finalX<leftmost      leftmost=finalX
                            if finalX>rightmost     rightmost=finalX
                            }
                        }

                    draw_set_color(c_white)
                    draw_set_alpha(1)
                    yy+=optimalStep
                    } // end n loop
                surface_reset_target()
                } // end v loop
            }
        } // end b loop

    previewCanvasComplete=1
    colorOnlyUpdate=0
    firstPass=false
    }
#endregion

// ---- REALTIME MODE ----
if (img==9 and mouse_x<1024 and mouse_check_button(mb_left)) or mouse_check_button_released(mb_right)
#region
    {
    optimalStep=160
    if dance==0 random_set_seed(seedVal)
    seedVal=random_get_seed()
    numSel=0

    for (b=0;b<sets+1;b++)
        {
        if setSelectedID==b {
			random_set_seed(randomSeedVal[b]) // ← add this
            leftmost=0;rightmost=0;topmost=0;bottommost=0

            if (setToSolo==b or setToSolo==-1)
                {
                setID=b
                sx=xx
                lifeVariant=strandSetVariAdj[b]
                var _hlB2 = strandLengthOverride[b]   // V1.95 - see the first loop
                if _hlB2<=0 _hlB2 = length
                hairLength = _hlB2 + preRandLifeVariant[b]
                if setCountOverrode[b]==1 {strandSet=strandCountOverride[b]} else {strandSet=strands}

                for (v=0;v<clamp(strandSet,0,maxPreviewStrandsPerSet);v++)
                    {
                    doCalc()

                    var t_minScale=setThickMinAdj[b]
                    var t_maxScale=setThickMaxAdj[b]
                    var cmx=setRootThickAdj[b]/30 // V1.91 per-set
                    var cmy=setTipThickAdj[b]/30 // V1.91 per-set
                    var _fadeInS2=clamp(setFadeInAdj[b],1,40)   // V1.91 per-set
                    var _fadeOutS2=clamp(setFadeOutAdj[b],1,40) // V1.91 per-set
                    var _padFactor=0.05+(padding/1000)
                    var _tMin=t_minScale*_padFactor
                    var _tMax=t_maxScale*_padFactor
                    var _tMax2=_tMax*2
                    var _lifeRcp=1/life

                    surface_set_target(previewSurf[b])
                    for(n=0;n<life;n+=optimalStep)
                        {
                        if root>n {rt=1-(clamp((n*(3800/life))/root,0,1))} else rt=0.01
                        if life-tip>n {tp=1-(clamp(abs((life-tip-n))/(tip*(life/3800)),0,1))} else tp=1
                        a=1 // V1.94 - see the first point loop

                        // Thickness — LUT
                        var _li90  = round(n*_lifeRcp*360) mod 1440
                        var _li180 = round(n*_lifeRcp*720) mod 1440
                        sc=clamp(n/scaleIn*(clamp((life-n)/scaleOut,0,100)),_tMin,_tMax)
                        var scx=lerp(_tMin,_tMax2,lut_sin[_li90])
                        var scy=lerp(_tMin,_tMax2,lut_cos[_li90])
                        var scz=lerp(_tMin,_tMax, lut_sin[_li180])
                        var tA=lerp(scx,scz,cmx)
                        var tB=lerp(scy,scz,cmy)
                        var scA=(clamp((tA+tB)*thicknessBase,0.15,100)/2) // V1.92 - same order as doMainStep

                        dpthAdd=preRandDepthAdd[b,v]

                        // Alpha fade - V1.91 per-set (clamped before the loop)
                        if (n>life-((_fadeOutS2/40)*(life/2))) {a=clamp((life-n)/((_fadeOutS2/40)*(life/2)),0,1)}
                        if (n<((_fadeInS2/40)*(life/2))+1)     {a=clamp(n/((_fadeInS2/40)*(life/2)),0,1)}

                        // Wave — LUT with amp inside angle
                        var _liDev  = round(n*freq*4)     mod 1440
                        var _liWave = round(n*freq*amp*4) mod 1440
                        deviationFromX = lut_sin[_liDev]
                        nx = xx + (lut_sin[_liWave] * (yy/100))

                        var xA=lerp(0,path_get_x(editingPath[0],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj1[b]*100))),strandSetMixerAdj1[b])
                        var xB=lerp(0,path_get_x(editingPath[1],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj2[b]*100))),strandSetMixerAdj2[b])
                        var xC=lerp(0,path_get_x(editingPath[2],(n-lifeVariant)/(4096+(strandSetMixerOffsetAdj3[b]*100))),strandSetMixerAdj3[b])
                        var tempX=(lerp(lerp(xA,xB,0.5),xC,0.5)/lifeVariant)*8
                        straggleXX=lerp(xx+tempX,setXpos,(n/3000)*(strandSetTaperAdj[b]*0.01))
                        var algFinalX=lerp((lerp(xx,nx,(strandSetWavynessAdj[b]*0.01)*ampFactor)),straggleXX,0.5+((lifeVariant-50)/100))
                        var algTaper=lerp(algFinalX,setXpos,(n/life)*(clamp(strandSetTaperAdj[b],1,strandSetTaperAdj[b])*0.01))

                        // V1.90 NOISE - gradual left/right deviation, root anchored.
                        var _nzOfsB=0
                        if noiseOn==1
                            {
                            var _m1=lut_sin[round(noiseP1+(n*noiseS1)) mod 1440]
                            var _m2=lut_sin[round(noiseP2+(n*noiseS2)) mod 1440]
                            var _m3=lut_sin[round(noiseP3+(n*noiseS3)) mod 1440]
                            _nzOfsB=((_m1*0.62)+(_m2*0.28)+(_m3*0.10))*noiseAmpS*(n/life)
                            }

                        finalX=algTaper+_nzOfsB
                        // Colour — this selected set's override values
                        var tempRv=lerp(color_get_red(setColVarA[b]),color_get_red(setColVarB[b]),clamp(dpth+dpthAdd,0,1))
                        var tempGv=lerp(color_get_green(setColVarA[b]),color_get_green(setColVarB[b]),clamp(dpth+dpthAdd,0,1))
                        var tempBv=lerp(color_get_blue(setColVarA[b]),color_get_blue(setColVarB[b]),clamp(dpth+dpthAdd,0,1))
                        var tempCol=make_color_rgb(tempRv,tempGv,tempBv)
                        var tempRr=lerp(color_get_red(tempCol),color_get_red(setRootCol[b]),rt)
                        var tempGr=lerp(color_get_green(tempCol),color_get_green(setRootCol[b]),rt)
                        var tempBr=lerp(color_get_blue(tempCol),color_get_blue(setRootCol[b]),rt)
                        tempCol=make_color_rgb(tempRr,tempGr,tempBr)
                        var tempRt=lerp(color_get_red(tempCol),color_get_red(setTipCol[b]),tp)
                        var tempGt=lerp(color_get_green(tempCol),color_get_green(setTipCol[b]),tp)
                        var tempBt=lerp(color_get_blue(tempCol),color_get_blue(setTipCol[b]),tp)
                        colrCustom=make_color_rgb(tempRt,tempGt,tempBt)

                        draw_set_color(colrCustom)
                        draw_set_alpha(clamp(1-power(1-clamp(a,0,1),max(1,previewAlphaK*scA)),0,1)) // V1.93 - see previewAlphaK

                        if set_active[setID]==0 and !generating
                            {
                            if finalX+xOffset[b]<4098 && yy+yOffset[b]<4070 and firstTime==0
                                {
                                draw_line_width((finalX+xOffset[b])*0.25,(yy+yOffset[b])*0.25,(finalX+xOffset[b])*0.25,(yy+yOffset[b])*0.25+(optimalStep*0.25),max(scA*previewWidthK,0.5))   // V1.92 - matches the final sprite footprint
                                if setHovveredID==b
                                    {
                                    if dsin(gameTick360*10*(60/fps))>=0 draw_set_color(c_white) else draw_set_color(c_black)
                                    }
                                if topmost==0       topmost=yy
                                if yy<topmost       topmost=yy
                                if yy>bottommost    bottommost=yy
                                if leftmost==0      leftmost=finalX
                                if finalX<leftmost  leftmost=finalX
                                if finalX>rightmost rightmost=finalX
                                }
                            }

                        draw_set_color(c_white)
                        draw_set_alpha(1)
                        yy+=optimalStep
                        } // end n loop
                    surface_reset_target()
                    } // end v loop
                }
            }
        } // end b loop

    previewCanvasComplete=1
	
    }
#endregion

if img==9 and setSelected!=-1 doHighlighting()



} // end function