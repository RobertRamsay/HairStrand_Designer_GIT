/// @description Step 2 
// You can write your code in this editor
// draw color highlights
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
	// point onward this running 1.94 build saves projects as the current format.
	mainS="Hair Strand Designer - Project File - Version1.94.0 - 26thAug2026 (C) Robert Ramsay"
	}

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