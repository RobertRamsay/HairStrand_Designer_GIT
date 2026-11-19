// =============================================================================
// g : Key Press S  -  arm the manual-save follow-up (backup copy)
//
// 83 is the key code for S. Fires on the frame S goes down, which includes the
// fake S press Draw_0 makes when the Save / Export buttons are clicked.
// Does the same four lines as the S test in this object's Begin Step; this
// copy is a safety net in case that test did not see the press.
// Setting the flags twice in one frame is harmless.
//
// What the flags mean (all on obj_surfaceDweller):
//   mainS                  the header line the saver is about to write. Forced
//                          to the current version so the file is marked 1.96.
//   v185ManualSavePending  1 = a manual save is happening; Alarm 1 must append
//                          the V1.85 colour, V1.96 Clumping and V1.96 Set
//                          Extras blocks to it.
//   v185ManualSavePath     the chosen file. Cleared here; canvasCheck fills it
//                          in at End Step, once the save dialog has returned.
//   alarm[1]=2             run Alarm 1 two steps from now, i.e. after
//                          obj_surfaceDweller's own S-key event (KeyPress_83)
//                          has written and closed the file.
//
// Nothing is armed in the demo (demoMode==1) or while canSave is false, the
// same test the saver itself uses, so Alarm 1 never appends to a file that
// was not written.
// If the user cancels the save dialog, the flag is still set; Alarm 1 then
// finds no valid path and does nothing.
// =============================================================================
// Backup latch for the legacy obj_surfaceDweller S-key saver.
// The actual 1.85 block is written once by Alarm 1 after the project file closes.
if instance_exists(obj_surfaceDweller)
    {
    with (obj_surfaceDweller)
        {
        if canSave and demoMode==0
            {
            mainS="Hair Strand Designer - Project File - Version1.96.0 - 9thNov2026 (C) Robert Ramsay"
            v185ManualSavePending=1
            v185ManualSavePath=""
            alarm[1]=2
            }
        }
    }
