/// @description Alarm 0 - un-press the dice button
// -----------------------------------------------------------------------------
// EVENT : Alarm 0. Set to 2 frames by the dice button in Draw_0 (left or right click).
// DOES  : makeRandom back to 0. makeRandom is the frame of spr_dice, so this is
//         what makes the dice pop back up after a click. The next left click then
//         flips it to 1 again, which is what calls randomize().
// -----------------------------------------------------------------------------
makeRandom=0