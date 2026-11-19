/// @description Alarm 2 - play the alert sound (currently never scheduled)
// -----------------------------------------------------------------------------
// EVENT : Alarm 2.
// DOES  : plays Sound1 once.
// NOTE  : nothing in the project sets alarm[2] at present, so this never fires.
//         Sound1 is also played directly by Step_1 when a canvas surface is lost.
// -----------------------------------------------------------------------------
audio_play_sound(Sound1,1,0)