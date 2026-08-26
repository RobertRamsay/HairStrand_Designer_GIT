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
	    while (dec) {
	        byte = dec & 255;
	        hi = string_char_at(h, byte div 16 + 1);
	        lo = string_char_at(h, byte mod 16 + 1);
	        hex = hex + hi + lo;
	        dec = dec >> 8;
	    }
		var oldhex=string_copy(hex,1,6);
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
