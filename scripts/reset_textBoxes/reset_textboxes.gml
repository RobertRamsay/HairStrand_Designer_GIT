/// reset all other text boxes
// -----------------------------------------------------------------------------
// reset_textBoxes()  -  close every numeric text box
//
// Each slider has a small number box you can click and type into. While a box
// is being typed in, its textBox_<name> flag is 1 and Draw_0 routes the
// keyboard to it; any other value means "not being edited".
// This sets them all to "not being edited". Runs in obj_surfaceDweller's scope.
//
// Called from Draw_0 whenever a box is opened (so only one is ever open) and
// when a slider is grabbed, and from obj_copy after a PASTE so a box that was
// open cannot write its old number over the pasted value.
//
// It does NOT touch the textBox_<name>_value strings (the text shown in the
// boxes), only the "is open" flags.
//
// ADDING A SLIDER WITH A TEXT BOX: add its textBox_ flag here, or it will stay
// open when another box is opened or a slider is dragged.
//
// Odd spot: textBox_minScale and textBox_maxScale are set to 2, not 0 (Create
// starts them at 2 as well). Draw_0 tests "== 1" for open, so 2 still means
// closed. Reason for the 2 not known.
// -----------------------------------------------------------------------------
function reset_textBoxes() {

	textBox_diminish=0
	textBox_distancings=0
	textBox_fadeIn=0
	textBox_fadeOut=0
	textBox_frizz=0
	textBox_lifeVariant=0
	textBox_maxFreq=0
	textBox_maxScale=2
	textBox_minFreq=0
	textBox_minScale=2
	textBox_mixer1=0
	textBox_mixer1_offset=0
	textBox_mixer2=0
	textBox_mixer2_offset=0
	textBox_mixer3=0
	textBox_mixer3_offset=0
	textBox_noiseAmt=0
	textBox_noiseFreq=0
	textBox_clump=[0,0,0,0] // V1.96 CLUMPING
	textBox_overrideCount=0
	textBox_overrideLength=0
	textBox_rootThick=0
	textBox_setDistance=0
	textBox_strands=0
	textBox_tapering=0
	textBox_thickVary=0
	textBox_tipThick=0
	textBox_wavyness=0
	textBox_length=0
	textBox_YRanRange=0
	
	
	


}
