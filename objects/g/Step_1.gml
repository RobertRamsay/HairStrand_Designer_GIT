// =============================================================================
// g : Begin Step  -  save/autosave bookkeeping for obj_surfaceDweller
//
// Runs every frame, before any Key Press or Step event. Everything inside
// "with (obj_surfaceDweller)" reads and writes obj_surfaceDweller's variables,
// not g's. Three parts:
//
//   A. canDrawUI: once the splash is gone, make sure the main UI is drawn.
//
//   B. MANUAL SAVE LATCH: on the frame S is pressed, set
//      v185ManualSavePending and alarm[1]=2 so Alarm 1 appends the marker
//      blocks (V1.85 colours, V1.96 Clumping, V1.96 Set Extras) after the old
//      S-key saver has closed the file. See g KeyPress_83 for what each flag
//      means.
//
//   C. COLOUR-CHANGE AUTOSAVE: keeps a copy ("snapshot", the v185Snap*
//      variables) of the four global colours and, for sets 0-10, the four
//      per-set colours and their four override flags. Each frame it compares
//      the live values with the copy. Any difference = the user changed a
//      colour last frame: refresh the copy, set v185AutosavePending and
//      alarm[1]=2. Alarm 1 then calls doAutoSave().
//      The ordinary autosave fires on mouse release; this one fires on the
//      values themselves, so a colour change is saved no matter which event
//      handled the release first.
//
// WHY alarm[1]=2 AND NOT 1
//   Alarms count down after Begin Step in the same frame. 1 would fire this
//   frame, before the S-key event has written the file. 2 fires next frame.
//
// IF YOU ADD ANOTHER PER-SET COLOUR-LIKE VALUE that should autosave when it
// changes without a mouse release, it needs a snapshot variable in all four
// places: the first-time copy, the compare, the refresh (all below), and the
// re-sync at the end of the load section of obj_surfaceDweller Alarm_1.
// =============================================================================
// Begin Step runs before the legacy Key Press events.
// Latch manual Save before KeyPress_83 forcibly releases S, debounce autosave
// from the real per-set colour state, and keep the normal UI visible after intro.

if instance_exists(obj_surfaceDweller)
    {
    with (obj_surfaceDweller)
        {
        // The splash screen owns the autoload decision from V1.90 onward:
        // LOAD AUTOSAVE leaves autoloading==1 so doMainStep performs the load,
        // GET STARTED clears it. Do not call doAutoLoad() directly here.
        if firstTime==false canDrawUI=1

        // Manual project Save is handled by the old S-key event later this frame.
        // Make the format boundary explicit before that event writes the header,
        // then let Alarm 1 append the authoritative colour block next frame.
        if keyboard_check_pressed(ord("S")) and canSave and demoMode==0
            {
            mainS="Hair Strand Designer - Project File - Version1.96.0 - 9thNov2026 (C) Robert Ramsay"
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
            // First frame after the colour arrays exist: just take the copy,
            // nothing to compare against yet. (Inside the "with", id is
            // obj_surfaceDweller, so these variables are created on it.)
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
                // While any save or load is in flight the compare is skipped, so
                // values changing as a file is read do not count as user edits.
                // (Alarm 1 re-syncs the snapshot itself at the end of a load.)
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

                    // Refresh the copy straight away so one edit schedules one
                    // autosave, not one per frame. While a colour is being dragged
                    // this re-arms alarm[1]=2 every frame the value moves; Alarm 1
                    // itself waits until no other save/load is running.
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
