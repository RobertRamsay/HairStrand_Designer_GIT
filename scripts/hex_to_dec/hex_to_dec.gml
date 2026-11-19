// -----------------------------------------------------------------------------
// hex_to_dec(hexString)  -  hex text to a number, e.g. "FF" gives 255
//
// Upper or lower case. An empty string gives 0.
//
// Used in two places:
//   - the project loaders (doAutoLoad, KeyPress_76): each saved colour is six
//     hex digits RRGGBB; they call this on each pair and feed the three
//     results to make_color_rgb. A saved colour can be shorter than six digits
//     (see dec_to_hex_save); the missing pairs arrive here as "" and give 0.
//   - Draw_0, when a hex colour is typed into the colour panel's hex box.
//
// A character that is not 0-9 or A-F is NOT rejected: the total is still
// shifted, so it counts as a 0 digit ("1G" gives 16). The error line for that
// case is commented out below.
// -----------------------------------------------------------------------------
function hex_to_dec(argument0) {
	var result=0;

	// special unicode values
	var ZERO=ord("0");
	var NINE=ord("9");
	var A=ord("A");
	var F=ord("F");

	for (var i=1; i<=string_length(argument0); i++){
	    var c=ord(string_char_at(string_upper(argument0), i));
	    // you could also multiply by 16 but you get more nerd points for bitshifts
	    result=result<<4;
	    // if the character is a number or letter, add the value
	    // it represents to the total
	    if (c>=ZERO&&c<=NINE){
	        result=result+(c-ZERO);
	    } else if (c>=A&&c<=F){
	        result=result+(c-A+10);
	    // otherwise complain
	    } else {
	        // this will make the browser behave badly but you can leave it in
	        // actual game maker if you want
	        //show_error("bad input for hex(str)", true);
	    }
	}

	return result;


}
