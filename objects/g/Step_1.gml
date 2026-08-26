// Begin Step runs before the legacy Key Press events.
// Latch manual Save before KeyPress_83 forcibly releases S, debounce autosave
// from the real per-set colour state, and keep the normal UI visible after intro.

if instance_exists(obj_surfaceDweller)
    {
    with (obj_surfaceDweller)
        {
        // The original doMainStep() startup flow owns autoload prompting.
        // Leave readyToCheckAutoloads==1 intact after the splash so it can ask:
        // "An autosave has been detected, do you wish to load it?"
        // Do not call doAutoLoad() directly here.
        if firstTime==false canDrawUI=1

        // Manual project Save is handled by the old S-key event later this frame.
        // Make the format boundary explicit before that event writes the header,
        // then let Alarm 1 append the authoritative colour block next frame.
        if keyboard_check_pressed(ord("S")) and canSave and demoMode==0
            {
            mainS="Hair Strand Designer - Project File - Version1.90.0 - 26thAug2026 (C) Robert Ramsay"
            v185ManualSavePending=1
            v185ManualSavePath=""
            // Begin Step runs before Alarm processing, so use 2 to guarantee the
            // persistence alarm cannot run until after this frame's S-key event.
            alarm[1]=2
            }

        // Step_0 creates the colour model during the first normal Step. Begin Step
        // runs earlier, so do not touch those arrays until initialisation is done.
        if variable_instance_exists(id,"setColourOverridesReady")
            {
            // Keep a snapshot of the authoritative colour model. When Step_0 changes
            // a global/per-set colour or override flag, schedule one autosave shortly
            // after the values settle. This avoids depending on mouse-release order.
            if !variable_instance_exists(id,"v185ColourSnapshotReady")
                {
                v185SnapGlobalA=globalColVarA
                v185SnapGlobalB=globalColVarB
                v185SnapGlobalRoot=globalRootCol
                v185SnapGlobalTip=globalTipCol

                for (var _initSet=0;_initSet<11;_initSet++)
                    {
                    v185SnapA[_initSet]=setColVarA[_initSet]
                    v185SnapB[_initSet]=setColVarB[_initSet]
                    v185SnapRoot[_initSet]=setRootCol[_initSet]
                    v185SnapTip[_initSet]=setTipCol[_initSet]
                    v185SnapAOver[_initSet]=setColVarAOverrode[_initSet]
                    v185SnapBOver[_initSet]=setColVarBOverrode[_initSet]
                    v185SnapRootOver[_initSet]=setRootColOverrode[_initSet]
                    v185SnapTipOver[_initSet]=setTipColOverrode[_initSet]
                    }

                v185ColourSnapshotReady=1
                }
            else
                {
                // A project load owns Alarm 1 until its recovery pass has finished.
                var _ioBusy =
                    (variable_instance_exists(id,"v185LoadRecoveryPending") and v185LoadRecoveryPending==1)
                    or (variable_instance_exists(id,"v185ManualSavePending") and v185ManualSavePending==1)
                    or loading or saving or autosaving

                if !_ioBusy
                    {
                    var _colourStateChanged =
                        v185SnapGlobalA!=globalColVarA
                        or v185SnapGlobalB!=globalColVarB
                        or v185SnapGlobalRoot!=globalRootCol
                        or v185SnapGlobalTip!=globalTipCol

                    for (var _checkSet=0;_checkSet<11;_checkSet++)
                        {
                        if v185SnapA[_checkSet]!=setColVarA[_checkSet]
                            or v185SnapB[_checkSet]!=setColVarB[_checkSet]
                            or v185SnapRoot[_checkSet]!=setRootCol[_checkSet]
                            or v185SnapTip[_checkSet]!=setTipCol[_checkSet]
                            or v185SnapAOver[_checkSet]!=setColVarAOverrode[_checkSet]
                            or v185SnapBOver[_checkSet]!=setColVarBOverrode[_checkSet]
                            or v185SnapRootOver[_checkSet]!=setRootColOverrode[_checkSet]
                            or v185SnapTipOver[_checkSet]!=setTipColOverrode[_checkSet]
                            {
                            _colourStateChanged=1
                            }
                        }

                    if _colourStateChanged
                        {
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

                        if autosave==1 and demoMode==0
                            {
                            v185AutosavePending=1
                            alarm[1]=2
                            }
                        }
                    }
                }
            }
        }
    }
