// =============================================================================
// V1.96 HELPER TIPS
//
// One table of "hover here -> show this" for every button and slider row, so
// each control explains itself in the tip area on the bottom bar. It is called
// once per frame from Draw_0, just before that tip is drawn.
//
// A control that already set its own tip earlier in the frame (the map
// toggles, the dice, the clump sliders, the UV loader) keeps it: this only
// fills in when nothing more specific has spoken.
//
// The rectangles are the same ones the click handlers test, so if a button is
// moved, move its line here too.
// =============================================================================

function uiTip(_x1, _y1, _x2, _y2, _text)
{
	if smallTip == "" and point_in_rectangle(mouse_x, mouse_y, _x1, _y1, _x2, _y2) smallTip = _text
}

function uiTips()
{
	if smallTip != "" return
	if firstTime return                    // the splash is up
	if mouse_x < 0 or mouse_y < 0 return

	var _mx = mouse_x, _my = mouse_y

	// ------------------------------------------------------------------
	// BOTTOM BAR
	// ------------------------------------------------------------------
	if _my > 1020
	{
		uiTip(3,   1027, 60,  1051, "Fast mode - previews up to 20 strands per set, for the quickest updates")
		uiTip(66,  1027, 120, 1051, "Med mode - previews up to 50 strands per set")
		uiTip(124, 1027, 180, 1051, "Slow mode - previews up to 100 strands per set, the closest match to the render")
		uiTip(182, 1027, 237, 1051, "Dyna mode - previews up to 30 strands per set")
		uiTip(261, 1027, 331, 1051, "Strand type - SINGLE draws one clean hair per strand, MULTI uses frayed multi-hair sprites. Generated maps only")
		if moreHairs == 1
			uiTip(332, 1027, 346, 1052, "Curl - how much the multi-strand sprites twist along each strand (drag up or down)")
		uiTip(352, 1027, 421, 1051, "Update mode - LIVE redraws as you drag, then grows the strands in. BUSY waits until you let go (the old behaviour)")
		uiTip(428, 1027, 497, 1051, "Smoothing - SMOOTH runs a realtime shader that cleans up the stepped preview strands. RAW shows them as drawn. Preview only")
		uiTip(846, 1027, 901, 1051, "Help - show or hide the keyboard shortcut and help panel")
		uiTip(906, 1027, 963, 1051, "Blur - softens the generated map you are viewing; hold to keep blurring (B)")
		uiTip(970, 1026, 983, 1062, "UV image opacity - drag up or down to fade the loaded UV image")
		return
	}

	// ------------------------------------------------------------------
	// TOP OF THE PANEL: file buttons and Generate
	// ------------------------------------------------------------------
	if _my < 100
	{
		uiTip(1032, 9,  1077, 51, "Exit Hair Strand Designer (Esc)")
		uiTip(1092, 32, 1128, 68, "Load a project file (L)")
		uiTip(1142, 32, 1178, 68, "Save the project file on its own, without exporting maps")
		uiTip(1333, 9,  1376, 51, "Export every generated map together with the project file (S)")
		uiTip(1175, 67, 1375, 97, "Generate every enabled map at full 4096 resolution (G)")
		return
	}

	// ------------------------------------------------------------------
	// MAP LIST (rows are 27px apart, RGB Mask first)
	// ------------------------------------------------------------------
	if _my < 376 and _mx >= 1024 and _mx < 1380
	{
		var _row = floor((_my - 103) / 27)
		if _row >= 0 and _row <= 9 and _my >= 103
		{
			var _names = ["RGB Mask", "Normal Map", "Mask Map", "Color Map", "ID Map", "Depth Map", "Flow Map", "AO Map", "Frizz Map", "Previewer"]
			var _what  = [
				"variation in red, root in green and tip in blue, for shader tinting",
				"surface normals for lighting the strands",
				"the opacity (alpha) mask of the strands",
				"the strands in your chosen colours",
				"a flat colour per strand or per set, for selecting them in a shader",
				"strand depth as greyscale, for layering and parallax",
				"the direction each strand runs, for anisotropic highlights",
				"ambient occlusion - soft shadowing around the strands",
				"random grey noise along the strands, for frizz or flyaway variation"]

			if _row == 9
				uiTip(1024, 346, 1380, 376, "Previewer - back to the live strand preview (P)")
			else if _mx < 1240
				smallTip = _names[_row] + " - " + _what[_row] + ". Click to view it"
			else if _mx >= 1347 and _mx <= 1370
				smallTip = "Export the " + _names[_row] + " on its own (it must be generated first)"
			else if _row == 7 and _mx >= 1268 and _mx <= 1350 and _my >= 290 and _my <= 310
				smallTip = "AO width - click to step through Thin, Default, Wide and Extreme. Right-click steps back"
		}
		return
	}

	// ------------------------------------------------------------------
	// FLOW / ID MODE BUTTONS
	// ------------------------------------------------------------------
	if _my >= 386 and _my <= 410
	{
		uiTip(1050, 389, 1100, 408, "Flow map - flip the left/right direction")
		uiTip(1104, 389, 1154, 408, "Flow map - flip the up/down direction")
		uiTip(1158, 389, 1208, 408, "Flow map - fill the blue channel, for a tangent-space style map")
		uiTip(1214, 389, 1264, 408, "Flow map - show direction as hue instead of red and green")
		uiTip(1272, 389, 1376, 408, "ID map - switch between one colour per strand and one colour per set")
		return
	}

	// ------------------------------------------------------------------
	// SLIDER ROWS (28px apart, Strands first). Clumping has its own tips.
	// ------------------------------------------------------------------
	if _mx >= 1036 and _mx <= 1380 and _my >= 422 and _my < 954
	{
		var _r = floor((_my - 422) / 28)
		var _over = "  Select a set to override it"
		switch (_r)
		{
			case 0:  smallTip = "Strands - how many strands each set has (the render draws up to 100 per set)." + _over; break
			case 1:  smallTip = "Length - how long the strands are." + _over; break
			case 2:  smallTip = "Spacing - how wide the roots of a set are spread." + _over; break
			case 3:  smallTip = "Distance - the gap between one set and the next"; break
			case 4:  smallTip = "Waviness - how far each strand waves from side to side." + _over; break
			case 5:  smallTip = "Wave Freq - the slowest (Min) and fastest (Max) wave a strand can be given." + _over; break
			case 6:  smallTip = "Tapering - draws the strands in toward the middle of their set." + _over; break
			case 7:  smallTip = "Variation - how much the strands of a set differ in length." + _over; break
			case 8:  smallTip = "Root Jitter - staggers where each strand starts, so the roots are not in a straight line." + _over; break
			case 9:  smallTip = "Thick Rng - the thinnest (Min) and thickest (Max) a strand can be." + _over; break
			case 10: smallTip = "Thick Adj - shapes the thickness toward the root and toward the tip." + _over; break
			case 11: smallTip = "Thick Var - how much thickness differs from one strand to the next." + _over; break
			case 12: smallTip = "Fading - how gradually a strand fades in at the root and out at the tip." + _over; break
			case 13: smallTip = "Noise - makes each strand wander: Amount is how far, Freq is how often." + _over; break
			case 14:
			case 15:
			case 16:
				if _mx < 1190 smallTip = "Mixer " + string(_r - 13) + " - click the name to edit this mixer's curve (F8)"
				else smallTip = "Mixer " + string(_r - 13) + " - Amount is how strongly its curve bends the strands, Offset slides it along them." + _over
				break
			case 17: smallTip = "Clumping - gathers a set into tresses: Amount is how tightly, Count is how many." + _over; break
			case 18: smallTip = "Clump Var - Start is how far down clumping begins, Scatter loosens strands." + _over; break
		}
		return
	}

	// ------------------------------------------------------------------
	// SEED
	// ------------------------------------------------------------------
	uiTip(1200, 983, 1324, 1012, "Seed - press F1 to type a seed number. With a set selected it changes that set only")

	// ------------------------------------------------------------------
	// COLOUR AREA
	// ------------------------------------------------------------------
	if _mx >= 1390
	{
		uiTip(1568, 541, 1632, 564, "Background colour - behind the strands in the previewer and the Color Map. Click to edit")
		uiTip(1568, 568, 1632, 590, "Variation Tone 1 - one of the two colours the strands are blended between. Click to edit")
		uiTip(1568, 594, 1632, 618, "Variation Tone 2 - the other colour each strand is blended between. Click to edit")
		uiTip(1568, 621, 1632, 645, "Root Tone - the colour at the root of the strands. Click to edit")
		uiTip(1568, 649, 1632, 671, "Tip Tone - the colour at the tip of the strands. Click to edit")
		uiTip(1516, 676, 1628, 696, "Root Coverage - how far down the strand the root tone reaches")
		uiTip(1516, 697, 1628, 714, "Tip Coverage - how far up from the end the tip tone reaches")
		uiTip(1519, 715, 1632, 736, "Hex colour - click to type a six-digit hex value for the selected tone")
		uiTip(1465, 763, 1606, 816, "Colour finetuner - nudge the selected tone one channel at a time")
		uiTip(1473, 820, 1596, 839, "Finetuner mode - work in RGB, HSV or grey")
		uiTip(1644, 542, 1899, 722, "Colour picker - click or drag to choose the selected tone")
		uiTip(1650, 742, 1894, 755, "Colour history - click a swatch to reuse an earlier colour")
		uiTip(1656, 758, 1887, 792, "Old and New - the selected tone before and after your change")
	}
}
