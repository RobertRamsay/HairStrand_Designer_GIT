// -----------------------------------------------------------------------------
// analise_HexToDec(line)  -  NOT USED
//
// Nothing in the project calls this (checked: no other script or object event
// mentions it). It is a copy of analise() with a longer copy length
// ("-(a-1)" instead of "-a"), which makes no difference to the result because
// string_copy stops at the end of the line anyway. Despite the name it does no
// hex conversion: it returns real() of the text after the colon.
//
// The loaders read hex colours with analiseString() + hex_to_dec() instead.
// Safe to ignore when debugging save/load.
// -----------------------------------------------------------------------------
function analise_HexToDec(argument0) {
				for (a=1;a<string_length(argument0);a++)
					{
					if string_char_at(argument0,a)=":" // start of important bit
						{
							return real(string_copy(argument0,a+1,string_length(argument0)-(a-1))) // transfer contents 
							//seedVal=real(string_copy(argument0,a+1,string_length(argument0)-a)) // transfer contents 
							break; // escape loop
						}
					}
				



}
