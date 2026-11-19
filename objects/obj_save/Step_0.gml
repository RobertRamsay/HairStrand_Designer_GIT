/// @description obj_save: early project saver (not used)
// You can write your code in this editor
// -----------------------------------------------------------------------------
// obj_save Step. NOT USED: obj_save is never created (see its Create event).
//
// If it did run, every step it would open a save dialog and write a text file
// containing just three lines: the header (mainS), the instruction line
// (instr) and "Seed:<n>;". All the other writes are inside the block comment
// below. That is far short of what the loaders expect, so such a file is not
// a valid project. There is also no instance_destroy, so the dialog would
// reopen every step.
//
// The commented-out section shows the oldest layout of the file and is where
// the line order used by KeyPress_83 / doAutoSave started. Two differences
// from the live format: it loops over 10 sets (the live format uses 11) and
// it uses dec_to_hex for colours (the live savers use dec_to_hex_save, which
// gives the RRGGBB order the loaders read). Do not copy lines from here.
// -----------------------------------------------------------------------------
//keyboard_key_press(vk_enter) // auto Enter
			fileCustom = get_save_filename_ext("HSD_Project|*.txt", obj_surfaceDweller.prjName,"","Please save to a directory outside of the Application.");
			

		if fileCustom != ""
		    {
// initial line
			var theFile = file_text_open_write(fileCustom);
			
		file_text_write_string(theFile,string(mainS));
			file_text_writeln(theFile);
			
// instruction line			
		file_text_write_string(theFile,string(instr));
			file_text_writeln(theFile);
			
// main variables	
var o=obj_surfaceDweller
		file_text_write_string(theFile,"Seed:"+string(o.seedVal)+";");
			file_text_writeln(theFile);
			/*
			file_text_write_string(theFile,"Blur:"+string(o.var_blur_amount)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"IDmode:"+string(o.idMode)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doRGB:"+string(o.doRGB)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doNorm:"+string(o.doNorm)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doColor:"+string(o.doColor)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doMask:"+string(o.doMask)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doID:"+string(o.doID)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doDepth:"+string(o.doDepth)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doFlow:"+string(o.doFlow)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"doAO:"+string(o.doAO)+";");
			file_text_writeln(theFile);
				
			file_text_write_string(theFile,"Current map:"+string(o.img)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Flip X:"+string(o.dirFlipX)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Flip Y:"+string(o.dirFlipY)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Blue:"+string(o.dirBlue)+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Flow Map Hue:"+string(o.dirHue)+";");
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Scale In:"+string(o.scaleIn)+";");  // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Scale Out:"+string(o.scaleOut)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Fade In:"+string(o.fadeIn)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Global Fade Out:"+string(o.fadeOut)+";"); // internal
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Background Color (HEX):"+string(dec_to_hex(o.colrBack))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation Tone 1 (HEX):"+string(dec_to_hex(o.customColVarA))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Variation Tone 2 (HEX):"+string(dec_to_hex(o.customColVarB))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Root Color (HEX):"+string(dec_to_hex(o.customRootCol))+";"); 
			file_text_writeln(theFile);
			
			file_text_write_string(theFile,"Tip Color (HEX):"+string(dec_to_hex(o.customTipCol))+";"); 
			file_text_writeln(theFile);
			
			var sets = 10
			for (s=0;s<sets;s++) // support up to 10 sets potentaill greater later on
				{
				file_text_write_string(theFile,"Strand Count Override"+string(s)+":"+string(o.strandCountOverride[s])+";"); 
				file_text_writeln(theFile);
				file_text_write_string(theFile,"Strand Length Override"+string(s)+":"+string(o.strandLengthOverride[s])+";"); 
				file_text_writeln(theFile);
				
				}
	*/


/*
minScale
maxScale
colorMode
tapering
root
tip
lifeVariant
rootPosition
tipPosition
wavyness
strands
diminish
maxStrands
distancings
setDistance
currentMapPreview
	

*/


			

		
				file_text_close(theFile);
			}
				keyboard_clear(vk_enter) // clear Enter

				