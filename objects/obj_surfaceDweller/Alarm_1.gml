/// @description V1.85 per-set colour persistence

var _manualSaveDone=0

// -----------------------------------------------------------------------------
// MANUAL SAVE
// The legacy S-key saver has finished and closed the chosen project file by the
// time this alarm runs. Append one authoritative, self-contained V1.85 block.
// -----------------------------------------------------------------------------
if variable_instance_exists(id,"v185ManualSavePending") and v185ManualSavePending==1
    {
    v185ManualSavePending=0

    // Prefer the path captured at the start of End Step. The file-dialog mouse
    // release may already have caused doAutoSave() to change fileCustom.
    var _manualPath=""
    if variable_instance_exists(id,"v185ManualSavePath") and v185ManualSavePath!="" and file_exists(v185ManualSavePath)
        _manualPath=v185ManualSavePath
    else if fileCustom!="" and fileCustom!="Autosave.txt" and file_exists(fileCustom)
        _manualPath=fileCustom

    if _manualPath!=""
        {
        var _saveFile=file_text_open_append(_manualPath)
        if _saveFile!=-1
            {
            file_text_write_string(_saveFile,"V1.85 - Per Set Colour Overrides")
            file_text_writeln(_saveFile)

            // Store true globals here because custom* can be exposing a selected set.
            file_text_write_string(_saveFile,"globalColVarA:"+string(globalColVarA)+";")
            file_text_writeln(_saveFile)
            file_text_write_string(_saveFile,"globalColVarB:"+string(globalColVarB)+";")
            file_text_writeln(_saveFile)
            file_text_write_string(_saveFile,"globalRootCol:"+string(globalRootCol)+";")
            file_text_writeln(_saveFile)
            file_text_write_string(_saveFile,"globalTipCol:"+string(globalTipCol)+";")
            file_text_writeln(_saveFile)

            for (var _saveSet=0;_saveSet<11;_saveSet++)
                {
                file_text_write_string(_saveFile,"setColVarAOverrode["+string(_saveSet)+"]:"+string(setColVarAOverrode[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setColVarA["+string(_saveSet)+"]:"+string(setColVarA[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setColVarBOverrode["+string(_saveSet)+"]:"+string(setColVarBOverrode[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setColVarB["+string(_saveSet)+"]:"+string(setColVarB[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setRootColOverrode["+string(_saveSet)+"]:"+string(setRootColOverrode[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setRootCol["+string(_saveSet)+"]:"+string(setRootCol[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setTipColOverrode["+string(_saveSet)+"]:"+string(setTipColOverrode[_saveSet])+";")
                file_text_writeln(_saveFile)
                file_text_write_string(_saveFile,"setTipCol["+string(_saveSet)+"]:"+string(setTipCol[_saveSet])+";")
                file_text_writeln(_saveFile)
                }

            file_text_close(_saveFile)
            _manualSaveDone=1
            }
        }

    v185ManualSavePath=""
    }

// -----------------------------------------------------------------------------
// MANUAL LOAD + AUTOLOAD
// clearOverrides() schedules this recovery whenever loading=true. Re-open the
// completed file and restore the V1.85 block independently of the legacy parser.
// Project format 1.85 is the minimum allowed to own per-set colour data.
// -----------------------------------------------------------------------------
if variable_instance_exists(id,"v185LoadRecoveryPending") and v185LoadRecoveryPending==1
    {
    v185LoadRecoveryPending=0

    var _loadPath=""
    if lastFileName!="" and file_exists(lastFileName)
        _loadPath=lastFileName
    else if fileCustom!="" and file_exists(fileCustom)
        _loadPath=fileCustom

    var _loadedVersion=0
    var _foundColourBlock=0

    if _loadPath!=""
        {
        var _readFile=file_text_open_read(_loadPath)
        if _readFile!=-1
            {
            // Read the compatibility version from the file itself, never mainS.
            var _header=""
            if !file_text_eof(_readFile)
                {
                _header=file_text_read_string(_readFile)
                file_text_readln(_readFile)
                }

            var _versionPos=string_pos("Version",_header)
            if _versionPos>0 _loadedVersion=real(string_copy(_header,_versionPos+7,4))

            if _loadedVersion>=1.85
                {
                var _line=""

                while !file_text_eof(_readFile) and _foundColourBlock==0
                    {
                    _line=file_text_read_string(_readFile)
                    file_text_readln(_readFile)
                    if _line=="V1.85 - Per Set Colour Overrides" _foundColourBlock=1
                    }

                if _foundColourBlock==1 and !file_text_eof(_readFile)
                    {
                    // Manual 1.85 saves contain four globals immediately after the
                    // marker. Existing 1.85 autosaves start directly with set 0.
                    // Accept both layouts so current Autosave.txt files remain valid.
                    _line=file_text_read_string(_readFile)
                    file_text_readln(_readFile)

                    var _firstSet=0
                    if string_pos("globalColVarA:",_line)==1
                        {
                        globalColVarA=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); globalColVarB=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); globalRootCol=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); globalTipCol=real(analiseString(_line))
                        }
                    else
                        {
                        // Autosave layout: global colours were restored from its normal
                        // colour fields; this first line is set 0's A override flag.
                        setColVarAOverrode[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarA[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarBOverrode[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarB[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setRootColOverrode[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setRootCol[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setTipColOverrode[0]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setTipCol[0]=real(analiseString(_line))
                        _firstSet=1
                        }

                    for (var _loadSet=_firstSet;_loadSet<11;_loadSet++)
                        {
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarAOverrode[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarA[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarBOverrode[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setColVarB[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setRootColOverrode[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setRootCol[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setTipColOverrode[_loadSet]=real(analiseString(_line))
                        _line=file_text_read_string(_readFile); file_text_readln(_readFile); setTipCol[_loadSet]=real(analiseString(_line))
                        }
                    }
                }

            file_text_close(_readFile)
            }
        }

    // Pre-1.85, or a malformed/missing 1.85 block: legacy colours are global.
    if _foundColourBlock==0
        {
        globalColVarA=customColVarA
        globalColVarB=customColVarB
        globalRootCol=customRootCol
        globalTipCol=customTipCol

        for (var _legacySet=0;_legacySet<maxSets;_legacySet++)
            {
            setColVarA[_legacySet]=globalColVarA
            setColVarB[_legacySet]=globalColVarB
            setRootCol[_legacySet]=globalRootCol
            setTipCol[_legacySet]=globalTipCol
            setColVarAOverrode[_legacySet]=0
            setColVarBOverrode[_legacySet]=0
            setRootColOverrode[_legacySet]=0
            setTipColOverrode[_legacySet]=0
            }
        }

    // Keep unused set slots sane while preserving loaded 0..10.
    for (var _extraSet=11;_extraSet<maxSets;_extraSet++)
        {
        setColVarA[_extraSet]=globalColVarA
        setColVarB[_extraSet]=globalColVarB
        setRootCol[_extraSet]=globalRootCol
        setTipCol[_extraSet]=globalTipCol
        setColVarAOverrode[_extraSet]=0
        setColVarBOverrode[_extraSet]=0
        setRootColOverrode[_extraSet]=0
        setTipColOverrode[_extraSet]=0
        }

    // Loads return to global editing. Per-set arrays stay authoritative and are
    // exposed by Step_0 when the user selects each set.
    setColourOverridesReady=1
    customColVarA=globalColVarA
    customColVarB=globalColVarB
    customRootCol=globalRootCol
    customTipCol=globalTipCol
    colourUiLastA=customColVarA
    colourUiLastB=customColVarB
    colourUiLastRoot=customRootCol
    colourUiLastTip=customTipCol
    colourUiLastSet=setSelectedID

    if variable_instance_exists(id,"colourSelectedSlot")
        {
        if colourSelectedSlot==0 colourSelectedStoreColor=colrBack
        if colourSelectedSlot==1 colourSelectedStoreColor=customColVarA
        if colourSelectedSlot==2 colourSelectedStoreColor=customColVarB
        if colourSelectedSlot==3 colourSelectedStoreColor=customRootCol
        if colourSelectedSlot==4 colourSelectedStoreColor=customTipCol
        }

    if bkCol_active==1   newColor=colrBack
    if ColA_active==1    newColor=customColVarA
    if ColB_active==1    newColor=customColVarB
    if RootCol_active==1 newColor=customRootCol
    if TipCol_active==1  newColor=customTipCol

    colorOnlyUpdate=1
    previewCanvasComplete=0
    forceUpdate=1
    pleaseGen=true

    // This running build always saves the current project format afterwards.
    mainS="Hair Strand Designer - Project File - Version1.95.0 - 26thAug2026 (C) Robert Ramsay"

    // Synchronise the Begin-Step snapshot so the restore itself does not cause
    // an unnecessary autosave on the following frame.
    v185SnapGlobalA=globalColVarA
    v185SnapGlobalB=globalColVarB
    v185SnapGlobalRoot=globalRootCol
    v185SnapGlobalTip=globalTipCol
    for (var _snapSet=0;_snapSet<11;_snapSet++)
        {
        v185SnapA[_snapSet]=setColVarA[_snapSet]
        v185SnapB[_snapSet]=setColVarB[_snapSet]
        v185SnapRoot[_snapSet]=setRootCol[_snapSet]
        v185SnapTip[_snapSet]=setTipCol[_snapSet]
        v185SnapAOver[_snapSet]=setColVarAOverrode[_snapSet]
        v185SnapBOver[_snapSet]=setColVarBOverrode[_snapSet]
        v185SnapRootOver[_snapSet]=setRootColOverrode[_snapSet]
        v185SnapTipOver[_snapSet]=setTipColOverrode[_snapSet]
        }
    v185ColourSnapshotReady=1
    v185AutosavePending=0
    }

// -----------------------------------------------------------------------------
// DEBOUNCED AUTOSAVE
// The Begin Step snapshot notices real model changes one frame after Step_0 has
// committed them. Saving here therefore writes the actual per-set arrays/flags.
// -----------------------------------------------------------------------------
if variable_instance_exists(id,"v185AutosavePending") and v185AutosavePending==1
    {
    if autosave==1 and demoMode==0 and !loading and !saving and !autosaving
        {
        v185AutosavePending=0
        doAutoSave()
        }
    }

// Keep Autosave.txt current after a successful manual project save as well.
if _manualSaveDone==1 and autosave==1 and demoMode==0 and !loading and !autosaving
    {
    doAutoSave()
    }
