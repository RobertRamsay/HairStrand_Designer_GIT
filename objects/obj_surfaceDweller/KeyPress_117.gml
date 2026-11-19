/// @description Key F6 - restart the program
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 117 = F6. Also "tapped" by the Restart button in
//         Draw_64 (function-key button block).
// DOES  : game_restart(). Everything in Create_0 runs again. With autosave on,
//         Autosave.txt is kept and the splash offers LOAD AUTOSAVE.
// NOTE  : no RegenCheck.txt is written here, so the splash screen is shown again
//         (compare the surface-loss restart in Step_1, which skips the splash).
// -----------------------------------------------------------------------------
// reset the game



game_restart()