/*Title: Read sequentialy files from Incell and save hyperstack
 * Version: V1.4
*
* Short description: Input InCell isolated tiff files, searching for wells (lines, columns) and fields. 
* Create hyperstack for each field, (xyzct) and save as tiff.
* 
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: March/2019
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/
//Define folders (input and output)

#@ String(value="Select image' path and an empty folder for the output results                                                                     ", visibility="MESSAGE") hint;
#@ File (label = "Select file input ", style = "file") source_input
#@ File (label = "Select output directory", style = "directory") output_dir
#@ String (label = "File suffix", value = ".tif") ext

files = getFileList(source_input);

well_line = newArray("A", "B", "C", "D", "E","F","G","H","I","J","K","L","M","N","0","P");
well_col = newArray("1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24");
//file_pattern = newArray("wv TL-Brightfield - DAPI","wv Cy3 - Cy3","wv DAPI - DAPI","wv FITC - FITC","wv TexasRed - TexasRed");

//Set Parameters
Dialog.create("File information");
Dialog.addNumber("Nº of channels (c)", 1);
Dialog.addNumber("Nº of fields (f)", 1);
Dialog.addNumber("Nº of slices (z)", 1);
Dialog.addNumber("Nº of time points (t)", 1);
Dialog.addChoice("Hyperstack order", newArray("xyczt(default)", "xyctz","xyzct","xyztc","xytcz","xytzc"),"xyczt");
Dialog.show();

channels = Dialog.getNumber();
field_number = Dialog.getNumber();
slices = Dialog.getNumber();
frames = Dialog.getNumber();
order = Dialog.getChoice();

if(channels < 1 || field_number < 1 || slices < 1 || frames < 1){
	exit("Input variables must be higher than 0 ");
}

if(isNaN(channels) || isNaN(field_number) || isNaN(slices)|| isNaN(frames)){
	exit("Input variables must have integer values");
}
//Verify possible file names
path = File.getParent(source_input);
file = File.getNameWithoutExtension(source_input);

if(indexOf(file,"wv")!=-1){
	file_pattern = substring(file, indexOf(file,"wv")-1, indexOf(file, ")"));	
}
else{
	if(slices == 1)
		file_pattern = substring(file, indexOf(file,"- time"), indexOf(file, ")"));	 
	else 
		file_pattern = substring(file, indexOf(file," z"), indexOf(file, ")"));	 
}


idx_filepattern = indexOf(file, file_pattern);
file_name_start = substring(file, 0,idx_filepattern); 

//check if it contains fld
if (endsWith(file_name_start,"(")) {
	field_start_name = "( ";
}
else {	
	field_start_name = "(fld";	
}
idx_field_pattern = indexOf(file, "(");


//check well start number format
id1 = indexOf(file_name_start, "-");
id2 = indexOf(file_name_start, "(");
well_format = substring(file_name_start, id1 + 2, id2);

if (startsWith(well_format,"0")) {
	well_start_number = "0";	
}
else {
	well_start_number = "";
}

setBatchMode(true);

//search all lines, columns and fields
for (line=0; line<well_line.length; line++){
	for (col=0; col<well_col.length; col++){

		print("Wait until is DONE!");
		
		column = checkNumber(well_start_number,parseInt(well_col[col]));
		
		file_start_name = well_line[line] + " - " + column;	
		for (f = 1; f <= field_number; f++){
			if (field_number == 1) {
				field_name = substring(file_name_start, idx_field_pattern , file_name_start.length());
			}
			else{
				fld = checkfld(file_name_start,f);
				field_name = field_start_name + fld + f;
			}
			
			filename = path + File.separator + file_start_name + field_name + file_pattern + ").tif";

			print(filename);	
						
			title = file_start_name + field_name + ")-stack";		
			
	    	if(File.exists(filename)){	
	    		print(file_start_name + field_name );
	    		run("Image Sequence...", "open=[" + filename + "] number=" + channels*frames*slices + " file=[" + file_start_name + field_name +"] sort");
	    		
	    		if (channels > 1 || frames > 1 || slices > 1) {
	    			
					run("Stack to Hyperstack...", "order=" + order + " channels="+ channels +" slices=" + slices + " frames=" + frames + " display=Color");
	    			
					print("Warning! Please confirm image properties (pixel width, voxel depth and time frame!");
					wind = getTitle();		
					selectWindow(wind);
					saveAs("Tiff", output_dir + File.separator + title +".tif");
	    		}
	    		else{
	    			saveAs("Tiff", output_dir + File.separator + file_start_name + field_name + file_pattern + ").tif");
	    		}
				
								
				close();
			}
			else { 
				continue;
			}		
	
		}
	}
}

function checkNumber(suffix, index){
	
	if(index<10)
		aux = "" + suffix + index;
	else 
		aux = index;

	return aux;
}

function checkfld(field,f) {	
	idx1 = indexOf(field, "d");
	idx2 = lengthOf(field);
	
	if(f<10){
		if((idx2-idx1) == 3 )
			aux = " ";
		else if ((idx2-idx1) == 4) 
			aux = " 0";
		else if ((idx2-idx1) == 5)
			aux = " 00"; 	
	}
	else if(f>=10 && f<100){
		
		if((idx2-idx1) == 5 )
			aux = " 0";
		else  
			aux = " ";		
	}
	else{
		aux = " ";
	}
	
	return aux;
}


print("DONE");

