/*Title: Measure Cy3 (channel 1) mean intensity inside spheroid area
 * Version: V0.3.3
*
* Short description: Input InCell isolated tiff files, searching for wells (lines, columns) and fields of maximum 384 well-plate. 
* Note: this version only works with 2D files with multiple channels. 
* Shperoid area is segmented either by processing Brightfield channel or using mask previouly calculated in Ilastik
* You need to specify Brighfield file pattern, mask file_pattern and the other channel file pattern 
* The user is prompted to define file parameters, spheroid mask option and validation option
* Validation option may require manual input to correct bad spheroid segmentation
* 
* Input: 
* 		** folder with incell tif files arranged by wells and fields
* 		** requires channel 1 (Cy3) and channel 2 (Brightfield)
* 		**if mask is available will be open as channel2_name+mask_pattern
* 		
* Output:	
* 		** Results table with area and mean, max and min intensity values inside sheroid area, with corresponding image labels
* 		** Area is in pixel^2 units
* 		
** Prerequisites: Run on ImageJ/Fiji v1.53 		
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
Dialog.addString("Brightfield file name pattern", "wv TL-Brightfield - DAPI",30);
Dialog.addString("Mask file pattern", "wv TL-Brightfield - DAPI)_Probabilities_0",30);
Dialog.addChoice("Analyse fluorescence in other channel?",newArray("Yes", "No"),"Yes");
Dialog.addString("Fluorescence file name pattern", "wv Cy3 - Cy3",30);
Dialog.addChoice("Ignore validation step?", newArray("Yes","No"), "No");
Dialog.show();

mask_available = Dialog.getChoice();
B_name_pattern = Dialog.getString();
mask_pattern = Dialog.getString();
other_channel = Dialog.getChoice();
F_name_pattern = Dialog.getString();
ig_validation = Dialog.getChoice();


Dialog.create("Select output parameters"); 
parameters = newArray("spheroid area", "spheroid perimeter", "spheroid shape", "spheroid feret's", "mean intensity", "minimum intensity");
Dialog.addCheckboxGroup(6, 1, parameters,newArray(true, false, false, false, true, false));
Dialog.show();
output_parameter = "";
for (i=0; i<6; i++){	
	if ( Dialog.getCheckbox()==1)		
		output_parameter = output_parameter + " " + parameters[i];
}

	
//area mean min perimeter shape feret's
//Set file Parameters
well_line = newArray("A", "B", "C", "D", "E","F","G","H","I","J","K","L","M","N","0","P");
well_col = newArray("1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24");
frames=1;
slices=1;
channels = 1;
field_number = 1;

indx_start_line = searchStringInArray("A", well_line);
indx_start_col = searchStringInArray("1", well_col);
indx_end_line = searchStringInArray("P", well_line);
indx_end_col = searchStringInArray("24", well_col);

//create labes array to store image names
labels = newArray(files.length);
canvas_width = newArray(files.length);
canvas_height = newArray(files.length);
l = 0;

run("Close All");
roiManager("reset");
run("Clear Results");

setBatchMode(true);


//search all lines, columns and fields
for (line=indx_start_line; line <= indx_end_line; line++){
	for (col=indx_start_col; col <= indx_end_col; col++){		
		file_start_name = well_line[line] + " - " + well_col[col];		
		for (f = 1; f <=field_number; f++) {
			
			field_name = "(fld " + f + " ";
			
			filename = source_dir + File.separator + file_start_name + field_name +  B_name_pattern + ").tif";		
			print(filename);
			if(File.exists(filename)){	
				labels[l] = file_start_name;			    
				l = l+1;

				if (other_channel == "No") {
					open(source_dir + File.separator + file_start_name + field_name +  B_name_pattern + ").tif");
					rename("C2-original");
					run("Set Scale...", "distance=0 known=0 unit=pixel");
				}
				else{
					open(source_dir + File.separator + file_start_name + field_name + B_name_pattern + ").tif");
					rename("C2-original");
					run("Set Scale...", "distance=0 known=0 unit=pixel");
					open(source_dir + File.separator + file_start_name + field_name + F_name_pattern + ").tif"); 
					rename("C1-original");
					run("Set Scale...", "distance=0 known=0 unit=pixel");
				}
			}
			else { //increment cycle if file doesn't exist
				continue;			
			}
					
			getDimensions(width, height, channels, slices, frames);

			//normalize canvas_size in the final output
			if (l == 1){
				canvas_width = width * 0.20 - (width * 0.20) * 0.04;
				canvas_height = height * 0.20 - (height * 0.20) * 0.04;
			}
			
			if(slices >1 || frames >1){//only works for t=1 and z=1
				exit("Curret version only works for 2D images with 2 channels! ");
			}
			run("Set Measurements...", output_parameter + " display redirect=None decimal=3");
			//run("Set Measurements...", "area mean min perimeter shape feret's display redirect=None decimal=3");
			
			//If no segmented mask is available
			if (mask_available=="from scratch"){//perform segmentation on ch2
				selectWindow("C2-original");
				rename("C2-original");
				run("Set Scale...", "distance=0 known=0 unit=pixel");	
				run("Duplicate...", " ");
				copy = getTitle();
				//correct uneven illumination
				run("Gaussian Blur...", "sigma=100");
				imageCalculator("Divide create 32-bit", "C2-original",copy);
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
				run("Invert");				
				run("Create Selection");				

				if(selectionType() !=-1){
					roiManager("Add");
					roiManager("select", 0);
					run("Enlarge...", "enlarge=15"); //enlarge to compensate filters
					roiManager("update");
				}
				else{
					if (ig_validation == "Yes") {
						print("No Spheroid detected on ", filename);
						l=l-1;
						continue;						
					}					
				}
			}
			else {//Spheroid mask available				
				mask_file = source_dir + File.separator + file_start_name + field_name + mask_pattern +  ".tif" ;
				//open mask. Note name is dependent on channel's 2 name					
				open(mask_file);
				
				//clean probability channel to get spheroid area
				run("Set Scale...", "distance=0 known=0 unit=pixel");
				run("Median...", "radius=10");
				setAutoThreshold("Default dark");
				run("Convert to Mask");	
	
				//remove rois from edges and smaller than 10000px with no circularity						
				run("Analyze Particles...", "size=10000-Infinity show=Masks exclude include");
				mask = getTitle();
				selectWindow(mask);
				run("Median...", "radius=20");
				run("Invert");
				run("Create Selection");
				if(selectionType() !=-1){
					roiManager("Add");
					roiManager("select", 0);
				}	
				else{					
					if (ig_validation == "Yes") {
						print("No Spheroid detected on ", filename);
						l=l-1;
						continue;						
					}					
				}				
			}	
			
			//VALIDATION STEP
			/*if (other_channel=="Yes") {	
				run("Set Measurements...", output_parameter + " display redirect=None decimal=3");	
					//run("Set Measurements...", "area mean min perimeter shape feret's display redirect=C1-original decimal=3");
			}
			else {
				
			    run("Set Measurements...", "area perimeter shape feret's display redirect=C1-original decimal=3");
			}*/
			if (ig_validation == "No") { //perform validation			
				setBatchMode("exit and display");			
				selectWindow("C2-original");
				run("Grays");
				run("Enhance Contrast", "saturated=0.35");
				if(roiManager("count")>0){ //if spheroid area exists
					roiManager("select", 0);
					//create dialog to ask for verification						
					Dialog.create("Spheroid options");	
					Dialog.addMessage("Verify if the spheroid area is correct.\nCheck Yes to continue. Check No to correct manually.");
					Dialog.addRadioButtonGroup("Correct spheroid area?", newArray("Yes","No"), 1, 2, "Yes");
					Dialog.show();
					
					satisfied = Dialog.getRadioButton();
					if(satisfied=="Yes"){ //If ok measure intensity values in Ch1							
						selectWindow(mask);				
						roiManager("select", 0);
						roiManager("measure");									
					}
					else{ //perform manual segmentation with wand tool and measure
						roiManager("reset");
						selectWindow("C2-original");				
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
						selectWindow("C2-original");				
						waitForUser("Adjust Roi with wand tool to fit spheroid area and press OK!");
						roiManager("Add");
						roiManager("select", roiManager("count")-1);
						run("Enlarge...", "enlarge=5 pixel");
						roiManager("update");
						roiManager("Measure");									
					}
				}
				else{ //if no spheroids area detected perform manual segmentation with wand tool and measure
					selectWindow("C2-original");				
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
					selectWindow("C2-original");				
					waitForUser("Adjust Roi with wand tool to fit spheroid area and press OK!");
					roiManager("Add");
					roiManager("select", roiManager("count")-1);
					run("Enlarge...", "enlarge=5 pixel");
					roiManager("update");					
					roiManager("Measure");
				}
			}
			else{//If skip validation step measure and save				
				roiManager("select", 0);
				roiManager("Measure");
			}
			
			setBatchMode("hide");
			
			//Save images for quality control after analysis
			selectWindow("C2-original");
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
			saveAs("PNG", output_dir + File.separator + file_start_name + "_ROI.png");
			run("Close All");
			roiManager("save",output_dir + File.separator + file_start_name + "_roi.roi");
			roiManager("reset");		
		}
	}
}

setBatchMode(false);
//cut lables array with correct dimension 
names = Array.slice(labels,0,l);
//Arrange final table with labes column and new column names
Table.rename("Results", "Final");
Table.setColumn("Image labels", names);
Table.renameColumn("Area", "Area [px]");
Table.renameColumn("Mean", "Mean intensity [16-bits]");
Table.renameColumn("Max", "Max intensity [16-bits]");
Table.renameColumn("Min", "Min intensity [16-bits]");
Table.rename("Final", "Results");

//save results
saveAs("Results", output_dir + File.separator + "Results.xls");

//preview output
run("Image Sequence...", "open=[" + output_dir + File.separator + file_start_name + "_ROI.png] file=.png sort use");
rename("Quality control preview");

print("====DONE====");

function searchStringInArray (str, strArray) {
    for (var j=0; j<strArray.length; j++) {
        if (strArray[j]==str) return j;
    }
    return -1;
}

