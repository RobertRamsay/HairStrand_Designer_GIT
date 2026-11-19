// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

/// @description RENDERED STRANDS

// =============================================================================
// doMainStep - THE FINAL 4096x4096 MAP RENDERER (plus a few per-step chores)
//
// CALLED BY  obj_surfaceDweller End Step (Step_2), once every step, in that
//            object's scope. Step_2 swaps customColVarA/B, customRootCol and
//            customTipCol to the colours of set [renderF] just before the call
//            and restores them straight after, which is how the per-set colours
//            reach the Colour map pass below.
//
// A render is started elsewhere: the G key / Generate button in Draw_0 set
// doOnce=true, retrigger=true and create obj_wait. Nothing below the
// "MAIN GENERATION LOOP" banner runs unless doOnce is true AND retrigger is true
// AND at least one map's GenState is 1.
//
// GenState per map (rgbMask_, norm_, color_, mask_, id_, depth_, flow_, ao_,
// frizz_):  0 = off,  1 = enabled and waiting to be (re)drawn,  2 = drawn and up
// to date. The do* flags (doRGB, doNorm ...) are the tick boxes. A map is drawn
// only when its do* flag is set AND its GenState is 1.
//
// PIPELINE - ONE SET PER STEP. A render of N sets takes N steps; renderF is the
// set being drawn this step and survives between steps.
//
//   every step     canvasCheck, autoload, preRandsRefresh, autosave on mouse
//                  release, input chores, then alpha writes are switched OFF
//   render start   (renderF == 0 only) reset counters, seed, and fill every
//                  enabled map with its background colour
//   per set        f = renderF. Seed the stream, work out hairLength and the
//                  strand count, build the mixer cache and clump membership
//   per strand     h = 0..strandSet-1. Read every per-strand value from the
//                  pre-random tables (updatePreRands), set up thickness / fade /
//                  noise / clump constants
//   per point      PASS 1: n = 0..life-1, one point per pixel down the strand.
//                  Work out X, scale, alpha and colours, store them in the pt_*
//                  arrays. Nothing is drawn here.
//   per map        PASS 2: for each enabled map, set its surface as target once
//                  and draw one sprite per stored point.
//   progress       every 20 strands and at the end of the set, blit the map
//                  being drawn to the application surface with a progress bar
//   end of set     renderF++. If sets remain: retrigger=true and RETURN, leaving
//                  doOnce true so the next step carries on with the next set.
//   finish         (after the last set) blue overwash on the Flow map, every
//                  GenState 1 -> 2, canSave=true, renderF=0, doOnce=false.
//
// There is no blur in here. The blur (B key) and the height-to-normal conversion
// (shd_normal, Multi Strand mode) are applied later, in Draw_0 and in the export code.
//
// COORDINATES  Everything is in 4096x4096 map pixels. The preview draws the
//              same numbers multiplied by 0.25 onto 1024x1024 surfaces.
//
// MUST STAY IN STEP WITH
//   previewDrawStrands (previewJob) + doCalc - the preview runs the SAME strand
//       maths (per-strand set-up, thickness, wave, mixers, taper, noise, clump).
//       Change a formula here and the render stops matching the preview unless
//       the same change is made there. The preview steps n by 10/20/40 and
//       draws line dashes; this draws every point as a sprite.
//   updatePreRands - both sides read the same tables, [set, strand], 100
//       strands per set. That is why strandSet is capped at 100 here.
//   clumpPrepareSet / mixerCacheBuild (clumpTools) - shared helpers.
//
// GPU STATE LEFT BEHIND  (the usual cause of "my surface draws nothing")
//   gpu_set_colorwriteenable(true,true,true,FALSE) is set on EVERY step, render
//   or not, and is never switched back. From End Step onwards alpha writes are
//   off. Any code that draws to a surface and needs its alpha channel written
//   (the preview surfaces, anything new) must call
//   gpu_set_colorwriteenable(1,1,1,1) itself first - see previewDrawStrands.
//   Blend mode is left at bm_normal and draw colour at c_white.
//
// RANDOM STREAM  The render reads every per-strand value from the tables, so
//   the only live draw left is irandom() in the Frizz pass. See PER-SET SEED.
// =============================================================================
function doMainStep() {
    
    // Ensure all required surfaces are initialized
    // (recreates any 4096 canvas or preview surface the OS has thrown away)
    canvasCheck();

    // -------------------------------------------------------------------------
    // AUTOSAVE & LOADING LOGIC
    // -------------------------------------------------------------------------
    
    // The splash screen already asked. autoloading is only still 1 here if the
    // user pressed LOAD AUTOSAVE, so load straight away - no popup.
    if (autoloading == 1 && readyToCheckAutoloads == 1 && skipIntro == 0) {
        alFile = file_text_open_read("Autosave.txt");
        if (alFile != -1) {
            file_text_close(alFile);
            doAutoLoad();
        }
        autoloading = 0;
    }

    // Direct autoload if intro is skipped
    if (skipIntro == 1 && autoloading == 1) {
        alFile = file_text_open_read("Autosave.txt");
        if (alFile != -1) {
            doAutoLoad();
            autoloading = 0;
        }
        if (alFile != -1) file_text_close(alFile);
    }

    // Reset pointers for a fresh generation request
    // V1.96 - was updatePreRands(-1) on every step while pleaseGen was set.
    // The tables now rebuild only for a set whose inputs changed (previewJob).
    // NOTE: a rebuild calls random_set_seed, so it moves the global random
    // stream. The render re-seeds per set further down, so it does not care.
    preRandsRefresh();
    // pleaseGen = "settings changed since the last Generate". While it is set
    // the set pointer is held at 0, so the next Generate starts from set 0.
    if (pleaseGen == true) {
        renderF = 0;        // Reset incremental set pointer
        renderH = 0;        // Reset per-set strand pointer
    }

    // Trigger an autosave on mouse release if system is ready
    if (mouse_check_button_released(mb_left) && demoMode == 0 && autosaving == 0 && readyToCheckAutoloads == 1) {
        autosaving = 1;
        doAutoSave();
        renderToSurf = 1; // Signal surface update
    }

    // -------------------------------------------------------------------------
    // INPUT HANDLING & LOGGING
    // -------------------------------------------------------------------------

    // Handle Generation trigger (G key or UI Button)
    // This block only deals with the debug log. The render itself is armed in
    // Draw_0 (doOnce / retrigger / obj_wait), which tests the same key and the
    // same button rectangle.
    // LOGGING IS SWITCHED OFF: doLogOnce is forced to 9 on the next line, so the
    // ==0 and ==1 tests below never pass and every "if (doLogOnce == 1)" in this
    // file is skipped. To get a LOG__*.txt again, set doLogOnce to 0 here instead.
    if (keyboard_check_pressed(ord("G")) || (mouse_x > 1175 && mouse_x < 1375 && mouse_y > 67 && mouse_y < 97 && mouse_check_button_pressed(mb_left))) {
        doLogOnce = 9; // Internal state flag
        if (doLogOnce == 0) {
            logFile = file_text_open_append("LOG__" + string(current_time) + ".txt");
            file_text_write_string(logFile, "LogFile initiated");
            file_text_writeln(logFile);
            doLogOnce = 1;
        }
        if (doLogOnce == 1) {
            file_text_write_string(logFile, "Generated by G press");
            file_text_writeln(logFile);
        }
        if (doLogOnce == 1) {
            file_text_write_string(logFile, "QuickClear Surfaces");
            file_text_writeln(logFile);
        }
    }

    debugMsg = "Step Event";
    gpu_set_blendmode(bm_normal);
    
    // Clear wait objects if generation is cancelled or finished
    // In practice this is the START of a render: Draw_0 creates obj_wait when
    // Generate is pressed, and this is the first step after that. It rewinds
    // the set pointer to 0 and clears 'generating', so 'generating' is only
    // true for the remainder of the frame Generate was pressed in - it is NOT
    // true for the whole multi-step render. Use renderF / the GenStates to tell
    // whether a render is still running.
    if (instance_exists(obj_wait)) {
        instance_destroy(obj_wait);
        generating = false;
        pleaseGen = false;
        renderF = 0;
        renderH = 0;
    }

    // UV Image Loader interaction
    if (point_in_rectangle(mouse_x, mouse_y, 985, 1029, 1017, 1059)) {
        smallTip = "UV image loader - Load in an image, preferrably square, to trace over";
        if (mouse_check_button_pressed(mb_left)) {
            // Re-instantiate the loader object
            if (instance_exists(obj_UV_Image_Loader)) instance_destroy(obj_UV_Image_Loader);
            instance_create_depth(0, 0, -100, obj_UV_Image_Loader);
        }
    }

    // Set GPU write enable to protect Alpha channel during draw
    // Every map pass below draws RGB only: the canvases keep whatever alpha
    // they were created with, so overlapping semi-transparent strand sprites
    // cannot punch holes in the saved texture.
    // !! This runs on EVERY step and is NEVER switched back on in this function.
    // !! Alpha writes stay OFF for whatever draws next (the Draw events, the
    // !! preview). Anything that needs alpha written to a surface must call
    // !! gpu_set_colorwriteenable(1,1,1,1) first.
    // The background fills in MAP INITIALIZATION are affected too: they set
    // RGB and leave alpha as it was.
    gpu_set_colorwriteenable(true, true, true, false);

    // -------------------------------------------------------------------------
    // MAIN GENERATION LOOP
    // doOnce    armed by Generate (Draw_0). Stays true while sets remain,
    //           cleared at the very bottom once the last set is done.
    // retrigger must also be true; set by Generate and again after each set.
    // saving    a save in progress holds the render off.
    // -------------------------------------------------------------------------

    if (doOnce) {
		
        if (maxScale < 1) maxScale = 1; // Scale safety fix

        // Check if any map needs regeneration (State 1)
        if (retrigger && !saving && (color_GenState == 1 or ao_GenState == 1 or mask_GenState == 1 or rgbMask_GenState == 1 or id_GenState == 1 or flow_GenState == 1 or norm_GenState == 1 or depth_GenState == 1 or frizz_GenState == 1)) {
            
			// Override img display during generation
			// img is the map the main view shows: 0 RGB mask, 1 normal, 2 ID,
			// 3 depth, 4 colour, 5 mask, 6 flow, 7 AO, 8 frizz, 9 = the strand
			// previewer. Switching away from 9 also stops previewUpdate drawing
			// while the render runs. This function does not put img back afterwards.
				if      (doColor and color_GenState   == 1) img = 4;
				else if (doRGB   and rgbMask_GenState == 1) img = 0;
				else if (doDepth and depth_GenState   == 1) img = 3;
				else if (doMask and mask_GenState   == 1) img = 5;
				else if (doID and id_GenState   == 1) img = 2;
				else if (doFrizz and frizz_GenState   == 1) img = 8;
				else if (doAO and ao_GenState   == 1) img = 7;
				else if (doNorm and norm_GenState   == 1) img = 1;
				else if (doFlow and flow_GenState   == 1) img = 6;
				
				else img=9
				//doRGB=false//true
				/*
doNorm=false//true
doColor=false//true 4
doMask=false//true
doID=false//true
doDepth=false//true
doFlow=false //true 6
doAO=false  //7
doFrizz=false
generating=false//false
renderF=0 // incremental render - current set being rendered
*/



            // Validate all surfaces exist before plotting
            // NOTE: resetSurfaces() is an empty function now (its body is
            // commented out), so this call and the "else" branches in MAP
            // INITIALIZATION do not recreate anything. canvasCheck() at the top
            // of this function is what actually recreates a lost surface.
            if (!surface_exists(canvas) or !surface_exists(mask_canvas) or !surface_exists(color_canvas) or !surface_exists(depth_canvas) or !surface_exists(flow_canvas) or !surface_exists(frizz_canvas) or !surface_exists(id_canvas) or !surface_exists(mask_canvas) or !surface_exists(nm_canvas)) {
                resetSurfaces();
            }


            // -----------------------------------------------------------------
            // RENDER START - first step of a render only (set 0)
            // Resets the counters that run across the whole render and paints
            // each enabled map's background. Sets 1..N skip this, so they draw
            // on top of what the earlier sets left on the canvases.
            // -----------------------------------------------------------------
            // Initialization block for the first frame of a render
            if (renderF == 0) {
                curlRotator = 0;
                renderH = 0;
                idList = 0;   // V1.94 - was never reset, so ID map colours shifted run to run
                random_set_seed(seedVal); // superseded by the PER-SET SEED below, which re-seeds before any draw is taken
                xx1 = 0; yy1 = 0; xx2 = 0; yy2 = 0;
                cache_strandPointer = 0;

                if (doLogOnce == 1) {
                    file_text_write_string(logFile, "Generating Triggered");
                    file_text_writeln(logFile);
                }

                canvasCheck();

                #region // MAP INITIALIZATION
                // One block per map, all the same shape: if the map is due
                // (GenState 1), fill its 4096 canvas with the background colour.
                // Alpha writes are off (see above), so these fills change RGB
                // only. The "else" half of each block is the lost-surface
                // fallback; resetSurfaces() is empty, so it relies on
                // canvasCheck() having already recreated the surface.
                //
                // Background per map:
                //   RGB mask, Mask, ID, Depth, Flow   black
                //   Colour                            colrBack (the background swatch)
                //   Normal                            black in Multi Strand mode (moreHairs==1,
                //                                     the canvas holds a HEIGHT map that
                //                                     shd_normal converts later), else
                //                                     128,128,255 = flat tangent-space normal
                //   Frizz                             128 grey (mid value)
                //   AO                                200 grey
                
                // Flow Map base color (Tangent Space Blue)
                // NOTE: when the Flow map is being rendered (flow_GenState 1) the
                // "Flow Map setup" block further down fills the canvas black again,
                // so this early overwash is wiped. The blue that ends up in the
                // saved map comes from the "Final blue overwash" after the last set.
                if (dirBlue == 1 and dirHue == 0 and doFlow == 1 and flow_GenState != 2) {
                    gpu_set_blendmode(bm_add);
                    surface_set_target(flow_canvas);
                    var BlueCol = (make_color_rgb(128, 128, 255));
                    draw_set_color(BlueCol);
                    draw_rectangle(0, 0, 4095, 4095, 0);
                    surface_reset_target();
                    if (doLogOnce == 1) { file_text_write_string(logFile, "Flow Blue Overwash"); file_text_writeln(logFile); }
                    gpu_set_blendmode(bm_normal);
                }

                // RGB Mask Canvas setup
                if (rgbMask_GenState == 1) {
                    if (surface_exists(canvas)) {
                        surface_set_target(canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "RGB Mask Canvas fill"); file_text_writeln(logFile); }
                    } else {
                        resetSurfaces();
                        surface_set_target(canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Mask Canvas setup
                if (mask_GenState == 1) {
                    if (surface_exists(mask_canvas)) {
                        surface_set_target(mask_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(mask_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Color Canvas setup
                // (the fallback branch fills black, not colrBack)
                if (color_GenState == 1) {
                    if (surface_exists(color_canvas)) {
                        surface_set_target(color_canvas);
                        draw_set_color(colrBack);
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(color_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Normal Map setup
                // (the main branch picks the colour from moreHairs, the fallback
                //  branch from oldNormDraw - two different variables)
                if (norm_GenState == 1) {
                    if (surface_exists(nm_canvas)) {
                        surface_set_target(nm_canvas);
                        if (moreHairs == 1) draw_set_color(make_color_rgb(0, 0, 0));
                        if (moreHairs == 0) draw_set_color(make_color_rgb(128, 128, 255));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(nm_canvas);
                        if (oldNormDraw == 0) draw_set_color(make_color_rgb(0, 0, 0));
                        if (oldNormDraw == 1) draw_set_color(make_color_rgb(128, 128, 255));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // ID Map setup
                if (id_GenState == 1) {
                    if (surface_exists(id_canvas)) {
                        surface_set_target(id_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(id_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Depth Map setup
                if (depth_GenState == 1) {
                    if (surface_exists(depth_canvas)) {
                        surface_set_target(depth_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(depth_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Frizz Map setup
                if (frizz_GenState == 1) {
                    if (surface_exists(frizz_canvas)) {
                        surface_set_target(frizz_canvas);
                        draw_set_color(make_color_rgb(128, 128, 128));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(frizz_canvas);
                        draw_set_color(make_color_rgb(128, 128, 128));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // Flow Map setup
                if (flow_GenState == 1) {
                    if (surface_exists(flow_canvas)) {
                        surface_set_target(flow_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(flow_canvas);
                        draw_set_color(make_color_rgb(0, 0, 0));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                // AO Map setup
                if (ao_GenState == 1) {
                    if (surface_exists(ao_canvas)) {
                        surface_set_target(ao_canvas);
                        draw_set_color(make_color_rgb(200, 200, 200));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    } else {
                        resetSurfaces();
                        surface_set_target(ao_canvas);
                        draw_set_color(make_color_rgb(200, 200, 200));
                        draw_rectangle(0, 0, 4095, 4095, 0);
                        draw_set_color(c_white);
                        surface_reset_target();
                    }
                }

                #endregion
            }

            // -----------------------------------------------------------------
            // PER SET - everything from here to "End sets block" draws ONE set
            // (set renderF) and then returns; the next step does the next set.
            // -----------------------------------------------------------------
            strandCount = 0;   // strands drawn so far in THIS set (progress bar)
            {
                maxStrands = 2200;
                // (removed: rootRange was overwritten per strand below, and this
                //  line divided by zero when Root Position was dragged to 0)

                #region // MAIN CALCULATION - REFACTORED v2.0

                var thicknessBase = 1.0;
                curlRotator = 0;

                // Point cache arrays - Pre-allocated for high-speed calculation
                // One entry per point of the CURRENT strand, filled by PASS 1 and
                // read by every map in PASS 2, so the strand maths runs once per
                // point instead of once per point per map. 4000 is safe because
                // strand life is clamped to 3900 in updatePreRands. They are
                // locals of this call, so no copy-on-write concerns here.
                //   pt_finalX / pt_yy   position in 4096 space
                //   pt_prevX            X of the point above, for the direction (Flow, AO)
                //   pt_scA              sprite scale = strand thickness at this point
                //   pt_a                alpha from the fade in / fade out
                //   pt_colr             RGB-mask colour, pt_colrCustom Colour-map colour
                //   pt_depthTone        Depth-map grey (same for the whole strand)
                //   pt_ang, pt_curl, pt_sub   Multi Strand only: base angle, running curl, sub-image
                var pt_finalX = array_create(4000, 0);
                var pt_yy = array_create(4000, 0);
                var pt_scA = array_create(4000, 0);
                var pt_a = array_create(4000, 1);
                var pt_colr = array_create(4000, c_white);
                var pt_colrCustom = array_create(4000, c_white);
                var pt_depthTone = array_create(4000, c_white);
                var pt_ang = array_create(4000, 0);
                var pt_curl = array_create(4000, 0);
                var pt_sub = array_create(4000, 0);
                var pt_prevX = array_create(4000, 0);
                var pt_count = 0;

                // Current batch index
                var f = renderF;

                // -------------------------------------------------------------
                // PER-SET SEED. Now that every per-strand value comes from the
                // pre-random tables, the only thing left in this render that draws
                // from the stream is the frizz map's irandom() further down. This
                // keeps that deterministic per set instead of depending on frame
                // boundaries and on whatever the preview did in between. The
                // +f*7919 stops all eleven sets sharing a stream, since
                // randomSeedVal defaults to 1 for every set.
                // -------------------------------------------------------------
                random_set_seed(randomSeedVal[f] + (f * 7919));
                if (doLogOnce == 1) { file_text_write_string(logFile, "SET ID:" + string(f)); file_text_writeln(logFile); }
                
                setID = f;
                sx = xx;
                // ID map colour: idMode 1 = one colour per SET (picked here),
                // idMode 0 = one colour per STRAND (picked in the strand loop).
                if (idMode == 1) idChoice = colorIDarray[f];
                sc = 1;
                a = 1;

                // Calculate Strand Set properties
                // V1.94 - was random(lifeVariant*2), re-rolled here. Two problems:
                // it disagreed with the preview (which uses preRandLifeVariant), and
                // lifeVariant is not assigned until inside the strand loop below, so
                // this was rolling against the PREVIOUS set's variance.
                // V1.95 - unconditional, with the same fallback as the preview, so
                // hairLength can never carry over from the previous set or frame.
                var _hlF = strandLengthOverride[f];
                if (_hlF <= 0) _hlF = length;
                hairLength = _hlF + preRandLifeVariant[f];
                if (setCountOverrode[f] == 1) strandSet = strandCountOverride[f]; else strandSet = strands;
                strandSet = min(strandSet, 100);   // the pre-random tables hold 100 strands per set

                // V1.96 - the three mixer paths depend only on the set and n, so
                // sample them once per set here (3 x 3900 path_get_x calls) rather
                // than at every point of every strand (3 x ~3000 x up to 100).
                // Step 1 = one cache entry per point, so mixCacheX[n] below.
                mixerCacheBuild(f, 1, strandSetVariAdj[f]);
                // V1.96 - clump membership for this set (clumpTools)
                // 3902 = room for a leader path at step 1 (life <= 3900, + spare).
                // Both helpers allocate fresh arrays, so the preview's own copies
                // (kept in pvW[]) are not overwritten by the render.
                clumpPrepareSet(f, strandSet, 3902);

                // -------------------------------------------------------------
                // PER-STRAND GENERATION LOOP
                // h = strand index within the set = the column of every
                // preRand*[f, h] table. Strands are drawn in index order, so a
                // higher h is drawn on top of a lower one. Clumping relies on
                // this order too: a clump's leader is always its lowest h, so
                // its path is stored before any follower needs it.
                // -------------------------------------------------------------
                for (h = 0; h < strandSet; h++) {
                    checkSum++;
                    // DEPTH MAP tone: one grey per strand, rising with the strand
                    // index (20..255 across the set), so later strands are brighter.
                    var d = clamp(floor((255 / strandSet) * h), 20, 255);
                    depthTone = make_color_rgb(d, d, d);
                    // -----------------------------------------------------------
                    // Every per-strand value below comes straight from the per-set
                    // pre-random tables, exactly as doCalc reads them for the
                    // preview. It used to roll each one live and then overwrite it
                    // from the preview's cache only when h < maxPreviewStrandsPerSet
                    // - a PREVIEW QUALITY setting (20 / 30 / 50 / 100). So in the
                    // default 50 mode, strands 50-99 of every set were freshly
                    // random and had never been previewed: the render genuinely had
                    // its own randomness for half of every set.
                    // -----------------------------------------------------------
                    dpth = preRandDepth[f, h];   // 0..1, drives the RGB-mask red channel and the colour A/B blend
					// xxx, yyy = top-left of the 512x512 zoom window Draw_0 cuts
					// out of the canvas for the detail view
					xxx = (1024 / 11) * h
					yyy = 400
                    subSpriteChoice = preRandSubSprite[f, h];
                    angChoice = preRandAngChoice[f, h];
                    // V1.92 - identical rule to doCalc. The old code re-rolled
                    // random_range once per active override AFTER taking the cached
                    // preview value, which both discarded that value and pulled extra
                    // numbers out of the random stream - so an overridden set drifted
                    // away from its own preview. One draw, clamps chosen up front.
                    thicknessBase = preRandThickBase[f, h];

                    if (idMode == 0) {
                        idChoice = colorIDarray[idList];
                        idList++;
                        if (idList > strandIDsize) idList = 0;
                    }

                    // lifeVariant is ALSO the global 'Variation' setting that the slider and
                    // text box write. Assigning the per-set value to it here overwrote the
                    // typed value every frame, which is why the Variation box would not take
                    // an edit. Use a local for the per-set working value instead.
                    var _lvS = strandSetVariAdj[f];
                    
                    // Spacing and initial X position logic
                    // xx      = this strand's root X: a random spot (preRandSpacing,
                    //           0..spacing*10) inside the set's span.
                    // setXpos = the set's gather point, at the right-hand end of
                    //           that span. Taper pulls strands toward it.
                    // Each set is shifted right by f * setDistance * 10.
                    // Same two expressions as doCalc - keep them identical.
                    xx = (320 - (strandSetSpaceAdj[f] * 10)) + ((strandSetSpaceAdj[f] * 10) * 0.5) + ((preRandSpacing[f, h] + (f * ((setDistance * 2) * 5))));
                    setXpos = (320 - (strandSetSpaceAdj[f] * 10)) + (strandSetSpaceAdj[f] * 10) + (f * ((setDistance * 2) * 5));
                    sx = xx;

                    // life = strand length in points = pixels down the map (10..3900).
                    // The point loop runs n = 0..life-1 and moves down 1 px per point.
                    life = preRandLife[f, h];

                    scaleIn = life * 0.75;
                    scaleOut = life * 0.12;
                    avgLife = median(life, avgLife);

                    freq = preRandFreq[f, h];   // wave frequency, between the set's Wave Freq min and max

                    amp = preRandAmp[f, h];     // 0..0.1, scales the wave ANGLE (see Wave below)

                    yp = 0;
                    // Start Y. yOffset is added here; xOffset is added later, to finalX.
                    yy = preRandYY[f, h] + yOffset[f];

                    nx = 0;
                    rootRange = preRandRootRange[f, h];
                    root      = preRandRoot[f, h];   // how far down the root tint reaches (see rt below)

                    tip = ((tipPosition * 10));      // length of the tip tint at the far end (see tp below)

                    // The pleaseGen guard here was dead - pleaseGen is false for the
                    // whole render, so these two were never assigned during a render.
                    strandDecision = preRandStrandDecision[f, h];

                    straggleChoice = preRandStraggleChoice[f, h];

                    cache_strandPointer = 0;
                    if (doLogOnce == 1) { file_text_write_string(logFile, "Strand ID: " + string(h) + " Life:" + string(life)); file_text_writeln(logFile); }

                    // Setup thickness and color parameters for the point-loop
                    // tMin / tMax = the set's thickness range as SPRITE SCALE:
                    // slider value x padFactor, where padFactor = 0.05 + padding/1000.
                    // cmx / cmy   = Root / Tip Thickness sliders as a 0..1-ish blend
                    // weight (slider / 30) - see "Thickness" in the point loop.
                    var t_minScale = setThickMinAdj[f];
                    var t_maxScale = setThickMaxAdj[f];
                    var cmx = setRootThickAdj[f] / 30;              // V1.91 per-set
                    var cmy = setTipThickAdj[f] / 30;               // V1.91 per-set
                    // V1.94 - dpthAdd was re-rolled inside the point loop; the preview
                    // uses one value per strand from preRandDepthAdd. Same table now, so
                    // the depth/colour blend agrees. (Reinstating the per-point speckle
                    // means moving this line back into the loop as random_range.)
                    dpthAdd = preRandDepthAdd[f, h];
                    var _fadeInS  = clamp(setFadeInAdj[f],  1, 40); // V1.91 per-set
                    var _fadeOutS = clamp(setFadeOutAdj[f], 1, 40); // V1.91 per-set
                    var padFactor = 0.05 + (padding / 1000);
                    var tMin = t_minScale * padFactor;
                    var tMax = t_maxScale * padFactor;
                    var tMax2 = tMax * 2;

                    // ---------------------------------------------------------
                    // V1.90 NOISE - per-strand setup. Phases are hashed from the
                    // set seed + set/strand index so the deviation is seed-driven
                    // and repeatable WITHOUT drawing from the random stream.
                    // noiseAmt = 0 skips all of this and the loop cost with it.
                    // noiseP1..3 = start phase of three sine octaves, as lut_sin
                    //              indexes (0..1440 = 0..360 degrees)
                    // noiseS1..3 = index advance per point. _nCyc = 1440/life is one
                    //              full cycle over the strand; the octaves run at
                    //              1.0x, 2.7x and 6.3x that.
                    // noiseAmpS  = sideways reach in pixels: grows with the Noise
                    //              amount and with strand length (noiseScale, set
                    //              in Create, is the master tuning value).
                    // This block is a copy of the one in doCalc - keep them identical.
                    // ---------------------------------------------------------
                    noiseOn = 0;
                    noiseP1 = 0; noiseP2 = 0; noiseP3 = 0;
                    noiseS1 = 0; noiseS2 = 0; noiseS3 = 0;
                    noiseAmpS = 0;

                    var _noiseAmtS  = setNoiseAmtAdj[f];    // V1.91 per-set
                    var _noiseFreqS = setNoiseFreqAdj[f];   // V1.91 per-set

                    if (_noiseAmtS > 0) {
                        noiseOn = 1;
                        var _nA = (h * 12.9898) + (f * 78.233) + (randomSeedVal[f] * 37.719);
                        noiseP1 = frac(abs(sin(_nA)         * 43758.5453)) * 1440;
                        noiseP2 = frac(abs(sin(_nA + 17.31) * 43758.5453)) * 1440;
                        noiseP3 = frac(abs(sin(_nA + 53.77) * 43758.5453)) * 1440;
                        // Frequency slider scales all three octaves together.
                        // noiseFreq 10 = neutral (1.0), 0 = 0.2, 40 = 3.4.
                        var _nFMul = 0.2 + (_noiseFreqS * 0.08);
                        var _nCyc = 1440 / max(life, 1);
                        noiseS1 = _nCyc * 1.0 * _nFMul;   // slow sweep down the fibre
                        noiseS2 = _nCyc * 2.7 * _nFMul;
                        noiseS3 = _nCyc * 6.3 * _nFMul;
                        noiseAmpS = (_noiseAmtS * 0.025) * (life * noiseScale);
                    }

                    // Color channel extraction for optimized blending
                    // customColVarA/B, customRootCol, customTipCol are THIS SET's
                    // colours here: Step_2 swaps them in around the doMainStep()
                    // call. (The preview reads setColVarA[b] etc. directly.)
                    var cRvA = color_get_red(customColVarA); var cGvA = color_get_green(customColVarA); var cBvA = color_get_blue(customColVarA);
                    var cRvB = color_get_red(customColVarB); var cGvB = color_get_green(customColVarB); var cBvB = color_get_blue(customColVarB);
                    var cRroot = color_get_red(customRootCol); var cGroot = color_get_green(customRootCol); var cBroot = color_get_blue(customRootCol);
                    var cRtip = color_get_red(customTipCol); var cGtip = color_get_green(customTipCol); var cBtip = color_get_blue(customTipCol);

                   // ---------------------------------------------------------
                    // PASS 1: POINT CALCULATION — LUT version
                    // Walks the strand root to tip and fills the pt_* arrays.
                    // Nothing is drawn in this pass.
                    // LUT: lut_sin / lut_cos (Create) hold 1440 entries, one per
                    // quarter degree, so the index is always  round(degrees * 4) mod 1440.
                    // ---------------------------------------------------------
                    pt_count = 0;
                    var prevX_cache = xOffset[f] + xx;   // V1.94 - finalX includes xOffset

                    // V1.96 clumping, per strand - identical rule to previewDrawStrands
                    // _cMode 0 = clumping off for this strand (or its leader has no path)
                    //        1 = this strand LEADS its clump: record its X at every
                    //            point into clumpLeadX[bin] for the followers
                    //        2 = follower: gets pulled toward the leader's recorded path
                    // _cW  = pull strength (Amount x this strand's stickiness)
                    // _cK  = leader points per unit of length fraction; it maps
                    //        "x% along me" to "x% along the leader" even when the
                    //        two strands have different lengths. clumpLeadStep is 1
                    //        in the render (10/20/40 in the preview).
                    var _cMode = 0, _cBin = 0, _cIdx = 0, _cW = 0, _cLen = 0, _cK = 0, _cArr = 0;
                    if (clumpOnS == 1) {
                        _cBin = clumpBin[h];
                        if (clumpIsLead[h] == 1) _cMode = 1;
                        else if (clumpLeadLen[_cBin] > 1) {
                            _cMode = 2;
                            _cW    = clumpAmtS * clumpStick[h];
                            _cLen  = clumpLeadLen[_cBin];
                            _cK    = clumpLeadLife[_cBin] / clumpLeadStep[_cBin];
                            _cArr  = clumpLeadX[_cBin];
                        }
                    }
                    a = 1;
                    var _lifeRcp = 1 / life; // avoid repeated division

                    for (n = 0; n < life; n++) {
                        // Root and tip gradients
                        // rt: 1 at the root, falling to 0 where the root tint ends
                        //     (n is rescaled as if the strand were 3800 long, so the
                        //     tint covers the same share of a short strand), then
                        //     0.01 for the rest of the strand.
                        // tp: 0 along the body, rising toward 1 over the last
                        //     stretch before (life - tip); 1 from there to the end.
                        // They become the GREEN (rt) and BLUE (tp) channels of the
                        // RGB mask and the root/tip tint weights of the Colour map.
                        // V1.94 - the preview has these else branches; without them the
                        // render latched the last computed rt/tp and smeared root colour
                        // down the strand.
                        if (root > n) { rt = 1 - (clamp((n * (3800 / life)) / root, 0, 1)); } else { rt = 0.01; }
                        if (life - tip > n) { tp = 1 - (clamp(abs((life - tip - n)) / (tip * (life / 3800)), 0, 1)); } else { tp = 1; }

                        // Thickness — LUT (dsin/dcos degree-based, exact match)
                        // Three profiles along the strand (t = n/life):
                        //   scx  sin(t*90)   thin at the root, widest at the tip   (range tMin..tMax*2)
                        //   scy  cos(t*90)   widest at the root, thin at the tip   (range tMin..tMax*2)
                        //   scz  sin(t*180)  thin at both ends, widest in the middle (tMin..tMax)
                        // cmx blends scx toward scz, cmy blends scy toward scz, the two
                        // results are added, multiplied by the strand's own random
                        // thickness (thicknessBase), clamped and halved.
                        // scA is the sprite scale used by every map pass.
                        var _li90  = round(n * _lifeRcp * 360) mod 1440;
                        var _li180 = round(n * _lifeRcp * 720) mod 1440;
                        var scx = lerp(tMin, tMax2, lut_sin[_li90]);
                        var scy = lerp(tMin, tMax2, lut_cos[_li90]);
                        var scz = lerp(tMin, tMax,  lut_sin[_li180]);
                        var tA = lerp(scx, scz, cmx);
                        var tB = lerp(scy, scz, cmy);
                        var scA = (clamp((tA + tB) * thicknessBase, 0.15, 100) / 2);

                        // RGB MASK colour: R = per-strand variation (depth),
                        // G = root gradient, B = tip gradient.
                        colr = make_color_rgb(clamp(255 * (dpth + dpthAdd), 0, 255), 255 * rt, 255 * tp);

                        // Custom colour — pre-extracted channels
                        // COLOUR MAP: blend colour A -> B by the strand's depth,
                        // then toward the root colour by rt, then the tip colour by tp.
                        var blend = clamp(dpth + dpthAdd, 0, 1);
                        var cv_r = lerp(cRvA, cRvB, blend); var cv_g = lerp(cGvA, cGvB, blend); var cv_b = lerp(cBvA, cBvB, blend);
                        cv_r = lerp(cv_r, cRroot, rt); cv_g = lerp(cv_g, cGroot, rt); cv_b = lerp(cv_b, cBroot, rt);
                        cv_r = lerp(cv_r, cRtip,  tp); cv_g = lerp(cv_g, cGtip,  tp); cv_b = lerp(cv_b, cBtip,  tp);
                        colrCustom = make_color_rgb(cv_r, cv_g, cv_b);

                        // Alpha fade
                        // Fade In / Fade Out sliders (1..40). At 40 a fade covers
                        // half the strand (slider/40 * life/2). Alpha ramps 0..1
                        // over the fade-in length at the root and 1..0 over the
                        // fade-out length at the tip. The fade-in test runs second,
                        // so it wins where the two overlap on a very short strand.
                        // (The preview bends this alpha through an opacity curve
                        // for display; the render uses it as it is.)
                        a = 1;
                        // V1.91 per-set. The old code clamped the GLOBAL fadeIn /
                        // fadeOut from inside the point loop; the per-set values are
                        // clamped once, above, instead.
                        if (n > life - ((_fadeOutS / 40) * (life / 2))) { a = clamp((life - n) / ((_fadeOutS / 40) * (life / 2)), 0, 1); }
                        if (n < ((_fadeInS / 40) * (life / 2)) + 1)     { a = clamp(n / ((_fadeInS / 40) * (life / 2)), 0, 1); }

                        // Wave — LUT with amp inside angle (matches original sin(degtorad(n*freq)*amp))
                        var _liDev  = round(n * freq * 4)       mod 1440; // sin(degtorad(n*freq))
                        var _liWave = round(n * freq * amp * 4) mod 1440; // sin(degtorad(n*freq)*amp)
                        deviationFromX = lut_sin[_liDev];
                        // Multi Strand only (preRandCurling is 0 otherwise): the sprite
                        // rotation creeps on every point. curlRotator is NOT reset per
                        // strand - it carries on through the whole set.
                        curlRotator += preRandCurling[f, h];
                        // WAVE: nx = root X plus a sine of (n * freq * amp) degrees.
                        // Its width is (yy - yOffset)/100, i.e. the un-offset Y, so
                        // the wave gets wider the further down the map the point is.
                        nx = xx + (lut_sin[_liWave] * ((yy - yOffset[f]) / 100));

                        // MIXERS: the three mixer paths blended into one sideways
                        // offset for this distance down the strand (per set, not per strand).
                        var tempX = mixCacheX[n];   // V1.96 - see mixerCacheBuild

                        // straggleXX = the mixer-shaped path, drifting toward the
                        //   set's gather point with distance (n/3000 x Taper%).
                        // algFinalX  = first move from the straight line (xx) toward
                        //   the wave by Waviness% x ampFactor (8, set in Create), then
                        //   blend that with the mixer path. The blend weight is
                        //   0.5 + (Variation - 50)/100, so Variation 50 = half and half,
                        //   higher = more mixer shape.
                        // algTaper   = TAPER: pull toward setXpos, zero at the root
                        //   and Taper% at the tip (Taper is treated as at least 1).
                        straggleXX = lerp(xx + tempX, setXpos, (n / 3000) * (strandSetTaperAdj[f] * 0.01));
                        var algFinalX = lerp((lerp(xx, nx, (strandSetWavynessAdj[f] * 0.01) * ampFactor)), straggleXX, 0.5 + ((_lvS - 50) / 100));
                        var algTaper  = lerp(algFinalX, setXpos, (n / life) * (clamp(strandSetTaperAdj[f], 1, strandSetTaperAdj[f]) * 0.01));

                        // V1.90 NOISE - gradual left/right deviation, root anchored
                        // so the fibre stays continuous and connected at the root.
                        // Three sine octaves weighted 0.62 / 0.28 / 0.10, times the
                        // amplitude, times n/life (zero at the root, full at the tip).
                        var _nzOfs = 0;
                        if (noiseOn == 1) {
                            var _n1 = lut_sin[round(noiseP1 + (n * noiseS1)) mod 1440];
                            var _n2 = lut_sin[round(noiseP2 + (n * noiseS2)) mod 1440];
                            var _n3 = lut_sin[round(noiseP3 + (n * noiseS3)) mod 1440];
                            _nzOfs = ((_n1 * 0.62) + (_n2 * 0.28) + (_n3 * 0.10)) * noiseAmpS * (n * _lifeRcp);
                        }

                        // The set's X offset (dragging the set on the canvas) goes in last.
                        finalX = xOffset[f] + algTaper + _nzOfs;

                        // V1.96 CLUMPING - pull toward this tress's leader
                        // Leader: store finalX (it already includes xOffset).
                        // Follower: _u runs 0..1 from the clump Start point to the tip;
                        // look up the leader's X at the same fraction of ITS length
                        // (interpolating between two stored points) and move toward it
                        // by _cW x smoothstep(_u), so the pull eases in and is
                        // strongest at the tip.
                        // The leader write below is a plain write and is safe HERE
                        // because clumpPrepareSet has just created these arrays and
                        // nothing else holds a reference to them. The preview shares
                        // its arrays with pvW[] and must use [@ ] (copy-on-write).
                        if (_cMode == 1) { clumpLeadX[_cBin][_cIdx] = finalX; _cIdx++; }
                        else if (_cMode == 2) {
                            var _u = clamp(((n * _lifeRcp) - clumpStartS) * clumpRampS, 0, 1);
                            if (_u > 0) {
                                var _fi = min((n * _lifeRcp) * _cK, _cLen - 1);
                                var _i0 = floor(_fi);
                                var _lx = lerp(_cArr[_i0], _cArr[min(_i0 + 1, _cLen - 1)], _fi - _i0);
                                finalX = lerp(finalX, _lx, _cW * _u * _u * (3 - (2 * _u)));
                            }
                        }

                        pt_finalX[pt_count] = finalX; pt_yy[pt_count] = yy; pt_scA[pt_count] = scA; pt_a[pt_count] = a;
                        pt_colr[pt_count] = colr; pt_colrCustom[pt_count] = colrCustom; pt_depthTone[pt_count] = depthTone;
                        pt_ang[pt_count] = angChoice; pt_curl[pt_count] = curlRotator; pt_sub[pt_count] = subSpriteChoice;
                        pt_prevX[pt_count] = prevX_cache;

                        prevX_cache = finalX;
                        pt_count++;
                        yy++;   // one pixel down the map per point
                        yp++;
                    }
                    // Leader finished: record how many points it stored and its
                    // length, so followers can map their own length onto it.
                    if (_cMode == 1) {
                        clumpLeadLen[_cBin]  = _cIdx;
                        clumpLeadLife[_cBin] = life;
                        clumpLeadStep[_cBin] = 1;
                    }

                    // ---------------------------------------------------------
                    // PASS 2: BATCHED RENDERING TO SURFACES
                    // One block per map. Each sets its 4096 canvas as the target
                    // ONCE for the whole strand, then draws one sprite per stored
                    // point ("batched" = one target switch per strand per map,
                    // not one per point).
                    //
                    // Common to every pass:
                    //   - runs only if the map's tick box (do*) is on AND its
                    //     GenState is 1
                    //   - alpha writes are OFF (set near the top), so only RGB
                    //     changes; pt_a still controls how strongly each sprite
                    //     blends over what is already there
                    //   - blend mode is bm_normal
                    //   - moreHairs==0 (Single Strand): sub-image as stored, no rotation
                    //     moreHairs==1 (Multi Strand): rotated by pt_ang + pt_curl
                    //   - sprite scale is pt_scA (the thickness)
                    // The passes differ only in target surface, sprite and colour.
                    // ---------------------------------------------------------

                    // RGB Mask Draw
                    // Target: canvas. Sprite: spr_strander. Colour: pt_colr
                    // (R = variation, G = root gradient, B = tip gradient).
                    if (doRGB and rgbMask_GenState == 1) {
                        surface_set_target(canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, pt_colr[_pi], pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], pt_colr[_pi], pt_a[_pi]);
                        }
                        surface_reset_target();
                        rgbMask_GenState = 1;
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT RGB canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Color Pass Draw
                    // Target: color_canvas. Sprite: spr_strander. Colour: pt_colrCustom
                    // (this set's A/B colours blended by depth, then root and tip tints).
                    if (doColor and color_GenState == 1) {
                        surface_set_target(color_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, pt_colrCustom[_pi], pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], pt_colrCustom[_pi], pt_a[_pi]);
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT COLOR canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Normal Map Draw
                    // Target: nm_canvas. Two different methods:
                    //   Multi Strand (moreHairs==1): spr_stranderBUMP in white at
                    //     about half alpha over a black canvas. This is a HEIGHT
                    //     map; shd_normal turns it into a normal map when it is
                    //     shown (Draw_0) and when it is saved/exported.
                    //   Single Strand (moreHairs==0): spr_nm, a ready-made normal
                    //     blob, drawn four times from 1.3x down to 1.0x scale with
                    //     rising alpha, to give a soft shoulder round the strand.
                    // Leaves texture filtering switched ON (gpu_set_texfilter(1)).
                    if (doNorm and norm_GenState == 1) {
                        surface_set_target(nm_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 1) {
                                gpu_set_blendmode(bm_normal);
                                draw_sprite_ext(spr_stranderBUMP, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], c_white, pt_a[_pi] * 0.51);
                            }
                            if (moreHairs == 0) {
                                draw_sprite_ext(spr_nm, 0, pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi] * 1.3, pt_scA[_pi] * 1.3, 0, c_white, pt_a[_pi] * 0.25);
                                draw_sprite_ext(spr_nm, 0, pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi] * 1.2, pt_scA[_pi] * 1.2, 0, c_white, pt_a[_pi] * 0.50);
                                draw_sprite_ext(spr_nm, 0, pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi] * 1.1, pt_scA[_pi] * 1.1, 0, c_white, pt_a[_pi] * 0.75);
                                draw_sprite_ext(spr_nm, 0, pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, c_white, pt_a[_pi]);
                            }
                        }
                        surface_reset_target();
                        gpu_set_texfilter(1);
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT NORMAL canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // ID Map Draw
                    // Target: id_canvas. Sprite: spr_strander. Colour: idChoice, a flat
                    // colour from colorIDarray - per strand (idMode 0, cycling through
                    // strandIDsize+1 colours) or per set (idMode 1).
                    if (doID and id_GenState == 1) {
                        surface_set_target(id_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, idChoice, pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], idChoice, pt_a[_pi]);
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT ID canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Flow Map Draw
                    // Target: flow_canvas. Sprite: spr_strander. The colour encodes
                    // the direction the strand is travelling at this point, taken
                    // from the previous point (ppx, one pixel up) to this one.
                    // Strands run down the map, so that angle lies in 180..360.
                    //   dirHue==1  hue mode: the angle is remapped 180..360 -> 0..1
                    //              and used as the hue, full saturation and value.
                    //   otherwise  vector mode: R = (cos(angle)+1)/2 (ud),
                    //              G = (sin(angle)+1)/2 (lr), B = 0. Blue is added
                    //              afterwards by the "Final blue overwash" if dirBlue
                    //              is on. Multi Strand also adds a share of the sprite
                    //              rotation to the angle.
                    // dirFlipX / dirFlipY flip a channel by adding 180 inside
                    // sin()/cos(). Note the 180 is added OUTSIDE degtorad, so it is
                    // 180 radians, not 180 degrees.
                    if (doFlow and flow_GenState == 1) {
                        surface_set_target(flow_canvas);
                        gpu_set_blendmode(bm_normal);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            var pfx = pt_finalX[_pi]; var pyy = pt_yy[_pi]; var ppx = pt_prevX[_pi];
                            var psc = pt_scA[_pi]; var pa = pt_a[_pi]; var psub = pt_sub[_pi];
                            var pang = pt_ang[_pi] + pt_curl[_pi];
                            if (dirHue == 1) {
                                var remapAng = remap(point_direction(ppx, pyy - 1, pfx, pyy), 180, 360, 0, 1);
                                if (moreHairs == 0) draw_sprite_ext(spr_strander, psub, pfx, pyy, psc, psc, 0, make_color_hsv((254 * remapAng), 255, 255), pa);
                                if (moreHairs == 1) draw_sprite_ext(spr_strander, psub, pfx, pyy, psc, psc, pang, make_color_hsv((254 * remapAng), 255, 255), pa);
                            } else {
                                var lr = 0; var ud = 0;
                                if (moreHairs == 1) {
                                    lr = (sin((dirFlipX * 180) + degtorad(point_direction(ppx, pyy - 1, pfx, pyy) + (pang * curlRotAmt * 0.001))) + 1) / 2;
                                    ud = (cos((dirFlipY * 180) + degtorad(point_direction(ppx, pyy - 1, pfx, pyy) + (pang * curlRotAmt * 0.001))) + 1) / 2;
                                }
                                if (moreHairs == 0) {
                                    lr = (sin((dirFlipX * 180) + degtorad(point_direction(ppx, pyy - 1, pfx, pyy))) + 1) / 2;
                                    ud = (cos((dirFlipY * 180) + degtorad(point_direction(ppx, pyy - 1, pfx, pyy))) + 1) / 2;
                                }
                                gpu_set_blendmode(bm_normal);
                                if (moreHairs == 0) draw_sprite_ext(spr_strander, psub, pfx, pyy, psc, psc, 0, make_color_rgb(255 * ud, 255 * lr, 0), pa);
                                if (moreHairs == 1) draw_sprite_ext(spr_strander, psub, pfx, pyy, psc, psc, pang, make_color_rgb(255 * ud, 255 * lr, 0), pa);
                            }
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT FLOW canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // AO Map Draw
                    // Target: ao_canvas (200 grey background).
                    //   Single Strand: spr_aoPlotter in white, rotated to follow the
                    //     strand direction, in up to 'passes' rings of growing size
                    //     (aoExtra = the AO width setting; it sets both the ring
                    //     sizes and, via passes, how many there are).
                    //     'tog' thins the work out: it counts 1..6 and only a ring
                    //     that lands on tog==1 is drawn, so one ring in six. tog is
                    //     an instance variable and is NOT reset per point, strand or
                    //     render, so which rings get drawn carries over from the
                    //     previous point. aoAmt (the ring alpha) drops slightly
                    //     after each ring that is drawn.
                    //   Multi Strand: spr_stranderAO in white at 0.88 alpha, then a
                    //     slightly smaller black copy at 0.25 alpha.
                    if (doAO and ao_GenState == 1) {
                        surface_set_target(ao_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            var pfx = pt_finalX[_pi]; var pyy = pt_yy[_pi]; var ppx = pt_prevX[_pi];
                            var psc = pt_scA[_pi]; var psub = pt_sub[_pi]; var pang = pt_ang[_pi] + pt_curl[_pi];
                            if (moreHairs == 0) {
                                var aoAmt = (10 - aoExtra) * 0.05;
                                var passes = clamp(round(10 * aoExtra), 6, 10);
                                for (pass = 1; pass < passes + 1; pass++) {
                                    if (tog == 1) {
                                        draw_sprite_ext(spr_aoPlotter, psub, pfx, pyy, psc * (pass / passes) * (aoExtra * (pass / passes)), psc * (pass / passes) * (aoExtra * (pass / passes)), point_direction(ppx, pyy - 1, pfx, pyy) + 90, c_white, aoAmt);
                                        aoAmt -= (0.16 / passes);
                                    }
                                    tog++;
                                    if (tog >= 7) tog = 1;
                                }
                            }
                            if (moreHairs == 1) {
                                draw_sprite_ext(spr_stranderAO, psub, pfx, pyy, psc, psc, pang, c_white, 0.88);
                                draw_sprite_ext(spr_stranderAO, psub, pfx, pyy, psc * 0.97, psc * 0.97, pang, c_black, 0.25);
                            }
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT AO canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Mask Map Draw
                    // Target: mask_canvas. Sprite: spr_strander in plain white on
                    // black - the opacity (alpha) map for the hair card.
                    if (doMask and mask_GenState == 1) {
                        surface_set_target(mask_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, c_white, pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], c_white, pt_a[_pi]);
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT MASK canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Depth Map Draw
                    // Target: depth_canvas. Sprite: spr_strander. Colour: pt_depthTone,
                    // the per-strand grey worked out at the top of the strand loop.
                    if (doDepth and depth_GenState == 1) {
                        surface_set_target(depth_canvas);
                        gpu_set_blendmode(bm_normal);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, pt_depthTone[_pi], pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], pt_depthTone[_pi], pt_a[_pi]);
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT DEPTH canvas (batched)"); file_text_writeln(logFile); }
                    }

                    // Frizz Map Draw
                    // Target: frizz_canvas (128 grey background). Sprite: spr_strander
                    // in a random grey PER POINT.
                    // irandom(255) is the ONLY live random draw in the render. It
                    // runs once per point per strand, and only when the Frizz map
                    // is being drawn. The stream is re-seeded at the start of each
                    // set (PER-SET SEED), so the result repeats run to run. Adding
                    // any other random call inside the set loop would change the
                    // frizz map.
                    if (doFrizz and frizz_GenState == 1) {
                        surface_set_target(frizz_canvas);
                        for (_pi = 0; _pi < pt_count; _pi++) {
                            frizzColor = make_color_hsv(0, 0, irandom(255));
                            if (moreHairs == 0) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], 0, frizzColor, pt_a[_pi]);
                            if (moreHairs == 1) draw_sprite_ext(spr_strander, pt_sub[_pi], pt_finalX[_pi], pt_yy[_pi], pt_scA[_pi], pt_scA[_pi], pt_ang[_pi] + pt_curl[_pi], frizzColor, pt_a[_pi]);
                        }
                        surface_reset_target();
                        if (doLogOnce == 1) { file_text_write_string(logFile, "PLOT FRIZZ canvas (batched)"); file_text_writeln(logFile); }
                    }

                    strandCount++;

                    // ---------------------------------------------------------
                    // PROGRESS FEEDBACK BLITTING
                    // The whole set is drawn inside one step, so the window would
                    // otherwise show nothing until the set is finished. Every 20
                    // strands this draws the map in progress straight onto the
                    // application surface: a 2048-wide, full-height slice centred
                    // on the set, squeezed into the 1024x1024 view (x0.5 wide,
                    // x0.25 high), with a red tint, a progress bar and a caption.
                    // It only touches application_surface, never the map canvases.
                    // 'sets' is the index of the last set, hence sets + 1 = how many.
                    // ---------------------------------------------------------
                    if (strandCount mod 20 == 0) {
                        var _activeCanvas;
                        // Canvas priority: colour > rgbmask > depth > others
                        if      (doColor  and color_GenState    == 1) _activeCanvas = color_canvas;
                        else if (doRGB    and rgbMask_GenState  == 1) _activeCanvas = canvas;
                        else if (doDepth  and depth_GenState    == 1) _activeCanvas = depth_canvas;
                        else if (doMask   and mask_GenState     == 1) _activeCanvas = mask_canvas;
                        else if (doNorm   and norm_GenState     == 1) _activeCanvas = nm_canvas;
                        else if (doID     and id_GenState       == 1) _activeCanvas = id_canvas;
                        else if (doFlow   and flow_GenState     == 1) _activeCanvas = flow_canvas;
                        else if (doAO     and ao_GenState       == 1) _activeCanvas = ao_canvas;
                        else if (doFrizz  and frizz_GenState    == 1) _activeCanvas = frizz_canvas;
                        else                                          _activeCanvas = canvas;

                        if (surface_exists(_activeCanvas)) {
                            // Centre viewport on the current set being generated
                            // setXpos is the set's X centre in 4096 space
                            // Show a 2048-wide window centred on it for context
                            var _srcW = 2048;
                            var _srcH = 4096;
                            var _srcX = clamp(setXpos - (_srcW * 0.5), 0, 4096 - _srcW);
                            var _srcY = 0;

                            surface_set_target(application_surface);
                            draw_clear(c_black);
                            draw_surface_part_ext(_activeCanvas, _srcX, _srcY, _srcW, _srcH, 0, 0, 1024/_srcW, 1024/_srcH, c_white, 1);

                            // Red "generating" overlay at low alpha
                            draw_set_color(c_red);
                            draw_set_alpha(0.15);
                            draw_rectangle(0, 0, 1024, 1023, 0);
                            draw_set_alpha(1);
                            draw_set_color(c_white);

                            // Progress bar
                            var _prog = clamp((renderF + (strandCount / max(strandSet, 1))) / (sets + 1), 0, 1);
                            draw_set_color(make_color_rgb(20, 20, 20));
                            draw_rectangle(20, 1000, 820, 1014, 0);
                            draw_set_color(make_color_rgb(80, 220, 120));
                            draw_rectangle(20, 1000, 20 + 800 * _prog, 1014, 0);
                            draw_set_color(c_white);
                            draw_set_font(-1);
                            draw_text(20, 980, "Generating... set " + string(renderF + 1) + " of " + string(sets + 1) + " | " + string(strandCount) + " strands");
                            surface_reset_target();
                        }
                    }
                } // End strand loop

                // Final viewport update for completed set
                // Same slice as the progress blit, without the tint or the bar.
                var _activeCanvas;
                if      (doColor  and color_GenState   == 1) _activeCanvas = color_canvas;
                else if (doRGB    and rgbMask_GenState == 1) _activeCanvas = canvas;
                else if (doDepth  and depth_GenState   == 1) _activeCanvas = depth_canvas;
                else if (doMask   and mask_GenState    == 1) _activeCanvas = mask_canvas;
                else if (doNorm   and norm_GenState    == 1) _activeCanvas = nm_canvas;
                else if (doID     and id_GenState      == 1) _activeCanvas = id_canvas;
                else if (doFlow   and flow_GenState    == 1) _activeCanvas = flow_canvas;
                else if (doAO     and ao_GenState      == 1) _activeCanvas = ao_canvas;
                else if (doFrizz  and frizz_GenState   == 1) _activeCanvas = frizz_canvas;
                else                                         _activeCanvas = canvas;

                if (surface_exists(_activeCanvas)) {
				    var _srcW = 2048;
				    var _srcH = 4096;  // ← add this
				    var _srcX = clamp(setXpos - (_srcW * 0.5), 0, 4096 - _srcW);
				    surface_set_target(application_surface);
				    draw_clear(c_black);
				    draw_surface_part_ext(_activeCanvas, _srcX, 0, _srcW, _srcH, 0, 0, 1024/_srcW, 1024/_srcH, c_white, 1);
				    draw_set_color(c_white);
				    surface_reset_target();
				}

                // Set complete - advance to next frame
                // If sets remain, return NOW. doOnce is still true and retrigger
                // is set again, so the next step re-enters and draws set renderF.
                // Everything below this block therefore runs once, after the
                // last set. (The colour-write state set above stays as it is.)
                renderF++;
                if (renderF <= sets) {
					xxx = (1024 / 11) * h
                    retrigger = true;
                    return;
                }
            } // End sets block

            // -----------------------------------------------------------------
            // FINISHING - runs once, after the last set
            // -----------------------------------------------------------------

            // Final blue overwash for the Flow map if applicable
            // Vector-mode flow map with the Blue option on: ADD 128 to the blue
            // channel of the whole 4096 canvas (strands were drawn with B = 0),
            // background included. Additive blend, so R and G are untouched.
            // Blend mode is put back to bm_normal afterwards.
            if (dirBlue == 1 and !dirHue and doFlow == 1 and flow_GenState == 1) {
                surface_set_target(flow_canvas);
                gpu_set_blendmode(bm_add);
                draw_set_color(make_color_rgb(0, 0, 128));
                draw_rectangle(0, 0, 4095, 4095, 0);
                if (f == 0) { surfData = surfData + "_" + string(surface_get_target()); }
                surface_reset_target();
                gpu_set_blendmode(bm_normal);
                draw_set_color(c_white);
                if (doLogOnce == 1) { file_text_write_string(logFile, "ADD blue over Flowmap"); file_text_writeln(logFile); }
            }

            retrigger = false;
            j = 0; h = 0;
            canSave = true;

            // Transition GenStates to 'Complete' (State 2)
            // State 2 is what Draw_0 checks before showing a map as up to date.
            // Editing a setting elsewhere drops a map back from 2 to 1, which is
            // what makes the next Generate redraw it.
            if (rgbMask_GenState == 1) rgbMask_GenState = 2;
            if (norm_GenState == 1) norm_GenState = 2;
            if (color_GenState == 1) color_GenState = 2;
            if (mask_GenState == 1) mask_GenState = 2;
            if (id_GenState == 1) id_GenState = 2;
            if (depth_GenState == 1) depth_GenState = 2;
            if (flow_GenState == 1) flow_GenState = 2;
            if (ao_GenState == 1) ao_GenState = 2;
            if (frizz_GenState == 1) frizz_GenState = 2;
			imgOverride = -1; // release override, return to normal img
            renderF = 0;
            pleaseGen = false;

        } // End retrigger

        // Reached only when the render has finished, or when doOnce was set but
        // there was nothing to draw. Disarms the renderer until the next Generate.
        doOnce = false;
        if (doLogOnce == 1) { file_text_close(logFile); doLogOnce = 2; }
    } // End doOnce
}