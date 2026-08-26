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
