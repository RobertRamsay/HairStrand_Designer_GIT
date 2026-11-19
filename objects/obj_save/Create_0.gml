/// @description obj_save: early project saver (not used)
// You can write your code in this editor

// =============================================================================
// OBJECT obj_save  -  the FIRST version of the project saver.  NOT USED.
//
// Nothing creates it: it is in no room, and the only instance_create calls for
// it (obj_surfaceDweller KeyPress_83, KeyPress_86 and doAutoSave) are all
// commented out. So neither of its events runs in the current program.
//
// How projects are really saved today:
//   S key / Save buttons -> obj_surfaceDweller KeyPress_83 writes the file,
//                           then Alarm_1 appends the V1.85 colour, V1.96
//                           Clumping and V1.96 Set Extras blocks.
//   autosave             -> doAutoSave() writes Autosave.txt in
//                           %LOCALAPPDATA%\HairStrand_Designer.
//   loading              -> KeyPress_76 (L key) or doAutoLoad(), then Alarm_1.
//   The file format is described at the top of scripts/doAutoSave.
//
// What this object would do if it were created: its Step event opens a save
// dialog EVERY step and writes a file holding only the header line, the
// instruction line and the Seed. That file could not be loaded as a project.
// Do not re-enable it as it stands.
//
// The two strings below are copies of the same values in obj_surfaceDweller's
// Create. Changing them here changes nothing; the header text that matters is
// in obj_surfaceDweller Create_0, objects/g, Alarm_1 and doAutoSave.
//
// The commented-out list underneath is the original plan of which variables
// to save. It is out of date; the real list is the write order in KeyPress_83
// and doAutoSave. Note this block comment is never closed, so it runs to the
// end of the file: anything added below it is commented out as well.
// =============================================================================

mainS ="Hair Strand Designer - Project File - Version1.96.0 - 9thNov2026 (C) Robert Ramsay"
instr="Variable description (colon : ) VariableValue (semiColon ;)";


// get all the main variables together for saving
/*
var_blur_amount
idMode
doRGB
doNorm
doColor
doMask
doID
doDepth
doFlow
doAO
generating
img
dirFlipX=0
dirFlipY=0
dirBlue=0
dirHue=0
scaleIn
scaleOut
fadeIn
fadeOut
makeRandom
seedVal
colrBack // for colors these can be stored as hex
colrCustom
customColVarA
customColVarB
customRootCol
customTipCol
for (s=0;s<10;s++) // support up to 10 sets potentaill greater later on
	{
	strandCountOverride[s]
	strandLengthOverride[s]
	}
minScale
maxScale
colorMode
tapering
root
tip
lifeVariant
rootPosition
tipPosition
wavyness
strands
diminish
maxStrands
distancings
setDistance
currentMapPreview



