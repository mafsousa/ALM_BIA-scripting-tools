/* Set Parasite Label
 * v0.1
*
* This is a particular macro to label parasite tracking from ToAst output logfile.
* 
* Input: 
 	 ** File in .tif stack xyz
	 ** LogFile.csv obtained from GetParasitePosition.py script 
* 
* Output: 
* 
     ** Original image, converted to RGB with the tracking labels 
     ** Roi set with parasite central positions 
* 
* Prerequisites: Run on ImageJ/Fiji v1.53
				
* 
* This macro should NOT be redistributed without author's permission. 
* Explicit acknowledgement to the ALM facility should be done in case of published articles 
* (approved in C.E. 7/17/2017):     
* 
* "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
* member of the national infrastructure PPBI-Portuguese Platform of BioImaging 
* (supported by POCI-01-0145-FEDER-022122)."
* 
* Date: March/2021
* Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
* Advanced Ligth Microscopy, I3S 
* PPBI-Portuguese Platform of BioImaging
*/

#@ File (label = "Input image (.tif)", style = "file") image
#@ File (label = "Input logfile (.csv)", style = "file") logfile

run("Clear Results");
run("Close All");
roiManager("reset");

open(image);
original = getTitle();
run("RGB Color");
path = File.getDirectory(image);

run("Enhance Contrast", "saturated=0.35");
setBatchMode("hide");
ImportResultsTable();

slice = -1;
for (i = 0; i < nResults; i++) {
    X = round(getResult('X', i));
    Y = round(getResult('Y', i));
    if (X==0 ||Y == 0) {
    	continue;
    }
	old_slice = slice;
    slice = round(getResult("Parasite", i));
    track = getResult("Track", i);
    selectWindow(original);
    setSlice(slice);
    run("Point Tool...", "type=Circle color=Red size=[Large] counter=0");
 	makePoint(X, Y,"small red hybrid");
 	roiManager("add");
 	if(old_slice!=slice){ 		
 		setFont("SansSerif", 42, " antialiased");
		setColor("red");
		drawString(track, X, Y);
 	}	
 	
}


setBatchMode("exit and display");
roiManager("Associate", "true");
roiManager("UseNames", "true");
roiManager("show all");

saveAs("Tiff", path + File.separator + original + "_label.tif");
roiManager("save", path + File.separator + original +"Roiset.zip");

function ImportResultsTable(){
     requires("1.35r");
     lineseparator = "\n";
     cellseparator = ",\t";

     // copies the whole RT to an array of lines
     lines=split(File.openAsString(logfile), lineseparator);

     // recreates the columns headers
     labels=newArray("Track","Parasite","X","Y");;
     for (j=0; j<labels.length; j++)
        setResult(labels[j],0,0);

     // dispatches the data into the new RT
     run("Clear Results");
     for (i=0; i<lines.length; i++) {
        items=split(lines[i], cellseparator);
        for (j=0; j<items.length; j++){
            setResult(labels[j],i,items[j]);
        }
     }
     updateResults();
 }




