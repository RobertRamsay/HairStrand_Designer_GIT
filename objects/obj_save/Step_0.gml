/// @description Insert description here
// You can write your code in this editor
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

				