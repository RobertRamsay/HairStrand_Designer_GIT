/// @description obj_wait: the "please wait" picture during generation
// You can write your code in this editor
// =============================================================================
// OBJECT obj_wait  -  "generating, please wait" sign.  IN USE.
//
// Not placed in a room and has only this event. obj_surfaceDweller Draw_0
// creates one (depth -1000) when a full generate is started (G key or the
// Generate button), and this draws spr_genWait in the middle of the canvas
// (512,512) on the GUI layer.
//
// It is removed in two places:
//   - obj_surfaceDweller Draw_0 destroys it when the left mouse button is
//     released
//   - doMainStep, if it finds one, destroys it and at the same time sets
//     generating=false, pleaseGen=false and resets renderF/renderH.
// So the object is more than a picture: its presence makes doMainStep reset
// those generation variables. Read that part of doMainStep before changing
// when this object is created or destroyed.
// =============================================================================

//draw_text(20,1000,"PLEASE WAIT.. GENERATING STRANDS AND MAPS... MORE STRANDS = MORE TIME.")
draw_sprite(spr_genWait,0,512,512)


