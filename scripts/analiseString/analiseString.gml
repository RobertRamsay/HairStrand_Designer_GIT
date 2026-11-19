// -----------------------------------------------------------------------------
// analiseString(line)  -  the TEXT after the first colon, without the final ";"
//
// For a project-file line "Description:value;" this returns "value" as a
// string. e.g. analiseString("Root Color (HEX):A1B2C3;") gives "A1B2C3".
// Callers wrap it in real() when they want a number.
//
// Used by doAutoLoad, KeyPress_76 and Alarm 1 for the hex colours, the mixer
// path points and every section from V1.5 onward.
//
// The "-a-1" in the copy length is what drops the last character. It drops it
// whatever it is, so a line written without the closing ";" loses its final
// digit. Always write lines as name + ":" + value + ";".
// A line with no colon returns nothing (undefined); real() of that throws.
// The loop counter a is an instance variable of the caller, not a local.
// -----------------------------------------------------------------------------
function analiseString(argument0) {
				for (a=1;a<string_length(argument0);a++)
					{
					if string_char_at(argument0,a)=":" // start of important bit
						{
							return (string_copy(argument0,a+1,string_length(argument0)-a-1)) // transfer contents 
							//seedVal=real(string_copy(argument0,a+1,string_length(argument0)-a)) // transfer contents 
							break; // escape loop (never reached: the return above already left)
						}
					}


}
