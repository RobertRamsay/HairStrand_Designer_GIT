// Backup latch for the legacy obj_surfaceDweller S-key saver.
// The actual 1.85 block is written once by Alarm 1 after the project file closes.
if instance_exists(obj_surfaceDweller)
    {
    with (obj_surfaceDweller)
        {
        if canSave and demoMode==0
            {
            mainS="Hair Strand Designer - Project File - Version1.92.0 - 26thAug2026 (C) Robert Ramsay"
            v185ManualSavePending=1
            v185ManualSavePath=""
            alarm[1]=2
            }
        }
    }
