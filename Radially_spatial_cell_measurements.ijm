/* Title: Radially spatial cell measurements
 * Version:
*
* Short description: Input stack files with CY3 in the first channel (result from macro FromInCellToHyperstack) 
* and the corresponding cell contours (result from Cellprofiler). Create 2 bands from the original contour 
* with "band_with" specified by the user. Measure area and intensity inside each band, for each cell and save it as an excel file
* 
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: October/2019
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/

#@ File (label = "Select input original images directory", style = "directory") input
#@ File (label = "Select overlay image ", style = "directory") overlays
#@ File (label = "Select uutput directory", style = "directory") output
#@ Integer (label = "Band width", value = "4") band_width
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

setBatchMode(true);

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	//process for each file
	print("Processing: " + input + File.separator + file);
	roiManager("reset");
	
	//open original stack (1st channel is cy3)
	open(input + File.separator + file);
	original_stack = getTitle();

	//get overlay name from the original name
	dotIndex = lastIndexOf( original_stack, "wv");
	title_begin = substring( original_stack , 0, dotIndex);
	overlay = title_begin + "wv Cy3 - Cy3)maskcells.tiff";	
		
	//get only Cy3 channel
	run("Duplicate...", "title=Cy3");	
	selectWindow(original_stack);
	close();

	//open overlay image
	print(overlays + File.separator + overlay);
	open(overlays + File.separator + overlay);
	overlay_image = getTitle();

	//Invert since overlay image is 0 value for bands
	run("Invert");

	//get each contour, exclude on the edge of the image and add to RoiManager
	run("Analyze Particles...", "exclude add");

	//Perform roi manipulations to get the 3 bands (enlarge -, XOR, twice)
	number_cells = roiManager("count"); 
	roi1 = newArray(number_cells);
	roi2 = newArray(number_cells);
	roi3 = newArray(number_cells);
	
	for (r = 0; r < number_cells; r++) {
		indx = 4*r +number_cells;
		roiManager("select", r);
		run("Enlarge...", "enlarge=-" + band_width); //reduce roi
		roiManager("Add");		
		roiManager("select", newArray(r,indx));	
		roiManager("XOR");
		roiManager("Add");
		roiManager("select", indx);
		run("Enlarge...", "enlarge=-" + band_width);
		roiManager("Add");	
		roiManager("select", newArray(indx,indx+2));	
		roiManager("XOR");
		roiManager("Add");
		roi1[r] = indx+1;  //outside band
		roi2[r] = indx+3;	//intermediate band
		roi3[r] = indx+2;	//inside band				
	}

	selectWindow("Cy3");	
	//create Results table to store the measurements
	title1 = "Results table";
	title2 = "["+title1+"]";
	f=title2;
	run("New... ", "name="+title2+" type=Table");
	print(f,"\\Headings:Cell\tArea_Roi1\tMean_Roi1\tArea_Roi2\tMean_Roi2\tArea_Roi3\tMean_Roi3");

	//Measure the three bands for each cell
	for (s = 0; s < number_cells; s++) {
		roiManager("select", newArray(roi1[s],roi2[s],roi3[s]));
		roiManager("Multi Measure");
		headings = split(String.getResultsHeadings);
		line = "";
		for (a=0; a<lengthOf(headings); a++)
    		line = line + getResult(headings[a],0) + "\t";
		
		array_line = split(line, "\t");
		print(f,s+"\t"+array_line[0]+"\t"+array_line[1]+"\t"+array_line[4]+"\t"+array_line[5]+"\t"+array_line[2]+"\t"+array_line[3]); //change the order of rois to be: outside, intermediate, inside 	
	}

	//save output image with bands and results table
	roiManager("show all");
	saveAs("tiff",output + File.separator + title_begin );	
	run("Close All");
	selectWindow("Results table");
	saveAs("Text", output + File.separator + title_begin + ".xls");
	close("Results table");
}
