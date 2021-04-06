/*Title: Organize files from LasX system and save them as hyperstack
 * Version: V0.2
*
* Short description: Input LasX isolated tiff files, searching for region/positions, stages and  
* create hyperstack for each one, (xyzct). Save as tiff.
* 
* 
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: March/2021
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/



#@ File (label = "Input first file", style = "directory") input
#@ File (label = "Output directory", style = "directory") output

//get file from path
file_name = File.getName(input);
input_path = File.getDirectory(input);
//get file_name without extension
//name = substring(file_name,0, indexOf(file_name, ".tif"));

Dialog.create("Organize LasX files into stacks");
Dialog.addChoice("Type of acquisition", newArray("Tilescan","Multiposition"), "Tilescan");
//Dialog.addString("File start name ", "TileScan 1");
Dialog.addNumber("Number of regions/positions", 1);
Dialog.addToSameRow();
Dialog.addNumber("Number of stages", 0);
Dialog.addNumber("Number of time points", 1); 
Dialog.addToSameRow();
Dialog.addNumber("Time frame [sec]", 0.3);
Dialog.addNumber("Number of slices", 1);
Dialog.addNumber("Number of channels", 1);

Dialog.show();
type = Dialog.getChoice();
//tile_start_name = Dialog.getString();
regions = Dialog.getNumber();
stages = Dialog.getNumber();
timepoints = Dialog.getNumber(); 
timeframe = Dialog.getNumber();
n_slices = Dialog.getNumber();
n_channels = Dialog.getNumber();

tile_start_name_list =  getPositionFileName(input);
Array.print(tile_start_name_list);
//if (tile_start_name_list.length!=regions) {
//	exit("List of files length is not the same as the number of regions/positions!");
//}


setBatchMode(true);
run("Close All");
//if tilescan type with one region
if (type == "Tilescan" && regions == 1) {
	tile_start_name = tile_start_name_list[0];
	//tile_start_name = "TileScan 1"; 
	for (s = 0; s < stages; s++) {
		if (stages == 0) 
			stage_name = "";
		else
			stage_name = numerical_name("Stage", stages, s) ;
	
		file_start_name = tile_start_name + "--" + stage_name ;	
					
		run("Image Sequence...", "open=[" + input + "] number=" + timepoints*n_slices*n_channels + " starting=0 file=[" + file_start_name + "] sort use");
		getVoxelSize(width, height, depth, unit);
		run("Properties...", "channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints + " pixel_width=" + width + " pixel_height=" + height + " voxel_depth=1 frame=[" + timeframe + " sec]");
		run("Stack to Hyperstack...", "order=xyczt(default) channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints +" display=Color");
		saveAs("Tiff", output + File.separator + file_start_name +  stage_name + ".tif");
		run("Close All");
		print("-----Saving ", file_start_name  + ".tif");
	}
}

//if tilescan type with more than one region
if (type == "Tilescan" && regions > 1) {
	for(r=1; r<=regions; r++){
		//region_name = "Region " + r;		
		file_start_name = tile_start_name_list[r-1];

		//select the correct files and calculate the number of stages
		stack_size = timepoints*n_slices*n_channels;
		n_files = listCorrectFiles(input, file_start_name);
		stages = n_files/stack_size;
	
		run("Image Sequence...", "open=[" + input + "] number=" + n_files + " starting=0 file=[" + file_start_name + "] sort use");
		rename("Tile");
		getVoxelSize(width, height, depth, unit);
		//convert to stages and save
		for (s = 0; s < stages; s++) {
			stage_name = "--Stage" + s;
			selectWindow("Tile");
			run("Duplicate...", "duplicate range="+ (s * stack_size+1) +"-" + (s+1) * stack_size );
			run("Properties...", "channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints + " pixel_width=" + width + " pixel_height=" + height + " voxel_depth=1 frame=[" + timeframe + " sec]");
			run("Stack to Hyperstack...", "order=xyczt(default) channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints +" display=Color");
			saveAs("Tiff", output + File.separator + file_start_name + stage_name + ".tif");
			print("-----Saving ", file_start_name  + stage_name + ".tif");
			close();				
		}
		run("Close All");
	}
}

//if multiposition type 
if (type == "Multiposition"){
	for(r=1; r<=regions; r++){
		//position_name = "Position " + r;
		file_start_name = tile_start_name_list[r-1];
		if (stages == 0) {
			//file_start_name = tile_start_name;
			run("Image Sequence...", "open=[" + input + "] number=" + timepoints*n_slices*n_channels + " starting=0 file=[" + file_start_name + "] sort use");
			getVoxelSize(width, height, depth, unit);
			run("Properties...", "channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints + " pixel_width=" + width + " pixel_height=" + height + " voxel_depth=1 frame=[" + timeframe + " sec]");
			run("Stack to Hyperstack...", "order=xyczt(default) channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints +" display=Color");
			saveAs("Tiff", output + File.separator + file_start_name + ".tif");
			run("Close All");
			print("-----Saving ", file_start_name + ".tif");
		}
		else{//CONFIRM IF THIS HAPPENS (not tested)
			for (s = 0; s < stages; s++) {
				stage_name = "Stage" + s;		
				file_start_name = tile_start_name_list[r-1];							
				run("Image Sequence...", "open=[" + input + "] number=" + timepoints*n_slices*n_channels + " starting=0 file=[" + file_start_name + "] sort use");
				getVoxelSize(width, height, depth, unit);
				run("Properties...", "channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints + " pixel_width=" + width + " pixel_height=" + height + " voxel_depth=1 frame=[" + timeframe + " sec]");
				run("Stack to Hyperstack...", "order=xyczt(default) channels=" + n_channels + " slices=" + n_slices + " frames=" + timepoints +" display=Color");
				saveAs("Tiff", output + File.separator + file_start_name + stage_name + ".tif");
				run("Close All");
				print("-----Saving ", file_start_name + stage_name +".tif");
			}
		}
	}
}


function numerical_name(string, number, s) {
	//auxiliar function to create string with numeric increment	
	if(s < 10 && number < 100 ){
		out_string = string + "0" + s;
	}
	else if(s < 10 && number > 99 ){
		out_string = string + "00" + s;
	}
	else if (s >= 10 && number < 100 ){
		out_string = string + s;
	}
	else if (s > 99 && number > 99){
		out_string = string + "0" + s;
	}
	return out_string;
}

function listCorrectFiles(dir, name) {	 
	 list = getFileList(dir);
	 c=0;
	 for (i=0; i<list.length; i++) {
	    if (startsWith(list[i], name))
	       c = c +1;
	
 	}
 	return c;
}

function getPositionFileName(input){
	files = getFileList(input);
	for (i = 0; i < files.length; i++) {
		if(endsWith(files[i], ".tif")==0)
			files = Array.deleteIndex(files, i);
	}
	
	names = newArray(files.length);
	for (i = 0; i < files.length; i++) {	
		indx = indexOf(files[i],"--");
		if (indx>0) {
			names[i] = substring(files[i],0, indx);
		}
	}
		
	InputArray=names;
	Array.print(names);
	OutputArray = unique(InputArray);
	Array.print(OutputArray);
	return Array.sort(OutputArray);
}


function unique(InputArray) {
    separator = ","
    
    InputArrayAsString = InputArray[0];
    for(i = 1; i < InputArray.length; i++){
        InputArrayAsString += separator + InputArray[i];
    }
    
    script = "result = r'" + 
             separator +
             "'.join(set('" +
             InputArrayAsString +
             "'.split('" + 
             separator +
             "')))";
 
    result = eval("python", script);
    OutputArray = split(result, separator);
    return OutputArray;
}




setBatchMode(false);
print("==Done==");