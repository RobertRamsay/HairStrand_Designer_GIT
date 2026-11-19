/// @description Key N - view normal map
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 78 = "N". Runs once on the frame the key goes down.
// DOES  : switches the viewer to the normal map (img=1).
// WRITES: currentMapPreview (the view we came from - nothing reads it back), img.
// NOTE  : img = which map the 1024x1024 viewer shows:
//           0 RGB mask, 1 normal, 2 ID, 3 depth, 4 colour, 5 mask, 6 flow,
//           7 AO, 8 frizz, 9 strand previewer.
//         Draw_0 reads img to pick the canvas; previewUpdate() (previewJob) only
//         rebuilds preview strands while img==9. A map view shows whatever was
//         last rendered with G - pressing this key does not render anything.
// GUARD : skipped while exiting==true, because N is also the "No" answer to the
//         quit dialog drawn at the end of Draw_0.
// -----------------------------------------------------------------------------

if !exiting
{
currentMapPreview=img
img=1 // show normal map
}



