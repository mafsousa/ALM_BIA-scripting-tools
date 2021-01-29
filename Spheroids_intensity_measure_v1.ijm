/*Title: Measure mean intensity channels inside spheroid area
 * Version: V1.0
*
* Short description: Input InCell stack files organized (at FromInCellToHyperstack) by wells (lines, columns) and fields of maximum 384 well-plate. 
* Note: this version only works with 2D files with multiple channels. 
* 
* Shperoid area is segmented either by processing Brightfield channel or using mask previouly calculated in Ilastik
* You need to specify Brighfield file pattern, mask file_pattern and the other channels file pattern 
* The user is prompted to define file parameters, spheroid mask option and validation option
* Validation option may require manual input to correct bad spheroid segmentation
* 
* Input: 
* 		** folder with incell atsck tif files arranged by wells and fields (ex. A - 1(fld 1)-stack.tif)
* 		** requires at least Brightfield channel for spheroid segmentation
* 		**if a mask is available the segmentation will be done in the mask		
* 		
* Output:	
* 		** Results table with spheroid area, perimeter, Ferets and shape. Mean intensity values inside each fluorescence chanel
* 		** Area is in pixel^2 units, Mean is in 8-bit range
* 		
** Prerequisites: Run on ImageJ/Fiji v1.53 		
* 				 Organize InCell files in stacks using FromInCellToHyperstack macro	
* 
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: January 2021
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/

//Define folders (input and output)

#@ String(value="Select images' path and an empty folder for the output results                                                                     ", visibility="MESSAGE") hint;
#@ File (label = "Select source Director", style = "directory") source_dir
#@ File (label = "Select output directory", style = "directory") output_dir
#@ String (label = "File suffix", value = ".tif") ext

files = getFileList(source_dir);

//Set analysis options
Dialog.create("Sheperoid analysis");
Dialog.addChoice("Spheroid segmentation:",newArray("with mask", "from scratch"),"from scratch");
Dialog.addChoice("Analyse fluorescence in other channel?",newArray("Yes", "No"),"Yes");
Dialog.addSlider("Number of channels to analyse", 1,4,1);
Dialog.addCheckbox("Ignore validation step?", false);
//Dialog.addChoice("Ignore validation step?", newArray("Yes","No"), "No");
Dialog.show();

mask_available = Dialog.getChoice();
other_channel = Dialog.getChoice();
channels_F = Dialog.getNumber();
ig_validation = Dialog.getCheckbox();

file_pattern = newArray("wv Cy3 - Cy3","wv DAPI - DAPI","wv FITC - FITC","wv TexasRed - TexasRed");
Dialog.create("Select channels file pattern");
Dialog.addString("Brightfield file name", "wv TL-Brightfield - DAPI",30);
Dialog.addString("Mask file name", "wv TL-Brightfield - DAPI)_Probabilities_0",30);

if (other_channel =="Yes") {	
	Dialog.addMessage("Fluorescence channels:");
	for (k = 0; k < channels_F; k++) {	
		Dialog.addChoice("Channel " + k+1 +" file name", file_pattern, file_pattern[k]);
	}
}
Dialog.show();	

Brightfield_pattern = Dialog.getString();
mask_pattern = Dialog.getString();
channels_pattern = newArray(channels_F);
for (k = 0; k < channels_F; k++) {	
	channels_pattern[k] =  Dialog.getChoice();
}



Dialog.create("Select output parameters"); 
//parameters = newArray("spheroid area", "spheroid perimeter", "spheroid shape", "spheroid feret's", "mean intensity", "minimum intensity");
parameters = newArray("spheroid area", "spheroid perimeter", "spheroid shape", "spheroid feret's");
Dialog.addCheckboxGroup(4, 1, parameters,newArray(true, false, false, false));
Dialog.show();
output_parameter = "";
for (i=0; i<parameters.length; i++){	
	if ( Dialog.getCheckbox()==1)		
		output_parameter = output_parameter + " " + parameters[i];
}

run("Set Measurements...", output_parameter + " redirect=None decimal=2");
//area mean min perimeter shape feret's
//Set file Parameters


//create labes array to store image names
labels = newArray(files.length);
canvas_width = newArray(files.length);
canvas_height = newArray(files.length);
l = 0;

run("Close All");
roiManager("reset");
run("Clear Results");

setBatchMode(true);

for (i = 0; i < files.length; i++) {
	filename = files[i];
	
	if(endsWith(filename, ".tif")){		
		print(filename);	
		open(source_dir + File.separator + filename);
		Stack.getDimensions(width, height, channels1, slices, frames)
		if(slices >1 || frames >1){//only works for t=1 and z=1
			exit("Curret version only works for 2D images with n channels! ");
		}
		labels[l] = filename;			    
		l = l+1;
		run("Set Scale...", "distance=0 known=0 unit=pixel");
		original = getTitle();
		run("Stack to Images");			
	}
	else { //increment cycle if file doesn't exist
			continue;			
	}

	//select brigthfield channel
	file_name_start = substring(original,0,indexOf(original, "-stack")-1);
	channel_1 = file_name_start + Brightfield_pattern + ")";
	selectWindow(channel_1);						
	getDimensions(width, height, channels2, slices, frames);

	//normalize canvas_size in the final output
	if (l == 1){
		canvas_width = width * 0.20 - (width * 0.20) * 0.04;
		canvas_height = height * 0.20 - (height * 0.20) * 0.04;
	}		
	
	//run("Set Measurements...", "area mean min perimeter shape feret's display redirect=None decimal=3");
			
	//If no segmented mask is available
	if (mask_available=="from scratch"){//perform segmentation on ch2
		selectWindow(channel_1);
		run("Set Scale...", "distance=0 known=0 unit=pixel");	
		run("Duplicate...", " ");
		copy = getTitle();
		//correct uneven illumination
		run("Gaussian Blur...", "sigma=100");
		imageCalculator("Divide create 32-bit", channel_1,copy);
		result = getTitle();
		//create background image
		selectWindow(result);
		run("Median...", "radius=10");
		run("Subtract Background...", "rolling=50 light create");			
		//create mask
		setAutoThreshold("Default");
		run("Convert to Mask");
				
		//remove rois from edges and smaller than 10000px with no circularity								
		run("Analyze Particles...", "size=10000-Infinity show=Masks exclude include");
		mask = getTitle();
		selectWindow(mask);
		run("Median...", "radius=20");
		//run("Invert");		
		run("Analyze Particles...", "size=10000-Infinity circularity=0.5-1 show=Masks exclude include");		
		run("Create Selection");		
			
		if(selectionType() !=-1){
			roiManager("Add");
			roiManager("select", 0);
			run("Enlarge...", "enlarge=15"); //enlarge to compensate filters
			roiManager("update");
		}
		else{
			if (ig_validation == true) {
				print("No Spheroid detected on ", filename);
				l=l-1;
				continue;						
			}					
		}
	}
	else {//Spheroid mask available				
		mask_file = file_name_start + mask_pattern;
		//select mask channel. Note name is dependent on channel's 2 name					
		selectWindow(mask_file);
		rename("channel_2");
			
		//clean probability channel to get spheroid area
		run("Median...", "radius=10");
		setAutoThreshold("Default dark");
		run("Convert to Mask");	
	
		//remove rois from edges and smaller than 10000px with no circularity						
		run("Analyze Particles...", "size=10000-Infinity show=Masks exclude include");
		mask = getTitle();
		selectWindow(mask);
		run("Median...", "radius=20");
		//run("Invert");
		run("Create Selection");
		if(selectionType() !=-1){
			roiManager("Add");
			roiManager("select", 0);
		}	
		else{					
			if (ig_validation == true) {
				print("No Spheroid detected on ", filename);
				l=l-1;
				continue;						
			}					
		}				
	}	
			
	if (ig_validation == false) { //perform validation			
		setBatchMode("exit and display");			
		selectWindow(channel_1);
		run("Grays");
		run("Enhance Contrast", "saturated=0.35");
		if(roiManager("count")>0){ //if spheroid area exists
			roiManager("select", 0);
			//create dialog to ask for verification						
			Dialog.create("Spheroid options");	
			Dialog.addMessage("Verify if the spheroid area is correct.\nCheck Yes to continue. Check No to correct manually.");
			Dialog.addRadioButtonGroup("The spheroid area is correct?", newArray("Yes","No"), 1, 2, "Yes");
			Dialog.show();
					
			satisfied = Dialog.getRadioButton();
			if(satisfied=="Yes"){ //If ok measure intensity values in Ch1							
				selectWindow(mask);				
				roiManager("select", 0);
				//roiManager("measure");									
			}
			else{ //perform manual segmentation with wand tool and measure
				roiManager("reset");
				selectWindow(channel_1);				
				run("Median...", "radius=10");
				run("Subtract Background...", "rolling=50 light create");		
				run("Find Maxima...", "prominence=100 strict exclude light output=[Point Selection]");	
				if(selectionType()! = -1){
				  	Roi.getCoordinates(xpoints, ypoints);				
					doWand(xpoints[0], ypoints[0], 100.0, "8-connected");
				}
				else{
					print("No spheroid detected!");
				}			
				selectWindow(channel_1);				
				waitForUser("Adjust Roi with wand tool to fit spheroid area and press OK!");
				roiManager("Add");
				roiManager("select", roiManager("count")-1);
				run("Enlarge...", "enlarge=5 pixel");
				roiManager("update");
				//roiManager("Measure");									
			}
		}
		else{ //if no spheroids area detected perform manual segmentation with wand tool and measure
			selectWindow(channel_1);
			run("Duplicate...", "title=copy");				
			run("Median...", "radius=10");
			run("Subtract Background...", "rolling=50 light create");		
			run("Find Maxima...", "prominence=100 strict exclude light output=[Point Selection]");	
			if(selectionType()! = -1){
			  	Roi.getCoordinates(xpoints, ypoints);				
				doWand(xpoints[0], ypoints[0], 100.0, "8-connected");
			}
			else{
				print("No spheroid detected on", filename);
			}			
			selectWindow("copy");	
			roiManager("reset");			
			waitForUser("Adjust Roi with wand tool to fit spheroid area and press OK!");
			roiManager("Add");
			roiManager("select", 0);
			run("Enlarge...", "enlarge=5 pixel");
			roiManager("update");					
			//roiManager("Measure");
		}
	}
	else{//If skip validation step measure and save				
		roiManager("select", 0);
		//roiManager("Measure");
	}

	//measure from roi in different channels
	if (other_channel == "No") {//measure only spheroid morphometry
		selectWindow(channel_1);
		roiManager("Measure");
	}
	else {//measure intensity in other channels
		//measure spheroid morphometrics
		selectWindow(mask);
		roiManager("select", 0);
		roiManager("Measure");
		
		//measure mean intensity for each channel	
		for (v = 0; v < channels_F; v++) {			
			channels_name = file_name_start + channels_pattern[v] + ")";
			selectWindow(channels_name);
			roiManager("select", 0);
			setResult("Mean_" + channels_pattern[v] , i, getValue("Mean"));
			updateResults();	
		}		
	}
	
	setBatchMode("hide");
	
	//Save images for quality control after analysis
	selectWindow(channel_1);
	run("Grays");
	run("Enhance Contrast", "saturated=0.35");
	run("RGB Color");
	roiManager("Select", 0);
	roiManager("Set Color", "red");
	roiManager("Set Line Width", 5);
	setForegroundColor(100, 255, 0);		
	roiManager("Draw");
	run("Select None");
	run("Scale...", "x=0.2 y=0.2 interpolation=Bilinear average create");
	run("Canvas Size...", "width="+ canvas_width +" height=" + canvas_height + " position=Center zero");
	saveAs("PNG", output_dir + File.separator + filename + "_ROI.png");
	run("Close All");
	roiManager("save",output_dir + File.separator + filename + "_roi.roi");
	roiManager("reset");		
}

setBatchMode(false);
//cut lables array with correct dimension 
names = Array.slice(labels,0,l);
//Arrange final table with labes column and new column names
Table.rename("Results", "Final");
Table.setColumn("File name", names);
Table.renameColumn("Area", "Area [px]");
Table.rename("Final", "Results");
//save results
saveAs("Results", output_dir + File.separator + "Results.xls");

//preview output
run("Image Sequence...", "open=[" + output_dir + File.separator + filename + "_ROI.png] file=.png sort use");
rename("Quality control preview");

print("====DONE====");

function searchStringInArray (str, strArray) {
    for (var j=0; j<strArray.length; j++) {
        if (strArray[j]==str) return j;
    }
    return -1;
}



