// -----------------------------------------------------------------------------
// dec_to_hex(number)  -  a number as hex text, in whole bytes ("00", "1A2B" ...)
//
// Standard GMLscripts.com routine. Most significant byte first, the usual way
// to write a hex number. 0 gives "00".
//
// IN THIS PROJECT it is used for DISPLAY only: Draw_0 calls it on the red,
// green and blue parts of a colour separately to build the text in the colour
// panel's hex box. (obj_save also mentions it, but only inside a commented-out
// block.)
//
// It is NOT what the project file uses. A GameMaker colour number holds blue
// in its top byte and red in its bottom byte, so this routine applied to a
// whole colour would give BBGGRR. Saving uses dec_to_hex_save, which gives
// RRGGBB, the order the loaders expect.
// -----------------------------------------------------------------------------
function dec_to_hex(argument0) {

	/// dec_to_hex(dec)
	//
	//  Returns a string of hexadecimal digits (4 bits each)
	//  representing the given decimal integer. Hexadecimal
	//  strings are padded to byte-sized pairs of digits.
	//
	//      dec         non-negative integer, real
	//
	/// GMLscripts.com/license
	{
	    var dec, hex, h, byte, hi, lo;
	    dec = argument0;

	 if (dec) hex = ""  else hex="00";
	    h = "0123456789ABCDEF";
	    while (dec) {
	        byte = dec & 255;
	        hi = string_char_at(h, byte div 16 + 1);
	        lo = string_char_at(h, byte mod 16 + 1);
	        hex = hi + lo + hex;
	        dec = dec >> 8;
	    }

	    return hex;
	}




}
