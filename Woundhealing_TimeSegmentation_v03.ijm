/* Title: Wound healing area time segmentation
* v0.3
* Short description: Input tiff file with time stack. For each time frame perform subtract background, gaussian blur; 
* Apply threshold with lowerthreslhold*1.05; 
* Analyse particles with minimum size = 10% of width+heigth; Measure area of each Roi for each frame;
*  
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: January/2021
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
	width = getWidth();
	height = getHeight();
	if (width>1000) { //to heavy to process
		run("Scale...", "x=0.5 y=0.5 z=1.0 width=" + round(width/2) + " height=" + round(height/2) + " depth="+ nSlices + " interpolation=Bilinear average process create");
	}
	setOption("ScaleConversions", true);
	resetMinAndMax();
	run("8-bit");
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
	Satisfied = false;
	while (Satisfied==false) {
		Dialog.create("Algorithm parameters");
		Dialog.addMessage("Select algorithm parameters");
		Dialog.addNumber("Gaussian sigma", 5);
		Dialog.addNumber("Backgroung radius", 10);
		items = newArray("Minimum","Otsu","Li","MaxEntropy","Default");
		Dialog.addChoice("Threshold algorithm", items);
		Dialog.show();
	
		sigma = Dialog.getNumber();
		radius = Dialog.getNumber();
		thres = Dialog.getChoice();
		//Reduce image size for better computer performance
		
		run("Select All");
		img=getTitle();		//original image
		run("Duplicate...", "duplicate");
		//Preprocess
		run("Subtract Background...", "rolling=" + radius + " light stack");
		run("Gaussian Blur...", "sigma=" + sigma + " stack");
		resetMinAndMax();
		
		imgP=getTitle();		//preprocessed-image
		
		//Segmentation
		setAutoThreshold(thres + " dark");
		getThreshold(lower, upper);
		setThreshold(lower, upper*1.05);
		
		//Post-processing
		run("Options...", "iterations=1 count=1 do=Open stack");
		
		//Find wound countours
		run("Set Measurements...", "area display redirect=None decimal=2");
		MinArea = width * 0.10 * height; 
		run("Analyze Particles...", "size=" + MinArea + "-Infinity show=Masks display clear include add stack");

		waitForUser("Check WoundHealing Result", "Check the quality of output\nThen click OK.");
		Dialog.create("Satisfied with WoundHealing output");
		Dialog.addMessage("If you are not satisfied, do not tick the box and just click Ok.\nThis will take you back to the previous step.");
		Dialog.addCheckbox("Satisfied?", false);
		Dialog.show();
		Satisfied = Dialog.getCheckbox();
		if (Satisfied) {		
			//Save Results
			selectWindow("Results");
			saveAs("Results",outDir + File.separator + img + ".xls");	
			xValues = newArray(nResults);
			yValues = newArray(nResults);
			for (i = 0; i < nResults(); i++) {
    			yValues[i] = getResult("Area", i);
    			xValues[i] = getResult("Slice", i);
			}	
			Plot.create("Plot of Results", "Time frame", "Area [pixels]");
			Plot.add("Circle", Table.getColumn("Area", "Results"));
			Plot.setStyle(0, "blue,#a0a0ff,1.0,Circle");
			//Preview result	
			selectWindow(imgP);
			close();
			selectWindow(img);
			roiManager("Select", 0);
		}
		else {
			selectWindow(img);
			close("\\Others");
			run("Clear Results");
			roiManager("reset");		
		}
	}
}
else{
	showMessage("Invalid input file");
	break;
}