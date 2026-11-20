/// @description Step 2
// You can write your code in this editor
// draw color highlights
// -----------------------------------------------------------------------------
// EVENT : End Step (Step_2). Last logic event of the frame, after the key events
//         and Step_0, before Draw_0.
// DOES  : 1. canvasCheck(): re-create any lost surface; also captures the manual
//            save path for Alarm 1 (v185ManualSavePath)
//         2. older in-frame copy of the per-set colour save (S) and load (L).
//            Alarm 1 does the same work one or two frames later and is the
//            version that is certain to run - see the notes on each block
//         3. colour picking for the active slot (background / A / B / root /
//            tip): Alt+right-click eyedropper anywhere, or left-drag in the
//            palette. Writes custom*, which Step_0 routes NEXT frame
//         4. autosave on left mouse release
//         5. doMainStep(): autoload, pre-random refresh, and the incremental
//            4K render (one set per frame while a render is running)
// READS : *_active flags (set by Step_0), fileCustom, mainS, renderF.
// WRITES: colrBack, custom*, newColor, getColorPick, color_GenState,
//         colorOnlyUpdate, forceUpdate, previewCanvasComplete, and on S / L the
//         global* / set* colour arrays and mainS.
// -----------------------------------------------------------------------------
debugMsg="End Step"
canvasCheck()

// -----------------------------------------------------------------------------
// V1.85 PER-SET COLOUR PERSISTENCE SAFETY FOR MANUAL SAVE / LOAD
//
// Per-set colour data belongs to project format 1.85 and later only.
// Older project files remain valid, but their four legacy colours are treated
// as global colours and all per-set colour override flags are cleared.
// -----------------------------------------------------------------------------

// Manual SAVE: append the true globals plus all per-set colour values/flags.
// This is deliberately authoritative because customCol* may currently expose a
// selected set rather than the project's true global colour.
// STATUS OF THIS BLOCK: it is the original 1.85 implementation. The S-key event
// (KeyPress_83) ends with keyboard_key_release(ord("S")), and object g's Begin
// Step comment says the save is latched there "before KeyPress_83 forcibly
// releases S" - i.e. by End Step this keyboard_check_pressed test is not
// expected to be true any more, and Alarm 1 (MANUAL SAVE) appends the block
// instead. Not confirmed by running it. If it ever does fire as well, the file
// simply gets two colour blocks and the loader uses the first one it finds.
// Unlike Alarm 1 this copy does NOT write the clump or "Set Extras" blocks.
// Block layout (must match the readers here and in Alarm 1): marker line, four
// global* lines, then for each set 0..10 eight lines: A flag, A, B flag, B,
// root flag, root, tip flag, tip. Values are GameMaker colour numbers (BGR
// packed into one integer), written as "name:value;".
if keyboard_check_pressed(ord("S")) and fileCustom!="" and file_exists(fileCustom) and !autosaving
	{
	var _v185ColourFile=file_text_open_append(fileCustom)
	if _v185ColourFile!=-1
		{
		file_text_write_string(_v185ColourFile,"V1.85 - Per Set Colour Overrides")
		file_text_writeln(_v185ColourFile)
		
		file_text_write_string(_v185ColourFile,"globalColVarA:"+string(globalColVarA)+";")
		file_text_writeln(_v185ColourFile)
		file_text_write_string(_v185ColourFile,"globalColVarB:"+string(globalColVarB)+";")
		file_text_writeln(_v185ColourFile)
		file_text_write_string(_v185ColourFile,"globalRootCol:"+string(globalRootCol)+";")
		file_text_writeln(_v185ColourFile)
		file_text_write_string(_v185ColourFile,"globalTipCol:"+string(globalTipCol)+";")
		file_text_writeln(_v185ColourFile)
		
		for (var _v185SaveSet=0;_v185SaveSet<11;_v185SaveSet++)
			{
			file_text_write_string(_v185ColourFile,"setColVarAOverrode["+string(_v185SaveSet)+"]:"+string(setColVarAOverrode[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setColVarA["+string(_v185SaveSet)+"]:"+string(setColVarA[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setColVarBOverrode["+string(_v185SaveSet)+"]:"+string(setColVarBOverrode[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setColVarB["+string(_v185SaveSet)+"]:"+string(setColVarB[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setRootColOverrode["+string(_v185SaveSet)+"]:"+string(setRootColOverrode[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setRootCol["+string(_v185SaveSet)+"]:"+string(setRootCol[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setTipColOverrode["+string(_v185SaveSet)+"]:"+string(setTipColOverrode[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			file_text_write_string(_v185ColourFile,"setTipCol["+string(_v185SaveSet)+"]:"+string(setTipCol[_v185SaveSet])+";")
			file_text_writeln(_v185ColourFile)
			}
		
		file_text_close(_v185ColourFile)
		}
	}

// Manual LOAD: the legacy loader has already read mainS by End Step. Only a
// file whose project header is 1.85+ is permitted to restore per-set colours.
// STATUS OF THIS BLOCK: same story as the save block above. KeyPress_76 ends with
// keyboard_key_release(ord("L")), and the load is redone properly by Alarm 1
// (MANUAL LOAD + AUTOLOAD) on the next frame, which reads the version from the
// file itself and also restores the clump and extras blocks. Whatever this block
// sets, Alarm 1 overwrites.
// One trap if this block is ever relied on: for a pre-1.85 file Step_0 has
// already replaced mainS with the current header earlier this frame, so the
// version read on the next line would be the current one, not the file's.
// How the reader works: scan line by line for the marker text, then read the
// fixed sequence of lines after it. analiseString() returns the text between
// ':' and the final ';'.
if keyboard_check_pressed(ord("L")) and fileCustom!="" and file_exists(fileCustom)
	{
	var _v185LoadedProjectVersion=real(string_copy(mainS,46,4))
	var _v185ReadFile=file_text_open_read(fileCustom)
	var _v185FoundColourBlock=0
	var _v185Line=""
	
	if _v185ReadFile!=-1 and _v185LoadedProjectVersion>=1.85
		{
		while !file_text_eof(_v185ReadFile) and _v185FoundColourBlock==0
			{
			_v185Line=file_text_read_string(_v185ReadFile)
			file_text_readln(_v185ReadFile)
			
			if _v185Line=="V1.85 - Per Set Colour Overrides"
				{
				_v185FoundColourBlock=1
				}
			}
		
		if _v185FoundColourBlock==1
			{
			_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); globalColVarA=real(analiseString(_v185Line))
			_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); globalColVarB=real(analiseString(_v185Line))
			_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); globalRootCol=real(analiseString(_v185Line))
			_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); globalTipCol=real(analiseString(_v185Line))
			
			for (var _v185LoadSet=0;_v185LoadSet<11;_v185LoadSet++)
				{
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setColVarAOverrode[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setColVarA[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setColVarBOverrode[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setColVarB[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setRootColOverrode[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setRootCol[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setTipColOverrode[_v185LoadSet]=real(analiseString(_v185Line))
				_v185Line=file_text_read_string(_v185ReadFile); file_text_readln(_v185ReadFile); setTipCol[_v185LoadSet]=real(analiseString(_v185Line))
				}
			}
		}
	
	if _v185ReadFile!=-1 file_text_close(_v185ReadFile)
	
	// Any file below 1.85, or a 1.85+ file without the colour block, falls back
	// to the four legacy/global colours and has no per-set colour overrides.
	if _v185FoundColourBlock==0
		{
		globalColVarA=customColVarA
		globalColVarB=customColVarB
		globalRootCol=customRootCol
		globalTipCol=customTipCol
		
		for (var _v185LegacySet=0;_v185LegacySet<maxSets;_v185LegacySet++)
			{
			setColVarA[_v185LegacySet]=globalColVarA
			setColVarB[_v185LegacySet]=globalColVarB
			setRootCol[_v185LegacySet]=globalRootCol
			setTipCol[_v185LegacySet]=globalTipCol
			setColVarAOverrode[_v185LegacySet]=0
			setColVarBOverrode[_v185LegacySet]=0
			setRootColOverrode[_v185LegacySet]=0
			setTipColOverrode[_v185LegacySet]=0
			}
		}
	
	// Sets beyond the currently saved 11 are not user-visible, but keep their
	// state sane if maxSets is increased later.
	for (var _v185ExtraSet=11;_v185ExtraSet<maxSets;_v185ExtraSet++)
		{
		setColVarA[_v185ExtraSet]=globalColVarA
		setColVarB[_v185ExtraSet]=globalColVarB
		setRootCol[_v185ExtraSet]=globalRootCol
		setTipCol[_v185ExtraSet]=globalTipCol
		setColVarAOverrode[_v185ExtraSet]=0
		setColVarBOverrode[_v185ExtraSet]=0
		setRootColOverrode[_v185ExtraSet]=0
		setTipColOverrode[_v185ExtraSet]=0
		}
	
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
	
	if bkCol_active==1   newColor=colrBack
	if ColA_active==1    newColor=customColVarA
	if ColB_active==1    newColor=customColVarB
	if RootCol_active==1 newColor=customRootCol
	if TipCol_active==1  newColor=customTipCol
	
	colorOnlyUpdate=1
	previewCanvasComplete=0
	forceUpdate=1
	
	// The loaded header was needed for compatibility checks above. From this
	// point onward this running 1.95 build saves projects as the current format.
	mainS="Hair Strand Designer - Project File - Version1.97.0 - 20thNov2026 (C) Robert Ramsay"
	}

// -----------------------------------------------------------------------------
// COLOUR PICKING FOR THE ACTIVE SLOT
// Five near-identical blocks, one per slot (background, A, B, root, tip). Only
// the slot whose *_active flag is 1 runs (Step_0 guarantees exactly one).
// Each has two ways to pick:
//   a) EYEDROPPER: hold Alt and right-click anywhere except the set panel strip
//      under the preview (x 0..1024, y 1024..1080).
//   b) PALETTE: left button held inside the palette picture (x 1644..1899,
//      y 542..720) or the thin strip below it (y 743..753). Fires every frame
//      of a drag.
// Both read the pixel under the mouse straight off the screen with
// draw_getpixel(), which is why a loaded palette image (F9) or anything else on
// screen can be sampled. draw_getpixel returns what was drawn LAST frame, and it
// is slow - fine for a click or a drag, do not call it more widely.
// device_mouse_raw_x/y are window pixels, not room pixels.
// After a pick:
//   color_GenState 2 -> 1   the finished 4K colour map is stale; re-render on G
//   colorOnlyUpdate / forceUpdate   ask the preview to refresh (colour only)
// The value goes into custom* (or colrBack). Step_0 sees "custom != last" on
// the next frame and stores it into the global or the selected set.
// -----------------------------------------------------------------------------
if bkCol_active==1
	{
		if keyboard_check(vk_alt) and mouse_check_button_pressed(mb_right)  and !( mouse_x>=0 and mouse_x<1024 and mouse_y>1024 and mouse_y<1080) // set panel area excluded
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			colrBack=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 

	if mouse_x>=1644 and mouse_x<=1899 and ( (mouse_y>=542 and mouse_y<=720) or (mouse_y>=743 and mouse_y<=753))
	// in palette?
		{
		if mouse_check_button(mb_left)
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			colrBack=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
		}
	}

// AUTOSAVE ON RELEASE. Any left-button release anywhere writes Autosave.txt
// (doAutoSave checks canSave, demoMode and the autosave switch itself).
// Side effect to know about: doAutoSave sets fileCustom="Autosave.txt". After a
// manual save the release of the file-dialog click lands here, which is why
// canvasCheck() copies the real project path into v185ManualSavePath first.
// doMainStep() below has its own release-triggered autosave as well.
if mouse_check_button_released(mb_left)
	{
		doAutoSave()
	}


if ColA_active==1 
	{

	if keyboard_check(vk_alt)  and mouse_check_button_pressed(mb_right) and!( mouse_x>=0 and mouse_x<1024 and mouse_y>1024 and mouse_y<1080) // set panel area excluded
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customColVarA=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
	if mouse_x>=1644 and mouse_x<=1899 and ( (mouse_y>=542 and mouse_y<=720) or (mouse_y>=743 and mouse_y<=753))
		{
		if mouse_check_button(mb_left)
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customColVarA=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
		}
	}
	
if ColB_active==1 
	{
			if keyboard_check(vk_alt)  and mouse_check_button_pressed(mb_right) and !( mouse_x>=0 and mouse_x<1024 and mouse_y>1024 and mouse_y<1080) // set panel area excluded
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customColVarB=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
	if mouse_x>=1644 and mouse_x<=1899 and ( (mouse_y>=542 and mouse_y<=720) or (mouse_y>=743 and mouse_y<=753))
		{
		if mouse_check_button(mb_left)
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customColVarB=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
		}
	}

if RootCol_active==1 
	{
	if keyboard_check(vk_alt)  and mouse_check_button_pressed(mb_right) and  !( mouse_x>=0 and mouse_x<1024 and mouse_y>1024 and mouse_y<1080) // set panel area excluded
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customRootCol=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 


	// (leftover highlight draw. This is a Step event, so nothing drawn here
	// reaches the screen - Draw_0 clears and redraws everything afterwards.)
	draw_sprite(spr_colHL,0,1566,550+128)
if mouse_x>=1644 and mouse_x<=1899 and ( (mouse_y>=542 and mouse_y<=720) or (mouse_y>=743 and mouse_y<=753))
		{
		if mouse_check_button(mb_left)
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customRootCol=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
		}
	}

if TipCol_active==1 
	{
				if keyboard_check(vk_alt) and mouse_check_button_pressed(mb_right) and  !( mouse_x>=0 and mouse_x<1024 and mouse_y>1024 and mouse_y<1080) // set panel area excluded
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customTipCol=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			}
	// (leftover highlight draw - see the note in the root block)
	draw_sprite(spr_colHL,0,1566,550+192)
	if mouse_x>=1644 and mouse_x<=1899 and ( (mouse_y>=542 and mouse_y<=720) or (mouse_y>=743 and mouse_y<=753))
		{
		if mouse_check_button(mb_left)
			{
			if color_GenState==2 {color_GenState=1;}
			getColorPick=draw_getpixel(device_mouse_raw_x(0), device_mouse_raw_y(0))
			customTipCol=getColorPick
			newColor=getColorPick
			colorOnlyUpdate=1
			previewCanvasComplete=0
			forceUpdate=1
			} 
		}
	}

// The final renderer still consumes the original custom colour variables.
// Feed it the colour set for the batch currently being rendered, then restore
// the UI-facing colours immediately afterwards.
// renderF is the set doMainStep will render this frame (0..10; it advances one
// set per frame during a render). doMainStep reads customColVarA/B, customRootCol
// and customTipCol inside its strand loop, so they are pointed at set renderF's
// colours for the duration of the call.
// renderF is 0 when no render is running, so the swap also happens (harmlessly,
// to set 0's colours) on every idle frame. The restore afterwards is what keeps
// that from leaking into the UI - do not return early between the two blocks.
// The background colour (colrBack) is not per-set and is not swapped.
var _uiColVarA=customColVarA
var _uiColVarB=customColVarB
var _uiRootCol=customRootCol
var _uiTipCol=customTipCol
var _swapRenderColours=(renderF>=0 and renderF<11)

if _swapRenderColours
	{
	customColVarA=setColVarA[renderF]
	customColVarB=setColVarB[renderF]
	customRootCol=setRootCol[renderF]
	customTipCol=setTipCol[renderF]
	}

doMainStep()

if _swapRenderColours
	{
	customColVarA=_uiColVarA
	customColVarB=_uiColVarB
	customRootCol=_uiRootCol
	customTipCol=_uiTipCol
	}