# From_subfolder_ to folder
#
#This script allows copying files that are separated into folder
#to the same folder
#
#Requires python 3.6
#
#
#* This macro should NOT be redistributed without author's permission. 
# Explicit acknowledgement to the ALM facility should be done in case of published articles 
# (approved in C.E. 7/17/2017):     
# 
# "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
# member of the national infrastructure PPBI-Portuguese Platform of BioImaging 
# (supported by POCI-01-0145-FEDER-022122)."
# 
# Date: July/2018
# Author: Mafalda Sousa, mafsousa@ibmc.up.pt
# Advanced Ligth Microscopy, I3S 
# PPBI-Portuguese Platform of BioImaging

import os
import glob
import shutil

import tkinter as tk
from tkinter.filedialog import askdirectory

root = tk.Tk()

src_path = askdirectory(title='Select Input folder') # shows dialog box and return the path
print(src_path)
dest_path = askdirectory(title='Select Output folder') # shows dialog box and return the path
print(dest_path)

root.withdraw()
  
for dir_path, dirnames, filenames in os.walk(src_path):
    for filename in filenames:
        if filename.endswith(".tif"):
            src = os.path.join(dir_path, filename)
            dest = os.path.join(dest_path, filename)
            shutil.copy2(src, dest)
