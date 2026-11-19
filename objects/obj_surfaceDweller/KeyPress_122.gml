/// @description Key F11 - disabled (old quick-load)
// -----------------------------------------------------------------------------
// EVENT : Key Press, key code 122 = F11.
// DOES  : nothing. The game_load() quick-load below was marked BROKEN and commented
//         out. It was the partner of F12 (KeyPress_123), which still writes a
//         game_save() snapshot that nothing can load back.
// -----------------------------------------------------------------------------

// BROKEN
//if firstTime==false {instance_create_depth(0,0,-100,obj_loadMessage) ;game_load(game_id)}