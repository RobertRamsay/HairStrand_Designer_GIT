/// @description Key P - view strand previewer
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 80 = "P". Runs once on the frame the key goes down.
// DOES  : switches the viewer to the strand previewer (img=9 // back to the live strand previewer).
// WRITES: currentMapPreview (the view we came from - nothing reads it back), img.
// NOTE  : img = which map the 1024x1024 viewer shows:
//           0 RGB mask, 1 normal, 2 ID, 3 depth, 4 colour, 5 mask, 6 flow,
//           7 AO, 8 frizz, 9 strand previewer.
//         Draw_0 reads img to pick the canvas; previewUpdate() (previewJob) only
//         rebuilds preview strands while img==9. A map view shows whatever was
//         last rendered with G - pressing this key does not render anything.
//         This is the normal working view: sliders give live feedback here.
// -----------------------------------------------------------------------------
currentMapPreview=img
img=9