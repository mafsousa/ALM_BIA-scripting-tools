/* Title: Wound healing 
* v0.2
* Short description: Input tiff file with time stack. For each time frame perform gaussian blur; 
* apply Variance filter with radius = 5. Apply default threshold default with upperthreslhold*0.1; 
* Analyse particles with minimum size = 8000; Measure area of each Roi;
*  
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: June/2019
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/

#@ File (label = "Select input image", style = "file") filename
#@ File (label = "Select output directory", style = "directory") outDir
#@ String (label = "File suffix", value = ".tif") ext

run("Close All");
roiManager("reset");
print(filename);

//open file
if(File.exists(filename) && (endsWith(filename, ext))){
	open(filename);
	//Reduce image size for better computer performance
	run("Scale...", "x=0.5 y=0.5 z=1.0 width=512 height=512 depth="+ nSlices + " interpolation=Bilinear average process create");
	run("Select All");
	w = getWidth;
	h = getHeight;
	img=getTitle();		//original image
	run("Duplicate...", "duplicate");
	//Preprocess
	run("Subtract Background...", "rolling=10 light stack");
	run("Gaussian Blur...", "sigma=3 stack");
	resetMinAndMax();
	//Convert to 8 bits
	run("8-bit");
	//run("Gray Morphology", "radius=1 type=circle operator=dilate");
	run("Variance...", "radius=5 stack");
	
	imgP=getTitle();		//preprocessed-image
	
	//Segmentation
	setAutoThreshold("Default");
	getThreshold(lower, upper);
	setThreshold(lower, upper*0.1);
	
	//Post-processing
	run("Options...", "iterations=1 count=1 do=Open stack");
	
	//Find wound countours
	run("Analyze Particles...", "size=8000.00-Infinity show=Masks display clear include add stack");
	
	//Save Results
	selectWindow("Results");
	saveAs("Results",outDir + File.separator + img + ".xls");

	//Preview result	
	selectWindow(imgP);
	close();
	selectWindow(img);
	roiManager("Select", 0);
}
else{
	showMessage("Invalid input file");
	break;
}