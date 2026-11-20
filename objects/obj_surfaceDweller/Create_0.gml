// =============================================================================
// CREATE EVENT - obj_surfaceDweller          (the variable reference for HSD)
//
// EVENT : Create. Runs once at start-up and again after every game_restart()
//         (F6, or the automatic restart after a second surface loss in Step_1).
//         The object is persistent, so it is NOT re-created when the room
//         changes to the path editor and back.
// DOES  : declares nearly every variable the program uses, creates the surfaces,
//         builds the sin/cos lookup table and fills the pre-random tables.
// NOT HERE: the per-set COLOUR arrays (global* / set* / colourUiLast*,
//         colourSelectedSlot) are created lazily by Step_0 on the first frame;
//         hCol[] / colorHistoryPointer by setupCanvases(); the preRand* tables
//         by updatePreRands(); the slider_interract_* flags by
//         nullify_sliderInterracts(); the v185* flags by object g / Alarm 1.
//
// CONVENTIONS USED THROUGHOUT
//   SETS        11 strand sets, index 0..10. "sets" is 10 (the LAST index), so
//               loops are written "<= sets" or "< sets+1" or "< 11".
//               maxSets (15) is only the size the per-set arrays are created
//               with; slots 11..14 exist but are never shown.
//   STRANDS     at most 100 per set - the size of every per-strand table.
//   CANVAS      final maps are 4096x4096 (surfSize). The on-screen preview is
//               1024x1024, i.e. canvas coordinates * 0.25.
//   SCREEN      UI coordinates are pixels on a fixed 1920x1080 layout.
//   SLIDERS     most "notched" sliders run 0..40.
//   OVERRIDES   each per-set setting is a PAIR of arrays:
//                 <name>Overrode[set]  1 = this set has its own value
//                                      0 = it follows the global slider
//                 <name>Adj[set] (or strandCountOverride / strandLengthOverride
//                                 / strandYRanRange) = the value actually used
//               The value array is ALWAYS filled in: moving a global slider
//               writes through to every set whose flag is 0. The calc scripts
//               (doCalc, doMainStep, previewJob) read only the per-set value.
//               A new override therefore has to be added in: here, Step_1
//               (F4 and F5 resets), clearOverrides(), the save and load code,
//               obj_copy (copy/paste) and previewSetSig() (so the preview
//               notices the change).
//   LEGACY      this file has grown since 2020. Variables marked "unused" or
//               "legacy" below were checked: nothing else in the project reads
//               them. They are left in place deliberately.
//
// SECTION ORDER (search for the banner text)
//   APP / WINDOW / UI SWITCHES      PREVIEW SURFACES + REDRAW REQUESTS
//   SIN/COS LOOKUP TABLE            START-UP + SURFACE-LOSS RESTART
//   AO                              MISC STATE
//   AUTOSAVE / AUTOLOAD / SPLASH    PREVIEW UPDATE + CALIBRATION
//   MIXER PATHS                     SET SELECTION / DRAGGING
//   UI COLOURS                      PER-SET OVERRIDE FLAGS (first group)
//   BLUR SHADER                     PROJECT NAME / RENDER FLAGS / MAP STATES
//   ID COLOURS, FLOW MAP OPTIONS    STRAND SHAPE GLOBALS, NOISE, CLUMPING
//   PROGRESSIVE PREVIEW (pv*)       SEEDS, PREVIEW QUALITY
//   COLOUR SLOT FLAGS               PER-SET ARRAYS (main group)
//   COLOURS                         THICKNESS, GENERAL STRAND GLOBALS
//   CANVASES (surfaces)             TEXT BOXES
//   FILE SAVE                       LEGACY PER-STRAND CACHE
//   FLYAWAY PATHS                   FINAL SET-UP
// =============================================================================
draw_set_color(c_white);

// -----------------------------------------------------------------------------
// APP / WINDOW / UI SWITCHES
// -----------------------------------------------------------------------------
// demoMode: build switch. 1 = DEMO build: manual save (KeyPress_83), autosave
// (doAutoSave) and the colour autosave are all disabled. Set by hand before
// compiling the demo (see the release recipe). demoInfo is the label Draw_0 shows.
demoMode=0 // for DEMO mode
demoInfo="DEMO (no save options)"
// Shown in the title line (Draw_64). NOT the project-file format version - that
// lives in the mainS header string further down and is changed separately.
versionHSD="1.96.0.0"

showHeart=0 // 1 = draw the heart in Draw_0. Toggled by F7 (KeyPress_118)
uiExtras=1 // little dots for overrides.

// canDrawUI: 0 while the splash is up, 1 afterwards. Set by object g (Begin
// Step) as soon as firstTime is false. Gates Draw_64 and obj_copy's buttons.
canDrawUI=0

// Window. topMostMode: 1 = keep the window above all others (F3, fullscreen
// build only). moveWindow: 1 while the window is being dragged by its top strip;
// wmx/wmy = where in the window it was grabbed (Step_1).
// fullscreenMode is a build switch like demoMode: 1 = borderless fullscreen
// build, which starts topmost and has to drop topmost around file dialogs.
topMostMode=0
wmx=0
wmy=0
moveWindow=0
fullscreenMode=0 // for fullscreen mode
if fullscreenMode==1 {window_set_topmost(1);topMostMode=1}

// -----------------------------------------------------------------------------
// PREVIEW SURFACES + REDRAW REQUESTS
// -----------------------------------------------------------------------------
// previewSurf[0..10]: SURFACES, one 1024x1024 transparent layer per set. Each
// set's preview strands are drawn onto its own layer (previewJob) and mainCalc()
// stacks the eleven layers every frame. One layer per set is what lets a single
// set be redrawn without touching the others. Re-created by canvasCheck() if
// lost; freed in CleanUp_0.
for (n=0;n<11;n++)
	{
	previewSurf[n]=surface_create(1024,1024)
	}

// The three "please redraw" flags. All are read and cleared once per frame by
// previewUpdate() (previewJob):
//   forceUpdate=1      redraw every set (after a load, surface loss, text entry)
//   colorOnlyUpdate=1  set together with forceUpdate by the colour code; it
//                      DOWNGRADES the request: only sets whose own values
//                      changed are redrawn
//   seedUpdate=1       (declared further down) a seed changed, redraw every set
// Ordinary slider edits need no flag: the preview compares per-set signatures.
forceUpdate=0 // use this for forcing an update after a text input
renderH=0 // render pointer: strand index within the set. Only ever reset to 0 now
colorOnlyUpdate=0

// -----------------------------------------------------------------------------
// SIN/COS LOOKUP TABLE
// lut_sin / lut_cos: PRE-COMPUTED TABLES (not random, never change after this).
// Index = angle in degrees * 4, wrapped with "mod 1440". Read in the per-point
// loops of doMainStep and previewJob, and by the noise (phases are 0..1440).
// -----------------------------------------------------------------------------
// Sin/cos lookup table — 1440 entries (0.25 degree resolution, full 360 degrees).
// Replaces dsin/dcos/sin(degtorad()) calls in hot inner loops.
// Usage: lut_sin[round(angle_deg * 4) mod 1440]  lut_cos[round(angle_deg * 4) mod 1440]
// Strand thickness shortcuts:
//   dsin(n/life*90)  -> lut_sin[(round(n/life*360)) mod 1440]
//   dcos(n/life*90)  -> lut_cos[(round(n/life*360)) mod 1440]
//   dsin(n/life*180) -> lut_sin[(round(n/life*720)) mod 1440]
//   sin(degtorad(n*freq)) -> lut_sin[(round(n*freq*4)) mod 1440]
lut_sin = array_create(1440, 0)
lut_cos = array_create(1440, 0)
for (var _li=0; _li<1440; _li++) {
	lut_sin[_li] = dsin(_li * 0.25)
	lut_cos[_li] = dcos(_li * 0.25)
}

// -----------------------------------------------------------------------------
// START-UP + SURFACE-LOSS RESTART
// -----------------------------------------------------------------------------
// firstPass: true until previewUpdate() has run once; forces the first full
// preview draw. newPalImg: sprite of the custom palette image loaded with F9,
// -1 = none (not saved with the project).
// previewCanvasComplete: legacy "preview finished" flag. Still written in many
// places (0 on any change, 1 by previewJob / doHighlighting) but nothing reads it.
firstPass=true
newPalImg=-1 // no image
previewCanvasComplete=0
/*
window_set_size(display_get_width(),display_get_height()-90)
window_set_position(0,45)
*/
// sprites to store canvases..
// aoSprite: sprite loaded from "ao.png" (if that file exists) by killSurfaces /
// setupCanvases and stamped onto a freshly cleared ao_canvas. -1 = none.
aoSprite=-1
// maxSets: SIZE of the per-set arrays (slots 0..14). Only 0..10 are real sets.
maxSets=15
// firstTime: true while the splash screen is showing. Goes false when the user
// presses LOAD AUTOSAVE / GET STARTED / Enter on the splash, or G / Generate
// (Draw_0). While true: no preview is drawn, no function-key buttons, and
// F12 does nothing.
// skipIntro: 1 = this run began with the automatic surface-loss restart, so the
// splash is skipped and doMainStep loads Autosave.txt straight away.
// RegenCheck.txt is the one-line note Step_1 leaves in the save folder just
// before that game_restart(); it is read once here and deleted, which is how a
// surface-loss restart is told apart from a normal launch or an F6 restart.
skipIntro=0
firstTime=true; // first loop around for quicksaving
if file_exists("RegenCheck.txt")
	{
	var fileOpen= file_text_open_read("RegenCheck.txt");
	var check=file_text_read_string(fileOpen);
	file_text_readln(fileOpen);
	file_text_close(fileOpen);
	
	if check=="Regen" skipIntro=1
	file_delete("RegenCheck.txt");
	firstTime=false; // first loop around for quicksaving
	}

// -----------------------------------------------------------------------------
// AO (ambient occlusion map)
// aoType 0..3 = the AO width button in Draw_64 (also the frame of spr_but_AO).
// aoExtra = the width factor the renderer uses, looked up from aoType every
// frame in Draw_64: 0 -> 0.75, 1 -> 0.87, 2 -> 1.05, 3 -> 1.6. The 1.55 here is
// replaced as soon as the button is first drawn. Neither is saved in a project.
// -----------------------------------------------------------------------------
aoExtra=1.55
aoType=1

// -----------------------------------------------------------------------------
// MISC STATE
// -----------------------------------------------------------------------------
infoMsg="" // debug text ("Count:n" after a surface loss)
count=0    // surface losses seen this run; the 2nd one triggers the restart (Step_1)

// Real screen size relative to the 1920x1080 layout. Used to convert room pixels
// to desktop pixels when dragging the window (Step_1). Assigned again further
// down (the 1.682 fix) - same values.
screenScaleX =display_get_width()/1920
screenScaleY =display_get_height()/1080


surfData="" // debug string appended to by the renderer's flow-map pass

//window_set_topmost(topMostMode);
// MULTI-STRAND ("more hairs") curl. curlRotator: running rotation accumulated
// along a strand while rendering (working value). curlRotAmt: the micro-curl
// amount 0..1 set by the small vertical control in Draw_0; saved in the project.
curlRotator=0
curlRotAmt=0.5 // 0 .. 1 later x3
flashAlpha=0   // 0..1 pulse for the SOLO marker, derived from gameTick360
gameTick360=0  // frame counter 0..360, advanced in Step_1

// setToSolo: -1 = show all sets; 0..10 = preview only that set (checkAndOffset
// sets it, previewSetSig / doHighlighting read it). Preview only - the final
// render always includes every active set.
setToSolo=-1 // which set should be made solo?
checkSum=0   // counts strands rendered (debug; incremented in doMainStep, never read)
// dynamicRes: 1 = DYNA preview quality (bottom-bar button); see Step_1.
dynamicRes=0
tickytime=0 // 0..1 sawtooth for the text-box caret blink (Step_1)
showHelp=0  // 1 = help panel sprite shown (toggled in Draw_0)
uiKeyHeld=-1   // V1.96 - key being "tapped" by a function-key button, released next frame
// smallTip: the tooltip line. Cleared every Begin Step, rewritten by whatever the
// mouse is over. Tooltip: a second tooltip string (see its uses in Draw_0).
smallTip=""
Tooltip=""

// -----------------------------------------------------------------------------
// AUTOSAVE / AUTOLOAD / SPLASH
// -----------------------------------------------------------------------------
// autosave:   1 = autosaving allowed (a constant switch; nothing turns it off).
// autosaving: 1 while doAutoSave() is writing Autosave.txt (re-entry guard).
// autoloading: 1 = "load Autosave.txt when ready". The splash sets it: LOAD
//             AUTOSAVE leaves it 1, GET STARTED / Enter clear it. doMainStep
//             performs the load and clears it.
// readyToCheckAutoloads: 1 once the splash has been answered. Until then no
//             autoload and no mouse-release autosave can happen.
// alFile:     scratch file handle used when probing Autosave.txt.
autosave=1
autosaving=0
alFile=""
autoloading=1
readyToCheckAutoloads=0

// V1.90 splash screen state.
// -1 = Autosave.txt not probed yet, 0 = none found, 1 = found.
// The splash owns the "load a previous session?" decision now, so the old
// show_question() popup in doMainStep has gone.
splashAutosaveFound=-1

// V1.91 - which set (if any) the pending preview rebuild is limited to.
// -1 = rebuild every set, as before. A per-set slider edit sets this to the
// selected set so mainCalc only clears and redraws that one preview surface.
// (Since V1.96 the progressive preview works out which sets changed by itself;
// localUpdateSet is still set and cleared by Draw_0 / KeyPress_76.
// liveLocalEvery / liveLocalTick are unused now - nothing else reads them.)
localUpdateSet=-1
liveLocalEvery=3   // rebuild the selected set every N frames while dragging
liveLocalTick=3

// Set by the manual (L) loader only when a project file was really read, so a
// cancelled file dialog cannot trigger a full preview rebuild.
v191ManualLoadOk=0

// V1.92 - preview stroke calibration.
// The final render stamps spr_strander (frame 0, ~30px of visible alpha at
// scale 1) at every point on a 4096 canvas. The preview draws lines on a 1024
// canvas, so the matching line width is 30*scA/4 = 7.5*scA. The old constant
// was 5 with an upper clamp of 10, which under-drew every strand by ~1.45x and
// stopped growing entirely past scA 2 - hence "the final looks way thicker".
previewWidthK=7.5

// V1.93 - preview alpha calibration.
// The final render stamps a sprite at EVERY point along the strand, so on any
// one output row roughly 20*scA of them overlap and their alpha compounds:
// the visible opacity is 1-(1-a)^(20*scA), not a. That stays near-solid far
// longer than a does and then collapses, which is why the rendered tip ends
// abruptly. The preview draws ONE non-overlapping segment per sampled point,
// so it has to apply that curve itself.
// The old code instead did clamp(a,0.25,1) - a hard 25% floor, so the preview
// tip never faded out at all. Measured against a real stamped strand the new
// curve is within 0.003 mean opacity; the old clamp was out by 0.10.
previewAlphaK=20
// yRanRange: GLOBAL "root Y jitter" slider. Each strand's start Y is rolled in
// the band -range .. +range*3 (plus 120) by updatePreRands, so a bigger value
// staggers the roots more. Per-set version: strandYRanRange[] +
// strandYRanRangeOverrode[].
yRanRange=20 // new is 1.53

// -----------------------------------------------------------------------------
// MIXER PATHS
// editingPath[0..2] are the three mixer curves (path assets StragglePath_A1 /
// B1 / C1). They are edited in Room_PathEditing (F8), saved point by point in
// the project file, and sampled by mixerCacheBuild() to bend the strands.
// pathLoad?x/y[] (filled in the loop below) hold the point positions read from
// a file until they are applied to these paths.
// -----------------------------------------------------------------------------
editingPath[0]=StragglePath_A1
editingPath[1]=StragglePath_B1
editingPath[2]=StragglePath_C1
//tn=0

// -----------------------------------------------------------------------------
// SET SELECTION / DRAGGING (working state of checkAndOffset and doHighlighting,
// the scripts that handle clicking, soloing and moving sets in the preview)
// -----------------------------------------------------------------------------
// path stuff per cycle
xDiff=0 // set offset minus mouse*4 at the moment a drag starts, so the set
yDiff=0 // keeps its position relative to the cursor while dragged (canvas px)

numSel=0	      // per-frame guard: only the first set under the mouse reacts
setHovveredID=-1// // set under the mouse, -1 = none
clickCount=0

clickedID=-1
held=0   // frames the button has been down on a set; a drag starts after ~0.15s
moving=0 // 1 while a set is being dragged
// bounding box of the set doHighlighting is testing (copied from setBB*[])
leftmost=0
rightmost=0
topmost=0
bottommost=0

// doOnce: render gate. G / Generate sets it true; doMainStep does its render
// work only while it is true and sets it false when the render has finished.
doOnce=true

// moreHairs: 0 = SINGLE STRAND mode, 1 = MULTI STRAND mode (button in Draw_0,
// saved in the project). In multi mode each stamp uses a random sub-image and
// rotation (preRandSubSprite / preRandAngChoice / preRandCurling), the normal
// map is drawn as a bump map and converted with shd_normal, and AO uses
// spr_stranderAO. Changing it changes the pre-random tables.
moreHairs=0 // yes please=1
hoveringNumber=false
debugMsg="" // name of the event/script last entered - a breadcrumb for crashes

// Render log. doLogOnce: 0 would open a LOG__ file on the next G press, 1 = log
// open and being written, 2 = closed. doMainStep sets it to 9 on every G press,
// which matches none of those, so logging is switched OFF. Change that 9 to 0 in
// doMainStep to get a log of a render.
logFile=""
doLogOnce=0

firstCalc=1 // 1 on frames where the left button is down; reset at the end of Draw_0
subSpriteChoice=0 // experimental in v1.43
lastFileName="" // path of the file most recently loaded; Alarm 1 re-opens it
// pre randomize... 1100

normalMapGenerated=0 // unused

normSprite=spr_AOBlack // temp sprite used when exporting the multi-strand normal map
// length: GLOBAL strand length slider, in canvas pixels (one point per pixel
// down the 4096 canvas; individual strands are clamped to 10..3900 points).
// Per-set version: strandLengthOverride[] + setLengthOverrode[].
// (hairLength, further down, is the working copy for the set being drawn:
// the set's length plus its random length offset preRandLifeVariant.)
length=2048
gpu_set_texfilter(1) // turn on filter

// -----------------------------------------------------------------------------
// UI COLOURS (fixed tints for interface elements - nothing to do with the hair
// colours, which are in the COLOURS section)
// -----------------------------------------------------------------------------
or_color=make_color_rgb(200,100,30)
or_editColor=make_color_rgb(160,60,10) // unused

// Text-box / value readout colours. White normally, yellow when the selected
// set overrides that value. or_color is left alone - it still tints the small
// per-set override indicator dots.
tbCol=c_white
tbColOver=make_color_rgb(255,225,60)
blu_color=make_color_rgb(30,130,240)
grn_color=make_color_rgb(30,230,50)
yel_color=make_color_rgb(240,230,20)
pur_color=make_color_rgb(180,80,255)
red_color=make_color_rgb(240,40,60)

// a pre-random list will be needed overall
// for each strand, each type

// -----------------------------------------------------------------------------
// PER-SET OVERRIDE FLAGS (first group) + MIXER PATH LOAD BUFFERS
// Loop index a = 0..14, used two ways at once:
//  - as a PATH POINT index for pathLoadAx/Ay, Bx/By, Cx/Cy: the default point
//    positions, copied from the path assets StragglePath_A / B / C. Only
//    points 0..10 are ever applied (KeyPress_76, doAutoLoad).
//    NOTE these defaults come from StragglePath_A/B/C, while the live mixers
//    are StragglePath_A1/B1/C1 (editingPath).
//  - as a SET index for the selection flags and the original (V1.43-1.53)
//    override flags. Their value arrays are created in the main per-set loop
//    further down.
//      flag                     value array            global slider
//      setLengthOverrode        strandLengthOverride   length
//      setCountOverrode         strandCountOverride    strands
//      setTaperOverrode         strandSetTaperAdj      tapering
//      setWaveynessOverrode     strandSetWavynessAdj   wavyness
//      setWaveFreqMinOverrode   strandSetWaveFreqMinAdj minFreq
//      setWaveFreqMaxOverrode   strandSetWaveFreqMaxAdj maxFreq
//      setVariOverrode          strandSetVariAdj       lifeVariant
//      setSpacingOverrode       strandSetSpaceAdj      distancings
//      strandYRanRangeOverrode  strandYRanRange        yRanRange
// setSelected[set]: 1 = that set is selected in the set panel.
// setSelectedID: the one set being edited, -1 = none = sliders edit the GLOBAL
// values. This single variable decides whether any edit is global or per-set.
// -----------------------------------------------------------------------------

for (a=0;a<maxSets;a++)
	{
	pathLoadAx[a]=path_get_point_x(StragglePath_A,a)
	pathLoadAy[a]=path_get_point_y(StragglePath_A,a)
	pathLoadBx[a]=path_get_point_x(StragglePath_B,a)
	pathLoadBy[a]=path_get_point_y(StragglePath_B,a)
	pathLoadCx[a]=path_get_point_x(StragglePath_C,a)
	pathLoadCy[a]=path_get_point_y(StragglePath_C,a)
	//
	setSelected[a]=0 // no sets are sected for overrides. 1.43
	setSelectedID=-1 // the ID of the selected 1.43
	// override flags (so we know what should be globally affected)
	// can be locally reset or all reset later
	setLengthOverrode[a]=0 // has this been overrode?
	setCountOverrode[a]=0 // has this been overrode? // yes defaults!
	//if a<4 setCountOverrode[a]=1 
	setTaperOverrode[a]=0 // has this been overrode?
	setWaveynessOverrode[a]=0 // has this been overrode?
	setWaveFreqMinOverrode[a]=0 // has this been overrode?
	setWaveFreqMaxOverrode[a]=0 // has this been overrode?
	setVariOverrode[a]=0 // has this been overrode?
	setSpacingOverrode[a]=0 // has this been overrode?

	strandYRanRangeOverrode[a]=0 // has this been overrode?

	}

// exiting: true while the "Are you sure you want to quit? Y / N" box is up
// (Esc or the quit button). Draw_0 draws the box and handles the answer.
exiting=false

// -----------------------------------------------------------------------------
// BLUR SHADER (the B key / BLUR button in Draw_0 blurs the map being viewed)
// uni_* are uniform handles; var_blur_amount is the strength (saved as "Blur").
// var_resolution_x/y and shader_enabled are leftovers from the blur demo object
// (obj_controller_gaussian_blur) - Draw_0 passes 4096,4096 directly.
// CHECK: the two blur_amount handles are fetched from the OPPOSITE shader to
// their name (_hoz from shd_gaussian_vertical, _vert from shd_gaussian_
// horizontal), and Draw_0 uses each with the shader its NAME suggests. That only
// works while "blur_amount" has the same handle in both shaders.
// -----------------------------------------------------------------------------
uni_resolution_hoz = shader_get_uniform(shd_gaussian_horizontal,"resolution");
uni_resolution_vert = shader_get_uniform(shd_gaussian_vertical,"resolution");
var_resolution_x = 4096
var_resolution_y = 2048

uni_blur_amount_hoz = shader_get_uniform(shd_gaussian_vertical,"blur_amount");
uni_blur_amount_vert = shader_get_uniform(shd_gaussian_horizontal,"blur_amount");
var_blur_amount = 0.125;

shader_enabled = true;
/*
c1=c_white
c2=c_white
c3=c_white
c4=c_white
c5=c_white
*/
// -----------------------------------------------------------------------------
// PROJECT NAME / RENDER FLAGS / MAP STATES
// -----------------------------------------------------------------------------
// file: path returned by the last PNG export dialog. prjName: project name, the
// default file name and the prefix of every exported map. projectOnly: set by the
// buttons in Draw_0 just before they fake an S key press - true = save the
// project .txt only, false = also export the finished maps. Reset after each save.
file="";
prjName="HSD_"
projectOnly=false;

dance=0

// fix in 1.682 for grabbing window in 4k
screenScaleX =display_get_width()/1920	
screenScaleY =display_get_height()/1080

previewingUV=false; // unused
tick=0 // 0..360 animation counter, advanced by 4 per frame in Draw_0
changesMade=false // for any algorithm changes made
// ID MAP. idMode 0 = every strand gets the next colour from colorIDarray,
// cycling through entries 0..strandIDsize (so 9 colours); 1 = one colour per set
// (colorIDarray[set]). idList is the running index for mode 0.
idMode=0 // 0 is each strand 1 is each set.
idList=0;
strandIDsize=8 // number of colors used for ID for strands
draw_set_font(regFont)
// pleaseGen: "settings changed since the last render". While true doMainStep
// keeps the render pointers (renderF / renderH) at 0. It does NOT start a
// render - only G / the Generate button does, and that clears it.
pleaseGen=false
doOnce=true
thicknessBase=1
xx1=0 // xx1..yy2: unused apart from being zeroed at the start of a render
yy1=0
xx2=0
yy2=0
// MAP TICK-BOXES (the enable column in Draw_0). do<Map> = 1 means "render this
// map on the next G". Not restored by a project load. Paired with the
// <map>_GenState variables below - read those notes.
// The trailing numbers in the old comments are the img view numbers.
doRGB=false//true
doNorm=false//true
doColor=false//true 4
doMask=false//true
doID=false//true
doDepth=false//true
doFlow=false //true 6
doAO=false  //7
doFrizz=false
// generating: true only on the frame G / Generate is pressed (Draw_0 sets it
// false again at the top of every frame). Not a "render in progress" flag -
// for that, test for a *_GenState of 1 with retrigger true, or renderF > 0.
generating=false//false
// renderF: the set the renderer will draw next, 0..10. doMainStep renders ONE
// set per frame and returns, so the window stays alive; after set 10 it marks
// the maps finished and puts renderF back to 0. Step_2 uses renderF to choose
// which set's colours to feed the renderer.
renderF=0 // incremental render - current set being rendered
// img: what the 1024x1024 viewer shows.
//   0 RGB mask (canvas)   1 normal (nm_canvas)   2 ID (id_canvas)
//   3 depth               4 colour               5 mask
//   6 flow                7 AO                   8 frizz
//   9 the live strand PREVIEWER (the normal working view)
// Keys: R N I D C M F A Z P in that order (KeyPress_82/78/73/68/67/77/70/65/90/80).
// The preview strands are only rebuilt while img==9.
img=9 // previewer default mode 8
prevFinalX=0 // unused

//state=1
// <map>_GenState - one per output map. The state of that map's 4K canvas:
//   0 = off: not ticked, nothing to do
//   1 = wanted: ticked but not rendered yet, or out of date. The next G renders
//       it. A render in progress also sits at 1 until the last set is done.
//   2 = finished: rendered and up to date. Only state-2 maps are exported by S.
// Who changes it:
//   tick-box click (Draw_0)        0 <-> 1, and 2 -> 0
//   end of a render (doMainStep)   every 1 -> 2
//   colour edit (Step_0 / Step_2)  color_GenState 2 -> 1
//   paste (obj_copy)               every 2 -> 1
//   project load                   set from the do* tick-boxes, so 2 -> 1 / 0
// rgbMask = canvas, norm = nm_canvas, the rest are named after their canvas.
rgbMask_GenState=0
norm_GenState=0
color_GenState=0
mask_GenState=0
id_GenState=0
depth_GenState=0
flow_GenState=0
ao_GenState=0
frizz_GenState=0


// -----------------------------------------------------------------------------
// ID COLOURS - fixed palette of 34 flat colours (index 0..33) for the ID map.
// Per-strand mode uses only 0..8; per-set mode uses 0..10 (one per set).
// -----------------------------------------------------------------------------
// id support of up to 33 sets, so maybe a 18 set, set limit? easy may 62/192 tones too.
colorIDarray[0]=make_color_rgb(255,0,0)
colorIDarray[1]=make_color_rgb(0,255,0)
colorIDarray[2]=make_color_rgb(0,0,255)

colorIDarray[3]=make_color_rgb(0,255,255)
colorIDarray[4]=make_color_rgb(255,0,255)
colorIDarray[5]=make_color_rgb(255,255,0)

colorIDarray[6]=make_color_rgb(255,255,255)

colorIDarray[7]=make_color_rgb(0,128,255)
colorIDarray[8]=make_color_rgb(128,0,255)
colorIDarray[9]=make_color_rgb(0,255,128)

colorIDarray[10]=make_color_rgb(128,255,255)
colorIDarray[11]=make_color_rgb(255,128,255)
colorIDarray[12]=make_color_rgb(255,255,128)

colorIDarray[13]=make_color_rgb(128,128,255)
colorIDarray[14]=make_color_rgb(128,255,128)
colorIDarray[15]=make_color_rgb(255,128,128)

colorIDarray[16]=make_color_rgb(128,0,0)
colorIDarray[17]=make_color_rgb(0,128,0)
colorIDarray[18]=make_color_rgb(0,0,128)

colorIDarray[19]=make_color_rgb(128,255,0)
colorIDarray[20]=make_color_rgb(255,128,32)
colorIDarray[21]=make_color_rgb(255,0,128)

colorIDarray[22]=make_color_rgb(64,0,0)
colorIDarray[23]=make_color_rgb(0,64,0)
colorIDarray[24]=make_color_rgb(0,0,64)

colorIDarray[25]=make_color_rgb(64,64,0)
colorIDarray[26]=make_color_rgb(0,64,64)
colorIDarray[27]=make_color_rgb(64,0,64)

colorIDarray[28]=make_color_rgb(64,64,64)
colorIDarray[29]=make_color_rgb(128,128,128)
colorIDarray[30]=make_color_rgb(192,192,192)

colorIDarray[31]=make_color_rgb(64,128,192)
colorIDarray[32]=make_color_rgb(64,192,128)
colorIDarray[33]=make_color_rgb(64,192,192)

// -----------------------------------------------------------------------------
// FLOW MAP OPTIONS (saved in the project as "Flow Map ...")
// The flow map encodes each strand's local direction as a colour.
//   dirHue  0 = direction as red/green components (the usual flow map)
//           1 = direction as a HUE instead; dirBlue is then ignored
//   dirFlipX / dirFlipY  0 or 1: shift the angle used for the green (X) / red
//           (Y) component, for engines that expect the opposite convention.
//           CHECK: doMainStep adds dirFlip*180 to an angle that is in RADIANS,
//           so the shift is not an exact half turn.
//   dirBlue 1 = doMainStep adds blue (0,0,128) over the finished flow map so it
//           reads like a tangent-space map; 0 = blue stays 0
// -----------------------------------------------------------------------------
// directional colors
dirFlipX=1
dirFlipY=1
dirBlue=1
dirHue=0


avgLife=0 // running median of strand lengths during a render (debug/statistic)

// -----------------------------------------------------------------------------
// STRAND SHAPE GLOBALS (fade / scale)
// -----------------------------------------------------------------------------
// NEW exposed variables in h 1.254

// padding: extra thickness added to every strand (thickness factor is
// 0.05 + padding/1000). No slider - always 0 unless changed here.
padding=0 // padding for color hairs (to be added)
// scaleIn / scaleOut: saved and loaded, but the renderer overwrites them for
// every strand (life*0.75 and life*0.12), so the saved values have no effect.
scaleIn=1500//1000 // is this the scaling in length?
scaleOut=500 // scaling out
// fadeIn / fadeOut: GLOBAL sliders, 0..40 (used clamped to 1..40). The strand's
// alpha ramps up over the first (fadeIn/40) of HALF its length and down over the
// last (fadeOut/40) of half its length. So 40 = fade across half the strand,
// 1 = almost no fade. Per-set versions: setFadeInAdj[] / setFadeOutAdj[].
fadeIn=8//100 // set fade in speed (alpha)
fadeOut=12// // set fade out speed (alpha+scale)

// -----------------------------------------------------------------------------
// NOISE. Two kinds of variable here:
//   noiseAmt / noiseFreq   GLOBAL sliders (per-set: setNoiseAmtAdj / FreqAdj)
//   noiseOn .. noiseS3     WORKING values for the strand being drawn right now;
//                          recalculated per strand, meaningless between strands
// The three "octaves" are three sine waves of different speed (x1, x2.7, x6.3)
// mixed 62% / 28% / 10%, read from lut_sin. Phases come from a hash of the set
// seed + set + strand number, so the wobble is repeatable and uses no random().
// The offset grows from 0 at the root to full at the tip.
// -----------------------------------------------------------------------------
// V1.90 NOISE - gradual left/right deviation along each fibre.
// Amount 0 = off (original algorithm, no extra cost). Above 0 enables the
// three-octave per-point noise lookup, which is deliberately more expensive.
noiseAmt=0        // 0-40 slider value - how far the fibre wanders
noiseFreq=10      // 0-40 slider value - how often it wanders (10 = neutral)
noiseOn=0         // per-strand gate, set in doCalc / doMainStep
noiseAmpS=0       // per-strand amplitude in pixels
noiseP1=0         // per-strand LUT phase, octave 1
noiseP2=0         // per-strand LUT phase, octave 2
noiseP3=0         // per-strand LUT phase, octave 3
noiseS1=0         // per-strand LUT step per point, octave 1
noiseS2=0         // per-strand LUT step per point, octave 2
noiseS3=0         // per-strand LUT step per point, octave 3
noiseScale=0.06   // master amplitude tuning - raise for wilder deviation

// V1.96 CLUMPING - strands of a set gather into tresses (see clumpTools).
// All four are 0-40 notched sliders. Amount 0 = off, so older projects are
// untouched until the user turns it up.
clumpAmt=0        // how hard members pull to their leader at the tip
clumpCount=6      // tresses per set (0 and 1 both mean one tress)
clumpStart=8      // how far down the strand the pull begins
clumpScatter=10   // per-strand looseness + a few strays
textBox_clump=[0,0,0,0]
clumpTip=[
	"Clump Amount - how tightly the strands of each tress pull together toward the tip. 0 = off",
	"Clump Count - how many tresses each set is split into, by root position",
	"Clump Start - how far down the strand the clumping begins (0 = from the root)",
	"Clump Scatter - loosens individual strands and lets a few strays escape"]
// textBox_clump[k] / clumpTip[k]: k = 0 Amount, 1 Count, 2 Start, 3 Scatter -
// the same index clumpTools uses everywhere (clumpGetGlobal(k) etc.).
// Per-set versions: setClumpAmtAdj / CountAdj / StartAdj / ScatterAdj[] with
// matching ...Overrode[] flags, created in the main per-set loop below.
//
// working state for the set currently being drawn
// Everything from here to mixCacheX is WORKING STATE, rebuilt by
// clumpPrepareSet() / mixerCacheBuild() for each set as it is drawn. The values
// given here are only placeholders so the variables exist.
//   clumpOnS      1 = clumping active for the current set
//   clumpAmtS     pull strength for the current set
//   clumpStartS   where along the strand (0..1) the pull begins
//   clumpRampS    multiplier turning (position - start) into a 0..1 ramp
//   clumpLeadX[tress][point]  X path of each tress's leader strand
//   clumpLeadV[tress]         strand number of that leader, -1 = none yet
//   clumpLeadLen / Life / Step[tress]  point count, length and point spacing
//                             of the stored leader path
//   clumpBin[strand]          which tress the strand belongs to
//   clumpIsLead[strand]       1 = this strand is its tress's leader (drawn
//                             unchanged; the others are pulled toward it)
//   clumpStick[strand]        0..1 how firmly this strand follows (Scatter)
//   mixCacheX[n]              combined sideways push of the three mixer paths
//                             at point n of a strand, for the current set
// The preview keeps a separate copy of all this per set in pvW[], so it can
// draw several sets a few strands at a time.
clumpOnS=0; clumpAmtS=0; clumpStartS=0; clumpRampS=1
for (var _cq=0;_cq<40;_cq++)
	{
	clumpLeadX[_cq]=array_create(4000,0)
	clumpLeadV[_cq]=-1
	clumpLeadLen[_cq]=0
	clumpLeadLife[_cq]=1
	clumpLeadStep[_cq]=1
	}
clumpBin=array_create(100,0)
clumpIsLead=array_create(100,0)
clumpStick=array_create(100,1)
mixCacheX=array_create(3901,0)

// -----------------------------------------------------------------------------
// PROGRESSIVE PREVIEW (pv*) - state of previewUpdate() in previewJob.
// Per set, pvState[set] is a small state machine:
//   0 UP TO DATE  nothing to do
//   2 CHANGING    a value this set depends on changed this frame. The set is
//                 redrawn at once at coarse quality (LIVE mode). It stays 2
//                 while values keep changing; pvQuiet[set] counts the frames
//                 since the last change.
//   1 SETTLED     unchanged for pvSettle frames (or never drawn / forced).
//                 Waiting for its turn to start the full-quality redraw.
//   3 GROWING IN  being redrawn at full quality a few strands per frame;
//                 pvV[set] = next strand, pvCnt[set] = how many in total.
//                 Reaching the end returns it to 0.
// "Changed" is decided by comparing pvSig[set], an array of every value the
// set's preview depends on (previewSetSig), with last frame's. If a new setting
// does not show in the preview until something else is moved, it is missing
// from previewSetSig.
// Tuning values are in microseconds (1000 = 1 ms; one 60 fps frame = 16667).
// -----------------------------------------------------------------------------
// V1.96 PROGRESSIVE PREVIEW (see previewJob)
pvBudget=12000    // microseconds per frame the grow-in may spend drawing strands
pvLiveBudget=16000 // microseconds per frame the live coarse pass aims for while values change
pvUsPerPoint=4     // measured cost of one strand point, microseconds (self-updating)
pvFullStep=10      // point spacing of the finished preview (what the rebuild always used)
pvSettle=5         // frames a set must stay unchanged before it grows in at full quality
pvChunk=2          // strands drawn for one set before moving on to the next
pvRR=0             // round-robin position, so every set grows at the same rate
pvBusy=0           // 1 while BUSY mode is waiting for the mouse to be released
// Update mode: 0 = LIVE (coarse while dragging, strands grow in afterwards),
// 1 = BUSY (the pre-1.96 feel: wait while a slider is held, redraw on release).
// A preference, not project data, so it lives in its own small ini file.
// Smoothing: 1 = SMOOTH (shd_previewSmooth runs as the preview is composited),
// 0 = RAW (the strands exactly as drawn). Preview only.
ini_open("HSD_Settings.ini")
pvMode=clamp(ini_read_real("preview","updateMode",0),0,1)
pvSmooth=clamp(ini_read_real("preview","smooth",1),0,1)
ini_close()
pvSmoothTexel=shader_get_uniform(shd_previewSmooth,"u_texel")
pvSmoothRadius=shader_get_uniform(shd_previewSmooth,"u_radius")
pvStatStrands=0    // counters, handy when profiling
pvStatCoarse=0
pvStatUs=0         // microseconds previewUpdate took last frame
for (var _pv=0;_pv<maxSets;_pv++)
	{
	pvSig[_pv]=[]      // last signature drawn; empty = never drawn
	pvState[_pv]=0     // 0 up to date, 1 settled and waiting, 2 changing (shown coarse), 3 growing in
	pvV[_pv]=0         // next strand to draw while growing
	pvCnt[_pv]=0       // strands this set will have
	pvW[_pv]=undefined // this set's working state (mixer cache + clump membership)
	pvDrawnStep[_pv]=10 // point spacing this set's surface was last drawn with (sizes the smoothing)
	pvQuiet[_pv]=0
	prSig[_pv]=[]      // inputs the pre-random tables were last built from (preRandsRefresh)
	}


// -----------------------------------------------------------------------------
// SEEDS
// seedVal: the GLOBAL seed. Step_1 re-applies it to the random stream every
//   frame, and it is saved as "Seed". Because randomize() is commented out, a
//   fresh launch always starts from GameMaker's default seed, so a new project
//   looks the same every time until the dice is clicked.
// randomSeedVal[set] (main per-set loop below): the seed each set's pre-random
//   table is built from. This, not seedVal, is what decides how a set looks.
// randomOverride[set]: 1 = the set was given its own seed with the dice while
//   selected; the "all sets" dice actions then leave it alone.
// seedUpdate: 1 = a seed changed, redraw every set (cleared by previewUpdate).
// seedValstring: the number typed into the F1 seed box (a number, not a string).
// makeRandom: frame of the dice sprite, 1 for two frames after a click (Alarm 0).
// -----------------------------------------------------------------------------
seedUpdate=0
seedValstring=0
//randomize() // new seed value
makeRandom=0; // perhaps this can be disabled for some reason...
seedVal=random_get_seed() // get seed value
random_set_seed(seedVal)
str=""  // scratch strings for the text boxes / hex colour box in Draw_0
str2=""
// -----------------------------------------------------------------------------
// PREVIEW QUALITY (bottom-bar FAST / MED / SLOW / DYNA buttons, Step_1)
// maxPreviewStrandsPerSet: cap on strands PREVIEWED per set (20/50/100/30).
//   Never above 100 - the pre-random tables hold 100 strands per set. The final
//   render ignores this and draws every strand.
// optimalStep: point spacing of the pre-1.96 preview. Still adjusted by the
//   buttons, the mouse wheel and DYNA mode, and saved, but the 1.96 preview
//   draws with pvFullStep instead.
// Both are assigned again at the very end of this event (50 and 10), which are
// the values actually in force at start-up.
// motionDetectMode: F2 toggle, see Step_1.
// -----------------------------------------------------------------------------
// PREVIEWER OPTI
maxPreviewStrandsPerSet=100 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
optimalStep=44 // for optimising the display update (16) higher is more optimised 80/44/20

motionDetectMode=0

// -----------------------------------------------------------------------------
// COLOUR SLOT FLAGS - which of the five colours the picker is editing.
// Exactly one is 1. Slot order everywhere: background, A, B, root, tip.
// Step_0 owns these (colourSelectedSlot 0..4, changed only by a click on a
// swatch) and rewrites them every frame; mainCalc() restores them again inside
// Draw_0 because an old hover-driven block there still changes them.
// getColorPick: the last pixel colour read by the eyedropper / palette (Step_2).
// -----------------------------------------------------------------------------
ColA_active=1
ColB_active=0
RootCol_active=0
TipCol_active=0
bkCol_active=0

getColorPick=make_color_rgb(255,255,255)

// minScale / maxScale: GLOBAL "Thick Min / Thick Max" sliders. They set the
// thinnest and thickest a strand's stamp can be along its length (the renderer
// multiplies them by 0.05 to get a sprite scale). maxScale is also the upper
// clamp of each strand's random thickness factor, and is forced to at least 1
// at render time. Per-set versions: setThickMinAdj[] / setThickMaxAdj[].
minScale=2
maxScale=3
// strand count/length overriding

// Creates every slider_interract_* flag (true while that slider is being
// dragged) and sets them all false. Needs maxSets, so it must stay below it.
nullify_sliderInterracts(); //reset all slider activity

// -----------------------------------------------------------------------------
// PER-SET ARRAYS (main group). Index s = set 0..14 (0..10 in use).
// Everything in this loop is one entry PER SET. See OVERRIDES at the top of the
// file for the flag / value pairing. Summary of what lives here:
//
//   VALUE ARRAY               FLAG ARRAY               GLOBAL       RANGE/NOTE
//   strandCountOverride       setCountOverrode         strands      strands in the set, max 100
//   strandLengthOverride      setLengthOverrode        length       canvas pixels
//   strandSetMixerAdj1..3     setMixerAmt1..3Overrode  mixer1..3    mixer amounts
//   strandSetMixerOffsetAdj1..3 setMixerOfs1..3Overrode mixer1..3_offset
//   strandSetTaperAdj         setTaperOverrode         tapering     %
//   strandSetWavynessAdj      setWaveynessOverrode     wavyness     %
//   strandSetWaveFreqMinAdj   setWaveFreqMinOverrode   minFreq
//   strandSetWaveFreqMaxAdj   setWaveFreqMaxOverrode   maxFreq
//   strandSetVariAdj          setVariOverrode          lifeVariant  % length variation
//   strandSetSpaceAdj         setSpacingOverrode       distancings  root spread (x10 px)
//   strandYRanRange           strandYRanRangeOverrode  yRanRange    root Y jitter
//   setThickMinAdj / MaxAdj   setThickMin/MaxOverrode  minScale / maxScale
//   setTipThickAdj            setTipThickOverrode      tipThick     (seeded lower down)
//   setRootThickAdj           setRootThickOverrode     rootThick    (seeded lower down)
//   setThickVaryAdj           setThickVaryOverrode     thickVary    (seeded lower down)
//   setFadeInAdj / OutAdj     setFadeIn/OutOverrode    fadeIn / fadeOut   0..40
//   setNoiseAmtAdj / FreqAdj  setNoiseAmt/FreqOverrode noiseAmt / noiseFreq 0..40
//   setClump*Adj (4)          setClump*Overrode (4)    clumpAmt etc.      0..40
//   randomSeedVal             randomOverride           (seedVal)    per-set seed
//
//   NO GLOBAL / NO FLAG (always per set):
//   xOffset / yOffset (declared later)  where the set sits on the canvas, in
//                             canvas pixels, changed by dragging or arrow keys.
//                             strandXOffset / strandYOffset are an older copy
//                             that checkAndOffset keeps in step; nothing draws
//                             from them.
//   alogrithmInfluence, taperInfluence  0..100, default 50. Saved, loaded and
//                             copy/pasted, but the calc scripts do not read them.
//   set_active                0 = set is ON (drawn in the preview and counted
//                             in the strand total). Note the sense: 0 is on.
//                             Nothing assigns it after this event, so every
//                             set is always on at present.
//   setBBxx                   root X of the last strand previewed in the set
//                             (canvas pixels), used by doHighlighting.
//   setBBl/r/t/b              bounding box of the set's preview strands in
//                             canvas pixels (left, right, top, bottom), written
//                             by previewDrawStrands; used for click-testing,
//                             the highlight box and the smoothing rectangle.
//                             r==0 and b==0 means "nothing drawn".
// -----------------------------------------------------------------------------
for (s=0;s<maxSets;s++) // support up to 32 sets maybe greater later on
	{
	strandCountOverride[s]=10
	strandLengthOverride[s]=2048

	setMixerAmt1Overrode[s]=0 // amounts and offsets ... (array based) can get rid of non array based?
	setMixerOfs1Overrode[s]=0 // 
	setMixerAmt2Overrode[s]=0 // 
	setMixerOfs2Overrode[s]=0 // 
	setMixerAmt3Overrode[s]=0 // 
	setMixerOfs3Overrode[s]=0 // 
	strandXOffset[s]=25 // mid position (0)
	strandYOffset[s]=25 // mid position (0)
	alogrithmInfluence[s]=50 // how much influence of the algorithm has
	taperInfluence[s]=50 // how much tapering is included
	
	// new in 1.71.0 - not fully implemented
	setThickMinOverrode[s]=0 // 
	setThickMaxOverrode[s]=0
	
	setThickMinAdj[s]=minScale
	setThickMaxAdj[s]=maxScale

	// New in 1.91 - every notched slider row can now be overridden per set.
	// These arrays are always populated: a global slider writes through to
	// every set that is not overridden, so the calc scripts just read [set].
	setTipThickOverrode[s]=0
	setRootThickOverrode[s]=0
	setThickVaryOverrode[s]=0
	setFadeInOverrode[s]=0
	setFadeOutOverrode[s]=0
	setNoiseAmtOverrode[s]=0
	setNoiseFreqOverrode[s]=0

	setFadeInAdj[s]=fadeIn
	setFadeOutAdj[s]=fadeOut
	setNoiseAmtAdj[s]=noiseAmt
	setNoiseFreqAdj[s]=noiseFreq

	// V1.96 clumping, same override pattern as the V1.91 rows
	setClumpAmtOverrode[s]=0
	setClumpCountOverrode[s]=0
	setClumpStartOverrode[s]=0
	setClumpScatterOverrode[s]=0
	setClumpAmtAdj[s]=clumpAmt
	setClumpCountAdj[s]=clumpCount
	setClumpStartAdj[s]=clumpStart
	setClumpScatterAdj[s]=clumpScatter

	// Preview bounding box per set, cached by previewDrawStrands for doHighlighting
	setBBl[s]=0; setBBr[s]=0; setBBt[s]=0; setBBb[s]=0; setBBxx[s]=0
	// setTipThickAdj / setRootThickAdj / setThickVaryAdj are seeded just after
	// tipThick / rootThick / thickVary are declared, further down this event.

	
	// new in 1.70.0 (implemented 21/5/23 RR)
	
	randomOverride[s]=0 // are we making a new random value for this set? if so use own value and not global value
	randomSeedVal[s]=1//seedVal+s // we want to be able to override seed values per set

	// New in V1.29 Advanced mode as opposed to the simple mode in 1.284, complete replacement but defaults can be generated in a simlar way in the end
	// each set has some kind of conformity to thier algorithms
	// each sets algorithms are unique to that set
	// PNM = could potentially be a multiplier on the path nodes.
	set_active[s]=0 // is the current set selected/active?

	//new in 1.43
	// mixer readjusters
	strandSetMixerAdj1[s]=10 // default 10
	strandSetMixerAdj2[s]=2 // default 2
	strandSetMixerAdj3[s]=1 // default 1
	strandSetMixerOffsetAdj1[s]=0
	strandSetMixerOffsetAdj2[s]=0
	strandSetMixerOffsetAdj3[s]=0
	
	//other override values
	strandSetTaperAdj[s]=10 // default 10
	strandSetWavynessAdj[s]=16 // default 16
	strandSetWaveFreqMinAdj[s]=1 // default 1
	strandSetWaveFreqMaxAdj[s]=10 // default 10
	strandSetVariAdj[s]=6 // default 6
	strandSetSpaceAdj[s]=21 // distancings=21
	
	strandYRanRange[s]=20 //default 20 (yRanRange)
	}


renderToSurf=0 // set to 1 by the mouse-release autosave in doMainStep; nothing reads it

// predefined counts now that diminish is gone in 1.43 
// 1.5 sees first 4 with overrides.
/*
strandCountOverride[0]=100
strandCountOverride[1]=60
strandCountOverride[2]=30
strandCountOverride[3]=15
*/
	
// set text box arrays for lengths
/*
for (aa=0;aa<32;aa++)
	{
	textBox_overrideLength[aa]=0
	textBox_overrideLength_value[aa]="" //store string version
	
	textBox_overrideCount[aa]=0
	textBox_overrideCount_value[aa]="" //store string version
	}
*/

// -----------------------------------------------------------------------------
// COLOURS
// How a strand point is coloured on the colour map: blend variation A -> B by
// the strand's depth value (so each strand is a mix of the two tones), then
// toward the ROOT colour near the root and the TIP colour near the tip.
//
// There are three layers of colour variable - mixing them up is the usual cause
// of "wrong colour" problems:
//   custom*  customColVarA / customColVarB / customRootCol / customTipCol
//            What the colour UI shows and edits, and what the renderer reads.
//            NOT the stored truth: Step_0 loads it each frame with the selected
//            set's colours (or the globals when no set is selected), and Step_2
//            swaps in each set's colours while that set renders.
//   global*  globalColVarA / B / globalRootCol / globalTipCol - the project
//            colours used by every set without an override.
//   set*     setColVarA[] / setColVarB[] / setRootCol[] / setTipCol[] - what
//            each set really uses, with set*Overrode[] flags.
//   global* and set* are created in Step_0 (first frame), not here. The values
//   below are only the start-up defaults that Step_0 copies into them.
// colrBack: background colour of the colour map. Global only, no per-set copy.
// Colours are GameMaker colour numbers. In the project file the five legacy
// colour lines are RRGGBB hex; the per-set block stores the raw numbers.
// -----------------------------------------------------------------------------
// custom coloring brown

// custom coloring defaults
colrBack=make_color_rgb(34,0,70)
colrCustom=make_color_rgb(12,8,5) // working: colour of the point being rendered
customColVarA=make_color_rgb(239,85,248)
customColVarB=make_color_rgb(36,28,210)
customRootCol=make_color_rgb(16,12,22)
customTipCol=make_color_rgb(150,100,250)
depthTone=make_color_rgb(0,0,0) // working: grey level of the current strand on the depth map

// Colour picker comparison swatch: storeColor = the slot's colour when it was
// selected ("old"), newColor = the colour being edited now ("new").
storeColor=customColVarA
newColor=customColVarA




idChoice=c_white // for storing the colour choise


deviationFromX=0 // we can use this for angling and flow map lerping
sc=1

// -----------------------------------------------------------------------------
// THICKNESS (global sliders; per-set copies are seeded just below)
// tipThick / rootThick: used as value/30 to blend between the strand's two
//   thickness profiles (one swelling toward the tip, one toward the root) and
//   a plain mid-strand bulge - they shape WHERE along its length a strand is
//   thick, rather than setting an absolute width. Width limits are
//   minScale / maxScale.
// thickVary: strand-to-strand variation. Each strand gets a random thickness
//   factor between thickVary/100 and thickVary/20, clamped to 0.8..maxScale (or
//   to the set's Thick Min/Max when those are overridden) - preRandThickBase.
// -----------------------------------------------------------------------------
tipThick=10
rootThick=6
thickVary=3

// V1.91 - seed the per-set thickness arrays now that their globals exist.
for (s=0;s<maxSets;s++)
	{
	setTipThickAdj[s]=tipThick
	setRootThickAdj[s]=rootThick
	setThickVaryAdj[s]=thickVary
	}
// colorMode: which sliders the colour picker shows (buttons in Draw_0); saved.
colorMode=1 // rgb=0 hsv=1 grey=2
a=1 // working: alpha of the strand point being drawn (also reused as a loop index)

// Hex colour entry box in Draw_0. hexColEdit = true while it is being typed in;
// editHexColor = the text typed so far; hexColR/G/B = its two-digit parts.
hexColEdit=false
editHexColor=""
hexColString=""
hexColR=""
hexColG=""
hexColB=""

// canSave: false from the moment G is pressed until the render finishes, so a
// half-rendered map cannot be saved or autosaved. saving: true while a project
// or autosave file is open for writing; the renderer waits while it is true.
canSave=true
saving=false
// -----------------------------------------------------------------------------
// GENERAL STRAND GLOBALS
// Two kinds of variable are mixed together below:
//   SETTINGS - the global sliders, saved in the project
//   WORKING  - scratch values for the strand / point being calculated right now
//              by doCalc (preview) or doMainStep (render). Their start values
//              here do not matter and they mean nothing between frames.
// -----------------------------------------------------------------------------
finalX=0   // WORKING: final X of the current point, canvas pixels
setXpos=0  // WORKING: X the current set tapers toward (its gathering point)
//maxStrandsPerSet=200 // needs a max or crash
// ampFactor: fixed multiplier on waviness (wavyness% * 8). Not a slider.
ampFactor=8 // boost wavyness...
// tapering: SETTING, %. How strongly strands converge on setXpos toward the tip.
tapering=10

// sets: the LAST set index, not the count. 10 means 11 sets (0..10).
sets=10 // only 11 used for now due to performance reasons
h=0 // WORKING: strand index in the render loop
// minFreq / maxFreq: SETTINGS. Each strand's wave frequency is rolled between
// them (preRandFreq). Higher = tighter waves.
minFreq=1
maxFreq=10
straggleXX=0      // WORKING
strandDecision=0//random(100)/100
straggleChoice=0//choose(StragglePath_A,StragglePath_B,StragglePath_C);
freq=random(1000)/100 // WORKING: wave frequency of the current strand
amp=random(100)/100 // essentially wavyness
nx=0      // WORKING: X after the wave is applied
dpthAdd=0 // WORKING: small per-strand offset added to the depth/colour blend
j=0
// root / tip: WORKING lengths of the root-colour and tip-colour zones of the
// current strand (saved as "Root coverage" / "Tip coverage" but recalculated
// per strand). rt / tp: WORKING 0..1 strength of root / tip colour at the
// current point; they are also the green and blue channels of the RGB mask
// (red = strand depth).
root=0
tip=0
rt=0
tp=0
// lifeVariant: SETTING "Variation", %. Strand lengths are rolled within
// +/- this percentage of the set's length. Per-set: strandSetVariAdj[].
lifeVariant=6
rootRange=500 // WORKING
// rootPosition: SETTING. Root colour zone = up to rootPosition*50 points
// (plus a random extra) from the root. No per-set version.
// tipPosition: SETTING. Tip colour zone = the last tipPosition*10 points.
rootPosition=25
tipPosition=50 // is this when it comes in before the end?
// wavyness: SETTING, %. Per-set: strandSetWavynessAdj[].
wavyness=16 // how wavy? 15def
frizz=50 // frizz frequency with some range of deviation 10% or so.
//*********************************************
// strands: SETTING, strands per set (per-set: strandCountOverride[]). Max 100.
// diminish: legacy "fewer strands in each later set" - removed in 1.43, still
// saved as "Reduction" so old files stay in step.
strands=10
diminish=4// how many less strands per set
//***********************************************
maxStrands=strands // legacy; saved as "Max Strands", the renderer sets it to 2200
sx=0 // WORKING
xx=0 // WORKING: root X of the current strand, canvas pixels
// distancings: SETTING "Spacing". Roots of a set are spread over distancings*10
// canvas pixels. Per-set: strandSetSpaceAdj[].
// setDistance: SETTING "Set Distances". Set n starts n * setDistance*10 pixels
// further right. Global only.
distancings=21// new in version 1.287
setDistance=36 // extra distancings
//distanceSet=510 // extra distancings

setID=0 // WORKING: set being drawn
// xxx / yyy: top-left corner, in canvas pixels, of the 512x512 window the map
// viewer zooms into (dragged in Step_0). The renderer also writes them.
xxx=400; // preview window (zoom)
yyy=200;
yp=0;          // WORKING: point counter along the current strand
strandCount=0; // WORKING: strands rendered so far in the current set

// retrigger: render gate, used with doOnce. G / Generate sets both true.
// doMainStep keeps retrigger true after each set so the next frame renders the
// next one, and sets it false when the last set is done.
retrigger=true;
// hairLength: WORKING length of the set being drawn (set length + its random
// offset). life: WORKING length of the current strand, in points = pixels.
hairLength=3600
life=hairLength
currentMapPreview=0 // before pressing shortcut keys
frizzColor=make_color_hsv(0,0,128) // WORKING: random grey per stamp on the frizz map
// mixer1..3 / mixer?_offset: SETTINGS, 0..40. How much each of the three mixer
// curves (editingPath[0..2]) pushes strands sideways. The offset stretches the
// curve along the strand: the whole curve spans 4096 + offset*100 points.
// Per-set: strandSetMixerAdj1..3[] / strandSetMixerOffsetAdj1..3[]. The combined
// result is cached in mixCacheX (mixerCacheBuild). That script divides by the
// set's Variation, so a Variation of 0 is a divide by zero there.
mixer1=10
mixer2=2
mixer3=1
mixer1_offset=0
mixer2_offset=0
mixer3_offset=0

// SETUP 16 point paths that will be used for storing up to 4 clump paths per set
// these paths will be treated like strands and even be mimicked from the first 4 strands generated (if there is 4)
// predefine a base one
// (clumpPath is from an earlier, path-based clumping idea. Unused: the V1.96
// clumping in clumpTools does not use paths. Nothing else refers to it.)
clumpPath=path_add()
path_set_closed(clumpPath,0) // not closed
path_set_kind(clumpPath,1) // smooth
path_add_point(clumpPath,0,0,0) // add a path point
path_add_point(clumpPath,1024,2048,0)
path_add_point(clumpPath,4096,4096,0)

// hack in some offsets
// xOffset[set] / yOffset[set]: PER SET, sets 0..10 only. Where the whole set is
// shifted to on the canvas, in canvas pixels (0 = its default column). Changed
// by dragging a set in the preview or with the arrow keys (checkAndOffset);
// saved as "Strand X offset" / "Strand Y offset".
for (n=0;n<11;n++)
	{
	xOffset[n]=0
	yOffset[n]=0
	}

// ghostSprite: a screenshot sprite captured by checkAndOffset() and drawn by
// Draw_0 at 40% over the preview area (hidden while the right button is held).
// -1 = none. checkAndOffset frees the old one before taking a new one.
ghostSprite=-1
// -----------------------------------------------------------------------------
// CANVASES - the eleven 4096x4096 SURFACES. About 64 MB of video memory each.
//   canvas        RGB mask map  (R = strand depth, G = root zone, B = tip zone)
//   flow_canvas   flow / direction map
//   mask_canvas   white-on-black alpha mask
//   nm_canvas     normal map (multi-strand mode: a bump picture, converted on export)
//   id_canvas     ID map
//   color_canvas  colour map
//   depth_canvas  depth map (grey level per strand)
//   ao_canvas     ambient occlusion map
//   frizz_canvas  frizz map (random grey per stamp)
//   blurSurface   scratch for the blur pass (B key)
//   tNormsurf     scratch for the bump -> normal conversion (shd_normal)
// (The old trailing comments on some of these lines were copy-pasted and say
// "depth pass" / "ID strands" where that is not what the surface holds.)
// Surfaces can vanish at any time. Step_1 and canvasCheck() test for that and
// re-create them, but their CONTENTS are lost and must be rendered again.
// setupCanvases() clears each one to its background and creates hCol[] (the 24
// colour-history swatches) and colorHistoryPointer.
// -----------------------------------------------------------------------------
surfSize=4096
canvas=surface_create(surfSize,surfSize) // out texture surface
flow_canvas=surface_create(surfSize,surfSize) // out texture surface
mask_canvas=surface_create(surfSize,surfSize) // out texture surface
nm_canvas=surface_create(surfSize,surfSize) // out texture surface
id_canvas=surface_create(surfSize,surfSize) // will fill out with ID strands in RGBCMY
color_canvas=surface_create(surfSize,surfSize) // will fill out with ID strands in RGBCMY
depth_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
ao_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
frizz_canvas=surface_create(surfSize,surfSize) // will fill out with a depth pass
blurSurface=surface_create(surfSize,surfSize) // will fill out with a depth pass
tNormsurf=surface_create(surfSize,surfSize) // will fill out with a blur
setupCanvases()

// -----------------------------------------------------------------------------
// TEXT BOXES - one pair per number box beside a slider:
//   textBox_<name>        state flag for that box (see the text-box code in
//                         Draw_0; reset_textBoxes() puts them all back to 0 when
//                         Enter is pressed)
//   textBox_<name>_value  the STRING shown / being typed, kept separately from
//                         the numeric setting of the same name.
// <name> matches the global setting it edits. Boxes without a _value line
// (diminish, frizz) are only reset by reset_textBoxes() and never drawn.
// minScale / maxScale start at 2 where every other flag starts at 0.
// -----------------------------------------------------------------------------
// text box settings
#region
str=""
textBox_wavyness=0 // active?
textBox_wavyness_value=string(wavyness)

textBox_strands=0 //activate
textBox_strands_value=string(strands)

textBox_diminish=0 //activate
//textBox_diminish_value=string(diminish)

textBox_distancings=0 //activate
textBox_distancings_value=string(distancings)

textBox_setDistance=0 //activate
textBox_setDistance_value=string(setDistance)

textBox_minScale=2 //activate
textBox_minScale_value=string(minScale)

textBox_maxScale=2 //activate
textBox_maxScale_value=string(maxScale)


textBox_tipThick=0 //activate
textBox_tipThick_value=string(tipThick)

textBox_rootThick=0 //activate
textBox_rootThick_value=string(rootThick)

textBox_thickVary=0 //activate
textBox_thickVary_value=string(thickVary)


textBox_lifeVariant=0 //activate
textBox_lifeVariant_value=string(lifeVariant)

textBox_tapering=0 //activate
textBox_tapering_value=string(tapering)

textBox_minFreq=0 //activate
textBox_minFreq_value=string(minFreq)

textBox_maxFreq=0 //activate
textBox_maxFreq_value=string(maxFreq)

textBox_fadeIn=0 //activate
textBox_fadeIn_value=string(fadeIn)

textBox_fadeOut=0 //activate
textBox_fadeOut_value=string(fadeOut)

textBox_noiseAmt=0 //activate
textBox_noiseAmt_value=string(noiseAmt)

textBox_noiseFreq=0 //activate
textBox_noiseFreq_value=string(noiseFreq)

textBox_frizz=0 //activate
//textBox_frizz_value=string(length)

textBox_length=0 //activate
textBox_length_value=string(length)

textBox_mixer1=0 //activate
textBox_mixer1_value=string(mixer1)

textBox_mixer2=0 //activate
textBox_mixer2_value=string(mixer2)

textBox_mixer3=0 //activate
textBox_mixer3_value=string(mixer3)

textBox_mixer1_offset=0 //activate
textBox_mixer1_offset_value=string(mixer1_offset)

textBox_mixer2_offset=0 //activate
textBox_mixer2_offset_value=string(mixer2_offset)

textBox_mixer3_offset=0 //activate
textBox_mixer3_offset_value=string(mixer3_offset)

textBox_YRanRange=0
textBox_YRanRange_value=string(yRanRange)

#endregion
// 

// -----------------------------------------------------------------------------
// FILE SAVE
// canLoad: always true (gate for the loaders). loading: true while KeyPress_76
// or doAutoLoad is reading a file; several per-frame jobs pause while it is set
// and clearOverrides() uses it to schedule Alarm 1.
// theFile: handle of the project / autosave file currently open ("" = never
// opened). fileCustom (the chosen path) is created in Draw_0.
// mainS: LINE 1 of every project file. The loaders read the format version out
// of it: the four characters after "Version" (character 46 on). Rules:
//   - keep the text before the number exactly this length
//   - the same string is assigned in Step_0, Step_2, Alarm 1 and object g, and
//     written literally by doAutoSave - change them all together
//   - after a load mainS briefly holds the FILE's header, then is set back
// instr: LINE 2, a human-readable note about the "name:value;" format.
// -----------------------------------------------------------------------------
canLoad=true
loading=false

theFile=""

mainS ="Hair Strand Designer - Project File - Version1.96.0 - 9thNov2026 (C) Robert Ramsay"
instr="Variable description (colon : ) VariableValue (semiColon ;)";

// NEW VARIABLE ARRAYS DEISGNED TO CACHE PRE-DATA for more accuracy of representation in the renderer (not sure if it will work)
// for v1.41
// remember randomized values from previewer so we can trnasfer those to 
// the final render, however, bear in mind the final render may be able to show us
// more... but we have capactiry of up to 60 strands per set that could have their
// details recalled in the renderer.

yjit=200 // unused

// -----------------------------------------------------------------------------
// LEGACY PER-STRAND CACHE  strand<Name>[set, strand]   (11 sets x 100 strands)
// These 2D tables are NOT the pre-random tables. They are the older cache
// described above: doCalc / doCalcSoft still WRITE the value they used for each
// preview strand into them, but nothing reads them back any more - the
// renderer takes everything from the preRand* tables instead. The loop below
// only gives them a starting value so the arrays exist.
//
// THE REAL PRE-RANDOM TABLES are preRand<Name>[set, strand] (and
// preRandLifeVariant[set]). They are built by updatePreRands(), called at the
// end of this event and afterwards by preRandsRefresh() whenever one of a set's
// inputs changes. Each set's table is generated from randomSeedVal[set], so the
// preview and the final render read identical numbers:
//   preRandLife        strand length in points      preRandThickBase  thickness factor
//   preRandSpacing     root X within the set        preRandYY         root Y
//   preRandFreq / Amp  wave frequency / amplitude   preRandDepth / DepthAdd  depth tone
//   preRandRoot / RootRange  root colour zone       preRandStrandDecision, StraggleChoice
//   preRandSubSprite / AngChoice / Curling  multi-strand stamp variation
// The ORDER of the random() calls in updatePreRands is part of the project
// format: adding or removing one changes how every saved project looks.
//
// CHECK (strandLife line below): "strandLife[..]= life=random_range(...)" is not
// a chained assignment in GML. The second "=" is a comparison, so strandLife
// gets true/false and life is not changed. Harmless only because doCalc
// overwrites strandLife and nothing reads it.
// The right-hand sides use the global settings at their start-up defaults.
// -----------------------------------------------------------------------------

for (setRands=0;setRands<11;setRands++) //f
	{
			
		// a 2D array will work for these
		var f=setRands // temp
		// PER STRAND
		for (strandNum=0;strandNum<100;strandNum++) //h
			{
			

			strandThickBase[setRands,strandNum]=clamp(random_range(thickVary/100,thickVary/20),0.8,maxScale)
							//var thicknessBase =strandThickBase[setRands,strandNum]
			strandXX[setRands,strandNum]=(320-(distancings*10))+((distancings*10)/2)+((random_range(0,distancings*10)+(f*((setDistance*2)*5)))) 
							//xx=(320-(distancings*10))+((distancings*10)/2)+((random_range(0,distancings*10)+(f*((setDistance*2)*5)))) 
			strandLife[setRands,strandNum]=
							life=random_range(   
							clamp (hairLength*   (1-(lifeVariant/100)) , 10 , 3900)     ,
							clamp (hairLength*   (1+(lifeVariant/100)) , 10 , 3900)
							)
							//life=strandLife[setRands,strandNum]
			strandFrq[setRands,strandNum]=random_range(minFreq,maxFreq)
							//freq=strandFrq[setRands,strandNum]
			strandAmp[setRands,strandNum]=	random(1000)/10000		
							//amp=random(1000)/10000
			strandYY[setRands,strandNum]=random(20)+120
							//yy=strandYY[setRands,strandNum]
			strandRootRange[setRands,strandNum]=random((rootPosition*50))/3 //500 // can we define this?
							//rootRange=strandRootRange[setRands,strandNum]
			strandRoot[setRands,strandNum]=(random_range(round(random_range(0,(rootPosition*50))),(rootPosition*50)+rootRange))	
							//root=strandRoot[setRands,strandNum]
			strandDecide[setRands,strandNum]=random(100)/100 // influence of the strand 0.00 - 1.00
							//strandDecision=strandDecision[setRands,strandNum]
			strandStraggleChoice[setRands,strandNum]=0
							//
							// V1.94 - seeded with a real value, not 0. The renderer now
							// reads this cache for the first 100 strands, and the preview
							// only fills it while img==9; generating straight from another
							// map view would otherwise render every strand at depth 0.
							strandDepth[setRands,strandNum]=random(100)/100
			//strandColor[setRands,strandNum]=c_white
			}
		
		
	}

// make paths
//we will make paths that will act as flyaways
// these will need to be predefined but we can pick from them
// they should also have the ability to be resized
// -----------------------------------------------------------------------------
// FLYAWAY PATHS (legacy). Creates 2000 path resources of 101 points each in
// path[]. No other event or script of this object reads path[], and the
// variables around it (screenScale, points, pd, lpd, split, paths, yStag, res,
// pathPreview) are only used again by o_pathMaker, which builds its own.
// It costs start-up time and memory on every launch and F6 restart.
// pathPreview is a 1024x1024 surface that is never freed in CleanUp_0.
// -----------------------------------------------------------------------------
screenScale=0.25
n=0
points=100 // definition...0-29
pd=points // point deletion

lpd=-1 // last point deleted
split =length/points
paths=2000 // max number (we dont need this many).
yStag=15 // ystagger
for (pa=0;pa<paths;pa++) // many paths
	{
	path[pa]=path_add()
	
	
		path_add_point(path[pa],0,0,100) // first point
		path_set_closed(path[pa],0)
		path_set_kind(path[pa],1)
		// now some random points

		for (p=0;p<points;p++) // quite a few
			{
				//path_add_point(path[pa],irandom_range(-100*screenScale,100*screenScale),irandom_range((p*split)*screenScale,(p+1)*split*screenScale)+random_range(-yStag,yStag),100) // setup
				path_add_point(path[pa],0,p*10,100)
				
			}
	}
	
	

// draw paths to surfaces..

// 
res=0.25
pathPreview=surface_create(4096*res,4096*res)

// -----------------------------------------------------------------------------
// FINAL SET-UP
// -----------------------------------------------------------------------------
//tackle memory issue:
surfSetAO=0 // unused
// tog: 1..6 counter in the AO pass of the renderer; an AO stamp is drawn only
// when it is 1, i.e. on one pass in six.
tog=1
mbx=0 // mouse position when the button went down on a set (drag threshold)
mby=0
// Build every pre-random table now, from the defaults above. Must stay AFTER all
// the per-set arrays and settings it reads (randomSeedVal, strandSet*Adj,
// strandLengthOverride, length, setThick*, rootPosition, editingPath, moreHairs).
// imgOverride: -1 = no override. Only ever set to -1 (here and at the end of a
// render); kept for the "show the map being generated" idea in Draw_0.
// The last three lines are the start-up preview quality (overriding the values
// given in the PREVIEW QUALITY section) - note optimalStep 10 with 50 strands
// is not exactly any of the four buttons.
updatePreRands(-1) //-1 is all
	imgOverride = -1;
	// medium mode
	maxPreviewStrandsPerSet=50 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
	optimalStep=10 // for optimising the display update (16) higher is more optimised
	dynamicRes=0
			
			


// -----------------------------------------------------------------------------
// V1.97 - MCP LINK
// obj_mcp lets Claude Code drive the app (scripts/mcpCommands, tools/hsd-mcp).
// It is off until switched on (Ctrl+Shift+F10 or the -mcp launch option).
// mcpFileOverride: a project path handed to the S / L key events by an MCP
// save or load, used instead of their file dialog. "" = show the dialog.
// -----------------------------------------------------------------------------
mcpFileOverride = ""
if !instance_exists(obj_mcp) instance_create_depth(0, 0, -2000, obj_mcp)
