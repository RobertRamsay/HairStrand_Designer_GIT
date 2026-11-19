// -----------------------------------------------------------------------------
// analise(line)  -  the NUMBER after the first colon of a project-file line
//
// Project files are lines of "Description:value;". This returns the value as
// a real, e.g. analise("Seed:1234;") gives 1234. The description is ignored:
// the loaders know what a line means only from its position in the file.
//
// Used by the positional loaders: doAutoLoad and KeyPress_76 (L key).
//
// Things to know when a load goes wrong:
//   - the text handed to real() still ends in ";" (it copies to the end of
//     the line). The loaders rely on real() accepting that. analiseString
//     strips the ";" and is the safer one for new code: real(analiseString(x)).
//   - a line with no colon returns nothing (undefined), and so does a line
//     whose only colon is its last character, because the loop stops one
//     short of the end. The variable being loaded then becomes undefined.
//   - a value that does not start with a number makes real() throw.
//   - the loop counter a is an instance variable of the caller, not a local.
// -----------------------------------------------------------------------------
function analise(argument0) {
				for (a=1;a<string_length(argument0);a++)
					{
					if string_char_at(argument0,a)=":" // start of important bit
						{
							return real(string_copy(argument0,a+1,string_length(argument0)-a)) // transfer contents 
							//seedVal=real(string_copy(argument0,a+1,string_length(argument0)-a)) // transfer contents 
							break; // escape loop (never reached: the return above already left)
						}
					}


}
