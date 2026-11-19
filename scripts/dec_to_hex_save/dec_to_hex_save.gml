// -----------------------------------------------------------------------------
// dec_to_hex_save(colour)  -  a GameMaker colour as "RRGGBB" text for the
//                             project file
//
// Used by both savers (doAutoSave and KeyPress_83) for the five colour lines:
// Background, Variation Tone 1 and 2, Root, Tip. Read back by the loaders with
// analiseString() + hex_to_dec() on character pairs 1-2, 3-4, 5-6.
//
// HOW IT GETS RRGGBB
//   A GameMaker colour number has red in its lowest byte, then green, then
//   blue. The loop peels off the LOWEST byte first and APPENDS it
//   (hex = hex + hi + lo; dec_to_hex prepends instead), so the text comes out
//   red first.
//
// THINGS THAT LOOK WRONG BUT ARE NOT
//   - The result can be shorter than six characters. The loop stops when the
//     remaining number is 0, so trailing zero bytes are not written: pure red
//     is "FF", black is "". The loaders read the missing pairs as 0.
//   - The variable names below are misleading. hexBlue holds characters 1-2,
//     which is RED, and hexRed holds 5-6, which is BLUE. They are joined back
//     in the same order they were taken, so that whole step changes nothing.
//   - "if argument0==0 hex=..." is immediately overridden by the "var hex"
//     line after it; black still comes out as "".
//
// The header text below (from the original dec_to_hex) no longer describes
// this function: it does not pad to pairs for 0 and it is byte-reversed.
//
// If the order here is ever changed, the string_copy positions in both loaders
// (doAutoLoad, KeyPress_76) must change with it, and files saved before the
// change would then load with red and blue swapped.
// -----------------------------------------------------------------------------
function dec_to_hex_save(argument0) {

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
		if argument0==0 hex="" 
	  //  if (dec) hex = ""  else hex="00";
	   var hex=""
	    h = "0123456789ABCDEF";
	    while (dec) { // one pass per byte, lowest (red) first
	        byte = dec & 255;
	        hi = string_char_at(h, byte div 16 + 1);
	        lo = string_char_at(h, byte mod 16 + 1);
	        hex = hex + hi + lo;
	        dec = dec >> 8;
	    }
		var oldhex=string_copy(hex,1,6); // at most three bytes: drops anything above blue
		var hexBlue = string_copy(oldhex,1,2) // copy R
		var hexGreen = string_copy(oldhex,3,2) // copy G
		var hexRed = string_copy(oldhex,5,2) // copy B
		var newhex="";
		 newhex=hexBlue+hexGreen+hexRed // reconstructed
		 
		 //if hexBlue==00 hex=hexGreen+hexBlue+hexRed // reconstructed
		// i'd like to swap R for B here so that it is readable,
		// if so , be sure to change the reading (loading file)
	
	    return newhex;
	}




}
