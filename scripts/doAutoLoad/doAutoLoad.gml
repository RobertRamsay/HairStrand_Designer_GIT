// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

// =============================================================================
// doAutoLoad()  -  read Autosave.txt back into obj_surfaceDweller
//
// WHAT IT IS
//   The mirror image of doAutoSave(). Runs in obj_surfaceDweller's scope and
//   assigns its settings directly. The file is
//   %LOCALAPPDATA%\HairStrand_Designer\Autosave.txt.
//
// WHEN IT RUNS
//   Only from doMainStep, once, at start-up: when the user pressed LOAD
//   AUTOSAVE on the splash (autoloading is still 1), or when the splash is
//   skipped (skipIntro). doMainStep checks the file exists first. The manual
//   L-key loader (KeyPress_76) is a separate, older copy of this code that
//   opens a file dialog instead.
//
// HOW THE FILE IS READ
//   BY LINE POSITION. Each "tString=...read_string; readln; x=analise(tString)"
//   takes the NEXT line of the file, whatever its label says. So the order of
//   reads here must be exactly the order of writes in doAutoSave(). If a
//   loaded project has values in the wrong sliders, a read and a write are out
//   of step: compare the two functions line by line from the top.
//   See the header of doAutoSave for the full list of lines.
//
//   analise(line)        -> number after the colon
//   analiseString(line)  -> text after the colon with the final ";" removed
//
//   Newer sections are guarded by the version number in the header line,
//   real(string_copy(mainS,46,4)), plus !file_text_eof, so older and shorter
//   files stop cleanly and keep defaults for whatever they do not have.
//
// WHAT IS NOT READ HERE (done one frame later by obj_surfaceDweller Alarm 1)
//   clearOverrides(), called below while loading==true, sets
//   v185LoadRecoveryPending and alarm[1]. Alarm 1 then re-opens the file and
//   finds these blocks by their MARKER LINE, not by position:
//     "V1.85 - Per Set Colour Overrides"  (read again; that copy is the one that counts)
//     "V1.96 - Clumping"                  (clumpReadFile)
//     "V1.96 - Set Extras"                (extrasReadFile; not in an autosave)
//
// ORDER THAT MATTERS
//   1. clearOverrides() first: resets every per-set flag/value so nothing
//      from the previous project survives.
//   2. the positional read.
//   3. after the file is closed: the mixer path points are pushed into the
//      real paths, and the random tables are rebuilt from the loaded seeds.
//   4. next frame: Alarm 1 (colours, clumping, extras).
//
// ADDING A NEW SAVED VALUE: see "ADDING A NEW SAVED VALUE" in doAutoSave.
// =============================================================================
function doAutoLoad(){

img=9 // 9 = the Previewer; a load always returns to the live preview

// No set is selected after a load (12 covers set slots 0-11).
for (nC=0;nC<12;nC++)
    {
    setSelected[nC]=0
    setSelectedID=-1
    }

if canLoad
    {
    fileCustom = "Autosave.txt";
    if fileCustom!="" theFile = file_text_open_read(fileCustom);

    // file_text_open_read returns -1 (not "") when it fails, so this test does
    // not catch a missing file. doMainStep checks the file exists before calling.
    if theFile != "" and fileCustom!=""
        {
        loading=true // makes clearOverrides() schedule the Alarm 1 recovery pass
        clearOverrides()
        lastFileName=fileCustom // Alarm 1 re-opens this path for the marker blocks

        // Line 1: header. mainS is used below for every version check.
        // Line 2: the instruction line, kept only so it can be written back.
        mainS=file_text_read_string(theFile); file_text_readln(theFile);
        instr=file_text_read_string(theFile); file_text_readln(theFile);

        // The ten reads below with a commented-out assignment (doRGB ... img)
        // still have to happen: each one steps past a line the saver wrote.
        // The map tick boxes and the viewed map are deliberately not restored.
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

        // Five colours stored as RRGGBB hex text (dec_to_hex_save): characters
        // 1-2 red, 3-4 green, 5-6 blue. A short string (trailing zero bytes are
        // not written) reads the missing pairs as 0, which is correct.
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
        setColourOverridesReady=1 // tells Step_0 and objects/g the colour arrays exist

        // Whichever colour slot is open in the picker shows the loaded value.
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

        tString=file_text_read_string(theFile); file_text_readln(theFile); maxPreviewStrandsPerSet=min(analise(tString),100) // V1.94 - the strand*/preRand* caches hold 100
        tString=file_text_read_string(theFile); file_text_readln(theFile); optimalStep=analise(tString)

        // If either value came back 0, fall back to working defaults.
        if maxPreviewStrandsPerSet==0 or optimalStep==0
            {
            maxPreviewStrandsPerSet=8
            optimalStep=64
            }

        // *_GenState: 0 = map off, 1 = ticked but needs generating, 2 = generated.
        // The do* flags were NOT loaded (see above), so this just drops every
        // currently ticked map back to "needs generating" for the new project.
        ao_GenState=doAO; color_GenState=doColor; depth_GenState=doDepth
        flow_GenState=doFlow; frizz_GenState=doFrizz; id_GenState=doID
        mask_GenState=doMask; norm_GenState=doNorm; rgbMask_GenState=doRGB
        pleaseGen=true

        // V1.36 - path points
        // The three mixer curves, 11 points each. They are parked in pathLoadA/B/C
        // and only pushed into the real paths at the bottom of this function.
        // string_copy(mainS,46,4) is the "1.96" in the header line.
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
        // Everything from here to the end of the positional format sits inside
        // this "if". If the marker line is not exactly this text (for example
        // the reads above have drifted by a line) none of the per-set data,
        // noise or per-set seeds load, and no error is shown.
        // 26 lines per set, same order as doAutoSave.
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
            // The label line is consumed whether or not it matches, so a file
            // without this section would lose one line here. Every autosave
            // this build can write has it.
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
            // Alarm 1 reads this same block again next frame by searching for the
            // marker; this read mainly keeps the line position right for the
            // V1.90 and V1.91 sections that follow it.
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

            // V1.90 - global NOISE amount + frequency. Written at the very end
            // of the file, so a project saved before this feature existed simply
            // hits EOF here and keeps the Create-event defaults.
            // The short-lived V1.86 block is still accepted: it held a single
            // 0-100 amount, which is rescaled to the 0-40 dual-slider range.
            noiseAmt=0
            noiseFreq=10
            if real(string_copy(mainS,46,4)) >= 1.86 and !file_text_eof(theFile)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile);

                if tString=="V1.90 - Noise"
                    {
                    if !file_text_eof(theFile)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); noiseAmt=real(analiseString(tString));
                        }
                    if !file_text_eof(theFile)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); noiseFreq=real(analiseString(tString));
                        }
                    }

                if tString=="V1.86 - Noise"
                    {
                    if !file_text_eof(theFile)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); noiseAmt=real(analiseString(tString))*0.4;
                        }
                    noiseFreq=10
                    }
                }
            // 40 is the top of both noise sliders. The text boxes hold their own
            // copy of the value as a string, so refresh those too.
            noiseAmt=clamp(noiseAmt,0,40)
            noiseFreq=clamp(noiseFreq,0,40)
            textBox_noiseAmt_value=string(noiseAmt)
            textBox_noiseFreq_value=string(noiseFreq)

            // V1.91 - per-set thickness / fade / noise overrides.
            // Seed every set from the globals first, so a pre-1.91 project keeps
            // rendering exactly as it did, then overwrite from the file if the
            // block is present.
            for (var _seedSet=0;_seedSet<maxSets;_seedSet++)
                {
                setTipThickOverrode[_seedSet]=0
                setRootThickOverrode[_seedSet]=0
                setThickVaryOverrode[_seedSet]=0
                setFadeInOverrode[_seedSet]=0
                setFadeOutOverrode[_seedSet]=0
                setNoiseAmtOverrode[_seedSet]=0
                setNoiseFreqOverrode[_seedSet]=0
                setTipThickAdj[_seedSet]=tipThick
                setRootThickAdj[_seedSet]=rootThick
                setThickVaryAdj[_seedSet]=thickVary
                setFadeInAdj[_seedSet]=fadeIn
                setFadeOutAdj[_seedSet]=fadeOut
                setNoiseAmtAdj[_seedSet]=noiseAmt
                setNoiseFreqAdj[_seedSet]=noiseFreq
                }

            // A pre-1.71 project carries no per-set thickness range, so those two
            // arrays would otherwise keep the Create-event defaults while the
            // globals show the loaded values.
            if real(string_copy(mainS,46,4)) < 1.71
                {
                for (var _oldThickSet=0;_oldThickSet<maxSets;_oldThickSet++)
                    {
                    setThickMinAdj[_oldThickSet]=minScale
                    setThickMaxAdj[_oldThickSet]=maxScale
                    }
                }

            if real(string_copy(mainS,46,4)) >= 1.91 and !file_text_eof(theFile)
                {
                tString=file_text_read_string(theFile); file_text_readln(theFile);
                if tString=="V1.91 - Per Set Thickness Fade Noise"
                    {
                    for (set=0;set<11;set++)
                        {
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setTipThickOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setTipThickAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setRootThickOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setRootThickAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setThickVaryOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setThickVaryAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setFadeInOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setFadeInAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setFadeOutOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setFadeOutAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setNoiseAmtOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setNoiseAmtAdj[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setNoiseFreqOverrode[set]=real(analiseString(tString));
                        tString=file_text_read_string(theFile); file_text_readln(theFile); setNoiseFreqAdj[set]=real(analiseString(tString));
                        }
                    }
                }
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

        // The clump block that follows in the file is not read here. Alarm 1
        // re-opens the file next frame (clumpReadFile / extrasReadFile).
        file_text_close(theFile);
        }
    else
        {
        keyboard_key_release(vk_enter)
        loading=false
        projectOnly=false
        }
    }

// loading goes false here, but v185LoadRecoveryPending (set by clearOverrides)
// stays 1 until Alarm 1 has run, and objects/g holds off its colour-change
// autosave until then.
keyboard_key_release(ord("L"))
loading=false
projectOnly=false
canLoad=true
//img=9

// Restore path points
// Runs even if no file was read; pathLoad* then still hold the values Create
// took from the default paths (or the last load). The 100 is the path point's
// speed value, the same as every other point in these paths.
for (a=0;a<11;a++)
    {
    path_change_point(editingPath[0],a,pathLoadAx[a],pathLoadAy[a],100)
    path_change_point(editingPath[1],a,pathLoadBx[a],pathLoadBy[a],100)
    path_change_point(editingPath[2],a,pathLoadCx[a],pathLoadCy[a],100)
    }

// Rebuild pre-rands with loaded seeds, in obj_surfaceDweller scope
// (the caller already is obj_surfaceDweller, so the "other." copies below copy
// each value onto itself; they would only matter if another object called this)
// updatePreRands(-1) rebuilds the random tables for all 11 sets, each from its
// own randomSeedVal, so this has to come after the seeds have been loaded.
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