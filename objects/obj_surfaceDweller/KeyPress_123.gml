/// @description Key F12 - game_save snapshot (legacy, nothing loads it)
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 123 = F12.
// DOES  : once the splash has been dismissed (firstTime==false), writes a GameMaker
//         game_save() snapshot. The matching loader (F11, KeyPress_122) is disabled,
//         so this is effectively dead. Real persistence is Autosave.txt (doAutoSave)
//         and the S-key project file (KeyPress_83 + Alarm 1).
// NOTE  : the commented block would have flagged every finished map (GenState 2)
//         for re-render (GenState 1) before saving.
// -----------------------------------------------------------------------------



/*
if id_GenState==2 id_GenState=1
if ao_GenState==2 ao_GenState=1
if flow_GenState==2 flow_GenState=1
if mask_GenState==2 mask_GenState=1
if rgbMask_GenState==2 rgbMask_GenState=1
if frizz_GenState==2 frizz_GenState=1
if color_GenState==2 color_GenState=1
if norm_GenState==2 norm_GenState=1
if depth_GenState==2 depth_GenState=1
*/


if firstTime==false game_save(game_id)

