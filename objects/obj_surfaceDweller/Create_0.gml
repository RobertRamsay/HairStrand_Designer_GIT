draw_set_color(c_white);

demoMode=0 // for DEMO mode
demoInfo="DEMO (no save options)"
versionHSD="1.93.0.0"

showHeart=0
uiExtras=1 // little dots for overrides.

canDrawUI=0

topMostMode=0
wmx=0
wmy=0
moveWindow=0
fullscreenMode=0 // for fullscreen mode
if fullscreenMode==1 {window_set_topmost(1);topMostMode=1}

for (n=0;n<11;n++)
	{
	previewSurf[n]=surface_create(1024,1024)
	}

forceUpdate=0 // use this for forcing an update after a text input
renderH=0
colorOnlyUpdate=0

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

firstPass=true
newPalImg=-1 // no image
previewCanvasComplete=0
/*
window_set_size(display_get_width(),display_get_height()-90)
window_set_position(0,45)
*/
// sprites to store canvases..
aoSprite=-1
maxSets=15
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

aoExtra=1.55
aoType=1

infoMsg=""
count=0

screenScaleX =display_get_width()/1920	
screenScaleY =display_get_height()/1080


surfData=""

//window_set_topmost(topMostMode);
curlRotator=0
curlRotAmt=0.5 // 0 .. 1 later x3
flashAlpha=0
gameTick360=0

setToSolo=-1 // which set should be made solo?
checkSum=0
dynamicRes=0
tickytime=0
showHelp=0
smallTip=""
Tooltip=""
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
yRanRange=20 // new is 1.53

editingPath[0]=StragglePath_A1
editingPath[1]=StragglePath_B1
editingPath[2]=StragglePath_C1
//tn=0

// path stuff per cycle
xDiff=0
yDiff=0

numSel=0	
setHovveredID=-1//
clickCount=0

clickedID=-1
held=0
moving=0
leftmost=0
rightmost=0
topmost=0
bottommost=0

doOnce=true

moreHairs=0 // yes please=1
hoveringNumber=false
debugMsg=""

logFile=""
doLogOnce=0

firstCalc=1
subSpriteChoice=0 // experimental in v1.43
lastFileName=""
// pre randomize... 1100

normalMapGenerated=0

normSprite=spr_AOBlack
length=2048
gpu_set_texfilter(1) // turn on filter

or_color=make_color_rgb(200,100,30)
or_editColor=make_color_rgb(160,60,10)
blu_color=make_color_rgb(30,130,240)
grn_color=make_color_rgb(30,230,50)
yel_color=make_color_rgb(240,230,20)
pur_color=make_color_rgb(180,80,255)
red_color=make_color_rgb(240,40,60)

// a pre-random list will be needed overall
// for each strand, each type

						
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

exiting=false

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
file="";
prjName="HSD_"
projectOnly=false;

dance=0

// fix in 1.682 for grabbing window in 4k
screenScaleX =display_get_width()/1920	
screenScaleY =display_get_height()/1080

previewingUV=false;
tick=0
changesMade=false // for any algorithm changes made
idMode=0 // 0 is each strand 1 is each set.
idList=0;
strandIDsize=8 // number of colors used for ID for strands 
draw_set_font(regFont)
pleaseGen=false
doOnce=true
thicknessBase=1
xx1=0
yy1=0
xx2=0
yy2=0
doRGB=false//true
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
img=9 // previewer default mode 8 
prevFinalX=0

//state=1
rgbMask_GenState=0
norm_GenState=0
color_GenState=0
mask_GenState=0
id_GenState=0
depth_GenState=0
flow_GenState=0
ao_GenState=0
frizz_GenState=0


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

// directional colors
dirFlipX=1
dirFlipY=1
dirBlue=1
dirHue=0


avgLife=0
	
// NEW exposed variables in h 1.254

padding=0 // padding for color hairs (to be added)
scaleIn=1500//1000 // is this the scaling in length?
scaleOut=500 // scaling out
fadeIn=8//100 // set fade in speed (alpha)
fadeOut=12// // set fade out speed (alpha+scale)

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


seedUpdate=0
seedValstring=0
//randomize() // new seed value
makeRandom=0; // perhaps this can be disabled for some reason...
seedVal=random_get_seed() // get seed value
random_set_seed(seedVal)
str=""
str2=""
// PREVIEWER OPTI			
maxPreviewStrandsPerSet=100 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
optimalStep=44 // for optimising the display update (16) higher is more optimised 80/44/20

motionDetectMode=0

ColA_active=1
ColB_active=0
RootCol_active=0
TipCol_active=0
bkCol_active=0

getColorPick=make_color_rgb(255,255,255)

minScale=2
maxScale=3
// strand count/length overriding

nullify_sliderInterracts(); //reset all slider activity

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


renderToSurf=0

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

// custom coloring brown

// custom coloring defaults
colrBack=make_color_rgb(34,0,70)
colrCustom=make_color_rgb(12,8,5)
customColVarA=make_color_rgb(239,85,248)
customColVarB=make_color_rgb(36,28,210)
customRootCol=make_color_rgb(16,12,22)
customTipCol=make_color_rgb(150,100,250)
depthTone=make_color_rgb(0,0,0)

storeColor=customColVarA
newColor=customColVarA




idChoice=c_white // for storing the colour choise


deviationFromX=0 // we can use this for angling and flow map lerping
sc=1

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
colorMode=1 // rgb=0 hsv=1 grey=2
a=1

hexColEdit=false
editHexColor=""
hexColString=""
hexColR=""
hexColG=""
hexColB=""

canSave=true
saving=false
finalX=0
setXpos=0
//maxStrandsPerSet=200 // needs a max or crash
ampFactor=8 // boost wavyness...
tapering=10

sets=10 // only 11 used for now due to performance reasons
h=0
minFreq=1
maxFreq=10
straggleXX=0
strandDecision=0//random(100)/100
straggleChoice=0//choose(StragglePath_A,StragglePath_B,StragglePath_C);
freq=random(1000)/100
amp=random(100)/100 // essentially wavyness
nx=0
dpthAdd=0
j=0
root=0
tip=0
rt=0
tp=0
lifeVariant=6
rootRange=500
rootPosition=25
tipPosition=50 // is this when it comes in before the end?
wavyness=16 // how wavy? 15def
frizz=50 // frizz frequency with some range of deviation 10% or so.
//*********************************************
strands=10
diminish=4// how many less strands per set
//***********************************************
maxStrands=strands
sx=0
xx=0
distancings=21// new in version 1.287
setDistance=36 // extra distancings
//distanceSet=510 // extra distancings

setID=0
xxx=400; // preview window (zoom)
yyy=200;
yp=0;
strandCount=0;

retrigger=true;
hairLength=3600
life=hairLength
currentMapPreview=0 // before pressing shortcut keys
frizzColor=make_color_hsv(0,0,128)
mixer1=10
mixer2=2
mixer3=1
mixer1_offset=0
mixer2_offset=0
mixer3_offset=0

// SETUP 16 point paths that will be used for storing up to 4 clump paths per set
// these paths will be treated like strands and even be mimicked from the first 4 strands generated (if there is 4)
// predefine a base one
clumpPath=path_add()
path_set_closed(clumpPath,0) // not closed
path_set_kind(clumpPath,1) // smooth
path_add_point(clumpPath,0,0,0) // add a path point
path_add_point(clumpPath,1024,2048,0)
path_add_point(clumpPath,4096,4096,0)

// hack in some offsets
for (n=0;n<11;n++)
	{
	xOffset[n]=0
	yOffset[n]=0
	}

ghostSprite=-1
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

// FILE SAVE
canLoad=true
loading=false

theFile=""

mainS ="Hair Strand Designer - Project File - Version1.93.0 - 26thAug2026 (C) Robert Ramsay"
instr="Variable description (colon : ) VariableValue (semiColon ;)";

// NEW VARIABLE ARRAYS DEISGNED TO CACHE PRE-DATA for more accuracy of representation in the renderer (not sure if it will work)
// for v1.41
// remember randomized values from previewer so we can trnasfer those to 
// the final render, however, bear in mind the final render may be able to show us
// more... but we have capactiry of up to 60 strands per set that could have their
// details recalled in the renderer.

yjit=200


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
							strandDepth[setRands,strandNum]=0
			//strandColor[setRands,strandNum]=c_white
			}
		
		
	}

// make paths
//we will make paths that will act as flyaways
// these will need to be predefined but we can pick from them
// they should also have the ability to be resized
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

//tackle memory issue: 
surfSetAO=0
tog=1
mbx=0
mby=0
updatePreRands(-1) //-1 is all
	imgOverride = -1;
	// medium mode
	maxPreviewStrandsPerSet=50 // NUMBER OF PREVIEW STRANDS (8) lower is more optimised
	optimalStep=10 // for optimising the display update (16) higher is more optimised
	dynamicRes=0
			
			