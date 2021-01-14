/*//////////////////////////////////////////////////////////////////////////////  
    * StarDist_process_folder 
	*  
	*  This is a generic macro to apply a pre trained StarDist 2D model to a folder of images 
	* 
	* Input: 
	 	 ** a folder of 2D greyscale images 
	 	 ** an empty folder to store the output result 
	 	 ** pre-trained zip model file
	 	 ** probability threshold (0-1)
	 	 ** NMS threshold (0-1)
		 
	* Output: 
	     ** Labelled cells in tif format
	* 
	* Prerequisites: Run on ImageJ/Fiji v1.53
	 				 Install plugin StarDist from the update sites select CSBDeep and StarDist				
	* 
	* This macro should NOT be redistributed without author's permission. 
	* Explicit acknowledgement to the ALM facility should be done in case of published articles 
	* (approved in C.E. 7/17/2017):     
	* 
	* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
	* member of the national infrastructure PPBI-Portuguese Platform of BioImaging 
	* (supported by POCI-01-0145-FEDER-022122)."
	* 
	* Date: October/2020
	* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
	* Advanced Ligth Microscopy, I3S 
	* PPBI-Portuguese Platform of BioImaging
//////////////////////////////////////////////////////////////////////////////////*/

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ File (label = "StarDist model (.zip file)", style = "file") model
#@ String (label = "File suffix", value = ".tif") suffix
#@ Float (label= "Probability threshold", style="slider", min=0, max=1, stepSize=0.05, value = 0.60) prob
#@ Float (label= "NMS threshold", style="slider", min=0, max=1, stepSize=0.05, value = 0.35) thres


run("Close All");

// normalize input variables into correct strings
prob = normalizeString(prob);
thres = normalizeString(thres);
model1 = replace(model, "\\\\",  "\\\\\\\\\\\\\\\\");
model2 = normalizeString(model1);
print("Apllying pre-trained StarDist model: ", model2);

//process folder with images
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
	print("Processing: " + input + File.separator + file);	
	open(input + File.separator + file);	
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input': "+ file+ ", 'modelChoice':'Model (.zip) from File', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.5', 'probThresh':" + prob + ", 'nmsThresh':" + thres + ", 'outputType':'Label Image', 'modelFile':" + model2 + ", 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	wait(5000); //for bigger images
	selectWindow("Label Image");
	saveAs("Tiff", output + File.separator + "Labelled_mask_" + file);
	run("Close All");
}

function normalizeString(name){
	name_changed = "\'"+ name + "\'";
	return name_changed;
}
