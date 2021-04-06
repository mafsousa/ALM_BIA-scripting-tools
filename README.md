## BioImage Analysis tools
Simple bioimage analysis macro/scripts developed at Advanced Light Microscopy Facility at I3S, Porto Portugal

## ImageJ/Fiji
* **LIFtoTIFF**: Convert the series of a LIF file into TIF format
* **FromInCellToHyperstack**: convert InCell images in hyperstack arranged by wells and fields
* **SaveLasXFilesToHyperstack**: convert Leica isolated  images in hyperstack arranged by position/region/field
* **Woundhealing_TimeSegmentation**: calculate wound healing area of a time-lapse image
* **StarDist_process_folder**:  apply a pre trained StarDist 2D model to a folder of images
* **CreateBandsQuadrants**: creates "sholl analysis" concentric shell with a specific number/width of bands from a starting Roi

   ![picture alt](https://github.com/mafsousa/ALM_BIA-scripting-tools/blob/main/Data_samples/CreateBandsQuadrants.png) 

* **SetParasiteLabel**: creates an annotated image with the parasite track information obtained from GetParasitePosition.py script

## Python

* **InCell_Merge_Excel_Files**: merge at least two excel files from InCell analysis results
* **From_subfolder_to_folder**: join files from different subfolders to he same level folder
* **ChangeFilenames**: change file names, by string replacement. Also allows removing file name spaces(e.g, test 1.txt to test1.txt)
* **MergeExcelFiles**: Merge two excel (.csv) files (source and target) by specifying the columns number to copy from source to target file;
* **AppendExcelFiles**: Merge excel files with the same columns and save in a new excel file;
 
     ![picture alt](https://github.com/mafsousa/ALM_BIA-scripting-tools/blob/main/Data_samples/AppendExcelfilesGUI_small.png) 

* **GetParasitePosition**: Extract tracks position information from logfile.txt (the output of the ToAsp plugin https://imagej.net/ToAST)  
 
# Authors
Mafalda Sousa, BioImage Analyst, mafsousa@ibmc.up.pt

# Licence

Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
 
"The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
