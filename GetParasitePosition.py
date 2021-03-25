## Get Parasite positions from ToAst (imageJ plugin) output
## Version:v0.1
##
## Short description: Reads logfile and extracts all the line until line = "Overall" and saves the track number, slice, X and Y position
##  
## Requires python 3.8, tkinter 
## 
## This script should NOT be redistributed without author's permission. 
## Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
## 
## "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
## member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
## 
## Date: March/2021
## Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
## Advanced Ligth Microscopy, I3S 
## PPBI-Portuguese Platform of BioImaging
##


import io, re, os
import csv
from tkinter import filedialog
from tkinter import *
        
def readit(file_name,start_line = 1): # start_line - where your data starts (2 line mean 3rd line, because we start from 0th line) 
    with open(file_name,'r') as f:
        data = f.read().split('\n')
     
    data = [i.split(' ') for i in data[start_line:]]
    for i in range(len(data)):        
        if re.search(data[i][0],"overall"):
            break            
        else:
           track.append([data[i][0], data[i][2], data[i][4], data[i][5]])
    
    return track


def path_leaf(path):
    head, tail = ntpath.split(path)
    return tail or ntpath.basename(head)

root = Tk()
root.filename = filedialog.askopenfilename(initialdir="/", title='Please select ToAsp logfile')

track = []
track = readit(root.filename)
print(root.filename)
with open( root.filename + '_Positions.csv', mode='w', newline='') as output_file:
    output_writer = csv.writer(output_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for t in range(len(track)):
        output_writer.writerow(track[t])
print(root.filename + '_Positions.csv SAVED')    
root.withdraw()

