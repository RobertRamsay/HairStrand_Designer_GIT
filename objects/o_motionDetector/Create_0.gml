// =============================================================================
// OBJECT o_motionDetector  -  "is the mouse moving fast?" sensor.  IN USE
// (placed in Room_HSD, persistent), but its result only matters in one mode.
//
// An invisible point that chases the mouse, covering a fifth (spd) of the
// remaining gap each step. While the mouse is still the point sits on it and
// distToMouse is about 0; when the mouse moves quickly the point falls behind
// and distToMouse grows. So distToMouse is a rough mouse-speed reading.
//
// Read in one place: obj_surfaceDweller Step_1. If distToMouse > 20 while
// dynamicRes==1 and motionDetectMode==1, the preview is switched to a coarse
// step (optimalStep=120) so it stays responsive during fast drags.
// motionDetectMode starts at 0 and is toggled with F2; dynamicRes is the DYNA
// preview mode. With either off this object has no visible effect. It must
// still exist: Step_1 reads o_motionDetector.distToMouse every frame and would
// crash without an instance.
// =============================================================================
x=mouse_x
y=mouse_y
distToMouse=1 // pixels between this point and the mouse; updated every Step
spd=0.2       // fraction of the gap closed per step: higher = catches up sooner = less sensitive
