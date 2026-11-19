/// @description Key A - view AO map
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 65 = "A". Runs once on the frame the key goes down.
// DOES  : switches the viewer to the AO map (img=7).
// WRITES: currentMapPreview (the view we came from - nothing reads it back), img.
// NOTE  : img = which map the 1024x1024 viewer shows:
//           0 RGB mask, 1 normal, 2 ID, 3 depth, 4 colour, 5 mask, 6 flow,
//           7 AO, 8 frizz, 9 strand previewer.
//         Draw_0 reads img to pick the canvas; previewUpdate() (previewJob) only
//         rebuilds preview strands while img==9. A map view shows whatever was
//         last rendered with G - pressing this key does not render anything.
// -----------------------------------------------------------------------------
currentMapPreview=img
img=7 // show AO map (old comment said flowmap; 7 is AO, 6 is flow)


