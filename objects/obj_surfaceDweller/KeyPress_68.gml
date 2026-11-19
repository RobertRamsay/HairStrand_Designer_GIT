/// @description Key D - view depth map
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 68 = "D". Runs once on the frame the key goes down.
// DOES  : switches the viewer to the depth map (img=3).
// WRITES: currentMapPreview (the view we came from - nothing reads it back), img.
// NOTE  : img = which map the 1024x1024 viewer shows:
//           0 RGB mask, 1 normal, 2 ID, 3 depth, 4 colour, 5 mask, 6 flow,
//           7 AO, 8 frizz, 9 strand previewer.
//         Draw_0 reads img to pick the canvas; previewUpdate() (previewJob) only
//         rebuilds preview strands while img==9. A map view shows whatever was
//         last rendered with G - pressing this key does not render anything.
// -----------------------------------------------------------------------------
currentMapPreview=img
img=3 // show depth map



