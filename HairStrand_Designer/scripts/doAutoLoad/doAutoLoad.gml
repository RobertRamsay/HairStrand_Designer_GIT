// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function doAutoLoad(){

img=9

for (nC=0;nC<12;nC++)
    {
    setSelected[nC]=0
    setSelectedID=-1
    }

if canLoad
    {
    fileCustom = "Autosave.txt";
    if fileCustom!="" theFile = file_text_open_read(fileCustom);

    if theFile != "" and fileCustom!=""
        {
        loading=true
        clearOverrides()
        lastFileName=fileCustom

        mainS=file_text_read_string(theFile); file_text_readln(theFile);
        instr=file_text_read_string(theFile); file_text_readln(theFile);

        #region VARIABLES TO LOAD
        var tString="";

        tString=file_text_read_string(theFile); file_text_readln(theFile); seedVal=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); var_blur_amount=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); idMode=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doRGB=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doNorm=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doColor=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doMask=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doID=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doDepth=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doFrizz=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doFlow=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //doAO=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); //img=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); dirFlipX=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); dirFlipY=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); dirBlue=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); dirHue=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); scaleIn=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); scaleOut=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); fadeIn=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); fadeOut=analise(tString)

        tString=file_text_read_string(theFile); file_text_readln(theFile); tString=analiseString(tString);
        colrBack=make_color_rgb(hex_to_dec(string_copy(tString,1,2)),hex_to_dec(string_copy(tString,3,2)),hex_to_dec(string_copy(tString,5,2)));

        tString=file_text_read_string(theFile); file_text_readln(theFile); tString=analiseString(tString);
        customColVarA=make_color_rgb(hex_to_dec(string_copy(tString,1,2)),hex_to_dec(string_copy(tString,3,2)),hex_to_dec(string_copy(tString,5,2)));

        tString=file_text_read_string(theFile); file_text_readln(theFile); tString=analiseString(tString);
        customColVarB=make_color_rgb(hex_to_dec(string_copy(tString,1,2)),hex_to_dec(string_copy(tString,3,2)),hex_to_dec(string_copy(tString,5,2)));

        tString=file_text_read_string(theFile); file_text_readln(theFile); tString=analiseString(tString);
        customRootCol=make_color_rgb(hex_to_dec(string_copy(tString,1,2)),hex_to_dec(string_copy(tString,3,2)),hex_to_dec(string_copy(tString,5,2)));

        tString=file_text_read_string(theFile); file_text_readln(theFile); tString=analiseString(tString);
        customTipCol=make_color_rgb(hex_to_dec(string_copy(tString,1,2)),hex_to_dec(string_copy(tString,3,2)),hex_to_dec(string_copy(tString,5,2)));

        // These are the legacy/global colours. Initialise every set from them;
        // only a 1.85+ project may replace individual values from the optional
        // per-set colour block later in the file.
        globalColVarA=customColVarA
        globalColVarB=customColVarB
        globalRootCol=customRootCol
        globalTipCol=customTipCol
        for (var _colourLoadSet=0;_colourLoadSet<maxSets;_colourLoadSet++)
            {
            setColVarA[_colourLoadSet]=globalColVarA
            setColVarB[_colourLoadSet]=globalColVarB
            setRootCol[_colourLoadSet]=globalRootCol
            setTipCol[_colourLoadSet]=globalTipCol
            setColVarAOverrode[_colourLoadSet]=0
            setColVarBOverrode[_colourLoadSet]=0
            setRootColOverrode[_colourLoadSet]=0
            setTipColOverrode[_colourLoadSet]=0
            }
        setColourOverridesReady=1

        if bkCol_active==1   newColor=colrBack
        if ColA_active==1    newColor=customColVarA
        if ColB_active==1    newColor=customColVarB
        if RootCol_active==1 newColor=customRootCol
        if TipCol_active==1  newColor=customTipCol

        for (s=0;s<11;s++)
            {
            tString=file_text_read_string(theFile); file_text_readln(theFile); strandCountOverride[s]=analise(tString)
            tString=file_text_read_string(theFile); file_text_readln(theFile); strandLengthOverride[s]=analise(tString)
            }

        tString=file_text_read_string(theFile); file_text_readln(theFile); minScale=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); maxScale=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); colorMode=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); tapering=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); root=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); tip=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); lifeVariant=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); rootPosition=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); tipPosition=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); wavyness=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); strands=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); diminish=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); maxStrands=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); distancings=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); setDistance=analise(tString)

        for (s=0;s<11;s++)
            {
            tString=file_text_read_string(theFile); file_text_readln(theFile); xOffset[s]=analise(tString)
            tString=file_text_read_string(theFile); file_text_readln(theFile); yOffset[s]=analise(tString)
            tString=file_text_read_string(theFile); file_text_readln(theFile); alogrithmInfluence[s]=analise(tString)
            }

        tString=file_text_read_string(theFile); file_text_readln(theFile); minFreq=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); maxFreq=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); frizz=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer1=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer1_offset=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer2=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer2_offset=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer3=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); mixer3_offset=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); rootThick=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); tipThick=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); thickVary=analise(tString)

        for (s=0;s<11;s++)
            {
            tString=file_text_read_string(theFile); file_text_readln(theFile); taperInfluence[s]=analise(tString)
            }

        tString=file_text_read_string(theFile); file_text_readln(theFile); maxPreviewStrandsPerSet=analise(tString)
        tString=file_text_read_string(theFile); file_text_readln(theFile); optimalStep=analise(tString)

        if maxPreviewStrandsPerSet==0 or optimalStep==0
            {
            maxPreviewStrandsPerSet=8
            optimalStep=64
            }

        ao_GenState=doAO; color_GenState=doColor; depth_GenState=doDepth
        flow_GenState=doFlow; frizz_GenState=doFrizz; id_GenState=doID
        mask_GenState=doMask; norm_GenState=doNorm; rgbMask_GenState=doRGB
        pleaseGen=true

        // V1.36 - path points
        if real(string_copy(mainS,46,4))>=1.36
            {
            for (z1=0;z1<11;z1++)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadAx[z1]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadAy[z1]=real(analiseString(tString));
                }
            for (z2=0;z2<11;z2++)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadBx[z2]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadBy[z2]=real(analiseString(tString));
                }
            for (z3=0;z3<11;z3++)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadCx[z3]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); pathLoadCy[z3]=real(analiseString(tString));
                }
            }

        // V1.5+ override block
        tString=file_text_read_string(theFile); file_text_readln(theFile);
        if tString="***VERSION 1.5 and later specific;"
            {
            for (b=0;b<11;b++)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); setLengthOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setCountOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setTaperOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setWaveynessOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setWaveFreqMinOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setWaveFreqMaxOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setVariOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setSpacingOverrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerAmt1Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerOfs1Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerAmt2Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerOfs2Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerAmt3Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); setMixerOfs3Overrode[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerAdj1[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerAdj2[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerAdj3[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerOffsetAdj1[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerOffsetAdj2[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetMixerOffsetAdj3[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetTaperAdj[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetWavynessAdj[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetWaveFreqMinAdj[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetWaveFreqMaxAdj[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetVariAdj[b]=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); strandSetSpaceAdj[b]=real(analiseString(tString));
                }

            tString=file_text_read_string(theFile); file_text_readln(theFile); length=real(analiseString(tString));

            // V1.53
            tString=file_text_read_string(theFile); file_text_readln(theFile);
            if tString=="V1.53 - 21st Nov 2020"
                {
                for (set=0;set<11;set++)
                    {
                    tString=file_text_read_string(theFile); file_text_readln(theFile); strandYRanRange[set]=real(analiseString(tString));
                    tString=file_text_read_string(theFile); file_text_readln(theFile); strandYRanRangeOverrode[set]=real(analiseString(tString));
                    }
                tString=file_text_read_string(theFile); file_text_readln(theFile); yRanRange=real(analiseString(tString));
                }

            // V1.55
            tString=file_text_read_string(theFile); file_text_readln(theFile);
            if tString=="V1.55 - 28th Dec 2020"
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); moreHairs=real(analiseString(tString));
                tString=file_text_read_string(theFile); file_text_readln(theFile); curlRotAmt=real(analiseString(tString));
                }

            // V1.70 - per-set random seeds (unconditional by version number)
            if real(string_copy(mainS,46,4)) >= 1.70
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); // consume "V1.70..." label
                for (set=0;set<11;set++)
                    {
                    tString=file_text_read_string(theFile); file_text_readln(theFile); randomOverride[set]=real(analiseString(tString));
                    tString=file_text_read_string(theFile); file_text_readln(theFile); randomSeedVal[set]=real(analiseString(tString));
                    }
                }

            // V1.71 - per-set thickness overrides (unconditional by version number)
            if real(string_copy(mainS,46,4)) >= 1.71
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile); // consume "V1.71..." label
                for (set=0;set<11;set++)
                    {
                    tString=file_text_read_string(theFile); file_text_readln(theFile); setThickMinOverrode[set]=real(analiseString(tString));
                    tString=file_text_read_string(theFile); file_text_readln(theFile); setThickMinAdj[set]=real(analiseString(tString));
                    tString=file_text_read_string(theFile); file_text_readln(theFile); setThickMaxOverrode[set]=real(analiseString(tString));
                    tString=file_text_read_string(theFile); file_text_readln(theFile); setThickMaxAdj[set]=real(analiseString(tString));
                    }
                }

            // V1.85 - per-set colour overrides. This data did not exist before
            // project format 1.85, so both the header and section label must match.
            if real(string_copy(mainS,46,4)) >= 1.85 and !file_text_eof(theFile)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile);
                if tString=="V1.85 - Per Set Colour Overrides"
                    {
                    for (set=0;set<11;set++)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setColVarAOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setColVarA[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setColVarBOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setColVarB[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setRootColOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setRootCol[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setTipColOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setTipCol[set]=real(analiseString(tString));
                        }
                    }
                }

            // V1.86 - global NOISE amount. Written at the very end of the file,
            // so a 1.86 project saved before this feature existed simply hits
            // EOF here and keeps the Create-event default of 0.
            noiseAmt=0
            if real(string_copy(mainS,46,4)) >= 1.86 and !file_text_eof(theFile)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile);
                if tString=="V1.86 - Noise"
                    {
                    if !file_text_eof(theFile)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); noiseAmt=real(analiseString(tString));
                        }
                    }
                }
            noiseAmt=clamp(noiseAmt,0,100)
            textBox_noiseAmt_value=string(noiseAmt)
            }

        // Loading always returns to global editing, so expose the loaded globals
        // to the existing picker and synchronisation code.
        customColVarA=globalColVarA
        customColVarB=globalColVarB
        customRootCol=globalRootCol
        customTipCol=globalTipCol
        colourUiLastA=customColVarA
        colourUiLastB=customColVarB
        colourUiLastRoot=customRootCol
        colourUiLastTip=customTipCol
        colourUiLastSet=setSelectedID
        if bkCol_active==1   newColor=colrBack
        if ColA_active==1    newColor=customColVarA
        if ColB_active==1    newColor=customColVarB
        if RootCol_active==1 newColor=customRootCol
        if TipCol_active==1  newColor=customTipCol

        #endregion

        file_text_close(theFile);
        }
    else
        {
        keyboard_key_release(vk_enter)
        loading=false
        projectOnly=false
        }
    }

keyboard_key_release(ord("L"))
loading=false
projectOnly=false
canLoad=true
//img=9

// Restore path points
for (a=0;a<11;a++)
    {
    path_change_point(editingPath[0],a,pathLoadAx[a],pathLoadAy[a],100)
    path_change_point(editingPath[1],a,pathLoadBx[a],pathLoadBy[a],100)
    path_change_point(editingPath[2],a,pathLoadCx[a],pathLoadCy[a],100)
    }

// Rebuild pre-rands with loaded seeds, in obj_surfaceDweller scope
with (obj_surfaceDweller)
    {
    for (var _s=0;_s<11;_s++)
        {
        randomSeedVal[_s]  = other.randomSeedVal[_s];
        randomOverride[_s] = other.randomOverride[_s];
        }
    seedVal = other.seedVal;
    random_set_seed(seedVal);    // ← stabilise global seed first
    updatePreRands(-1);          // ← now build pre-rands correctly
    previewCanvasComplete=0;
    forceUpdate=1;
    pleaseGen=true;
    }

}