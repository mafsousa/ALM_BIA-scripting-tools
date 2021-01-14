/*Title: Read sequentialy files from Incell and save hyperstack
 * Version: V0.1
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
* Date: Sept/2019
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/

source_dir = getDirectory("Select source Directory");
output_dir = getDirectory("Select output Directory");
well_line = newArray("A", "B", "C", "D", "E","F","G","H");
well_col = newArray("01","02","02","04","05","06","07","08","09","10","11","12");


//Set Parameters
Dialog.create("File information");
Dialog.addNumber("Nº of channels (c)", 4);
Dialog.addNumber("Nº of fields (f)", 9);
Dialog.addNumber("Nº of slices (z)", 1);
Dialog.addNumber("Nº of time points (t)", 1);
Dialog.show();

channels=Dialog.getNumber();
field_number = Dialog.getNumber();
slices=Dialog.getNumber();
frames=Dialog.getNumber();

print(field_number);
setBatchMode(true);

//search all lines, columns and fields
for (line=0; line<well_line.length; line++){
	for (col=0; col<well_col.length; col++){
		file_start_name = well_line[line] + " - " + well_col[col];			
		
		for (f = 1; f <= field_number; f++){
			if (f<10)
				field_name = "(fld 00" + f;
			else if (f>=100)
 				field_name = "(fld " + f;
			else 
				field_name = "(fld 0" + f;
			
			filename = source_dir + File.separator + file_start_name + field_name + " wv DAPI - DAPI).tif";
			dotIndex = lastIndexOf( file_start_name + field_name + " wv DAPI - DAPI).tif", '.');
			title = substring( file_start_name + field_name + " wv DAPI - DAPI).tif", 0, dotIndex) + "_" + field_name;			
    		
			if(File.exists(filename)){						
				run("Image Sequence...", "open=[" + source_dir+ File.separator + file_start_name + field_name + " wv DAPI - DAPI).tif] number=" + channels + " file=[" + file_start_name + field_name +"] sort use");
			}else { 
				continue;
			}
			//convert to hyperstack
			run("Stack to Hyperstack...", "order=xyczt(default) channels="+ channels +" slices=" + slices + " frames=" + frames + " display=Color");
			wind = getTitle();
	
			selectWindow(wind);
			saveAs("Tiff", output_dir + File.separator + title +".tif");
			
			close();

		}
	}
}

