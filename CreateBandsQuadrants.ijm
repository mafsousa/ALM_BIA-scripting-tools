/*Title: Create "sholl" analysis bands from central roi 
 * Version: V0.1
*
* Short description: A set of bands and quadrants is created from a starting  roi
* 
* Input: 
* 		** image file
* 		** number of bands and band width
* 		** draw or open first (center) roi
* 		
* Output:	
* 		** bands/quadrantes roi set
* 		
* Prerequisites: Run on ImageJ/Fiji v1.53c 	
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


roiManager("reset");
//check if there's images opened
list = getList("image.titles");
if (list.length == 0) {
	Dialog.create("Warning");
    Dialog.addMessage("No Image opened!");
    Dialog.show();
    exit;
}

while (roiManager("count")<1) {
	waitForUser("Define the first roi and add it to Manager. Press Ok to continue");
}
roiManager("select", 0);
roiManager("rename", "central roi");

// define the number of rings and bandwidth
Dialog.create("Schwann cells migration")
Dialog.addNumber("Number of bands", 5);
Dialog.addNumber("Band width [px]",15);
Dialog.show();
rings = Dialog.getNumber();
band_width = Dialog.getNumber();


getPixelSize(unit, pixelWidth, pixelHeight);
run("Set Scale...", "distance=0 known=0 unit=pixel");

//warning for to big/much bands
Y = getHeight();
X = getWidth();

if((rings * band_width)>X/2 || (rings * band_width)>Y/2){
	Dialog.create("Warning");
    Dialog.addMessage("You must define smaller/less bands!");
    Dialog.show();
    exit;
}


//Add the rings to Roi manager
//setBatchMode("hide");
r = newArray(rings);
t = 0;
for (i = 0; i < rings; i=i+1) {
	roiManager("select", t);	
	run("Enlarge...", "enlarge="+ band_width);
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	t = roiManager("index");	
	
	if (i==0) 
		roiManager("Select", newArray(0,1));
	else 
		roiManager("Select", newArray(t,t-2));
	roiManager("XOR");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "ring_" + i+1);	
	r[i] = roiManager("index");
}

number_rois = roiManager("count");
roiManager("select", 0);
raio = getValue("Major");
diameter = round(rings *  band_width + raio);

//print(diameter);

roiManager("select", 0);
xm = getValue("X");
ym = getValue("Y");
run("Specify...", "width=" + diameter +" height=" + diameter + " x="+ xm+" y=" +ym);
roiManager("add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "Q4");
x1 = xm - diameter;
y1= ym;
run("Specify...", "width=" + diameter +" height=" + diameter + " x="+ x1+" y=" +y1);
roiManager("add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "Q3");
x2 = xm - diameter;
y2= ym - diameter;
run("Specify...", "width=" + diameter +" height=" + diameter + " x="+ x2+" y=" +y2);
roiManager("add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "Q2");

x3 = xm;
y3= ym - diameter;
run("Specify...", "width=" + diameter +" height=" + diameter + " x="+ x3+" y=" +y3);
roiManager("add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "Q1");

//Define rings inside each quadrant
count_rois = roiManager("count");
for (q = 4; q>0; q--){
	ind_Q = count_rois - q; 
	for (r = 0; r < rings*2; r=r+2 ){
		ind_R = count_rois-(rings * 2)-3+r;
		roiManager("select", newArray(ind_R,ind_Q));
		roiManager("AND");
		roiManager("Add");	
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Q"+ q + "_ring" + r/2);
	}
}

for (i = number_rois -1; i > 0 ; i--) {
	roiManager("select", i);
	roiManager("delete");
}

setBatchMode("exit and display");
roiManager("show all");
//roiManager("save", "bands_quadrantes_set.zip");